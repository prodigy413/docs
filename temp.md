### testcode

```
terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.73.0"
    }
  }

  backend "s3" {
    bucket = "test-repo-tf-state-d51351f094907b415bab9b2e71"
    key = "workload/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  alias  = "base"
  region = "ap-northeast-1"
}

data "aws_caller_identity" "base" {
  provider = aws.base
}

provider "aws" {
  region = "ap-northeast-1"

  assume_role {
    role_arn     = "arn:aws:iam::${data.aws_caller_identity.base.account_id}:role/terraform-exec-role"
    session_name = "terraform-deploy"
  }
}

resource "aws_cloudwatch_log_group" "terraform" {
  name = "/aws/codebuild/test"
  retention_in_days = 7
}
```

### buildspec-apply.yml

```
version: "0.2"

env:
  variables:
    TF_IN_AUTOMATION: "true"

phases:
  build:
    commands:
      - cd ${CODEBUILD_SRC_DIR}/${REGION}/environments/${ENV}
      - terraform init -input=false -no-color
      - terraform apply -input=false -auto-approve -no-color
```

### buildspec-lint.yml

```
version: "0.2"

env:
  variables:
    TF_IN_AUTOMATION: "true"

phases:
  install:
    commands:
      # https://github.com/terraform-linters/tflint/releases/expanded_assets/v0.64.0
      - |
        set -eu
        tflint_dir="$(mktemp -d)"
        tflint_archive="${tflint_dir}/tflint_linux_amd64.zip"
        wget -O "$tflint_archive" https://github.com/terraform-linters/tflint/releases/download/v0.64.0/tflint_linux_amd64.zip
        printf '%s  %s\n' 'cca9d13e2e1d7a2c627af60ff899a3c9b74212899416aeb96ec764d2ef954537' "$tflint_archive" | sha256sum -c -
        unzip -q "$tflint_archive" tflint -d /usr/local/bin
  build:
    commands:
      - cd "${CODEBUILD_SRC_DIR}/${REGION}/environments/${ENV}"
      - terraform fmt -check -diff -recursive -no-color
      - terraform init -backend=false -input=false -no-color
      - terraform validate -no-color
      - tflint --init
      - tflint
```

### buildspec-plan.yml

```
version: "0.2"

env:
  variables:
    TF_IN_AUTOMATION: "true"

phases:
  build:
    commands:
      - cd ${CODEBUILD_SRC_DIR}/${REGION}/environments/${ENV}
      - terraform init -input=false -no-color
      - terraform validate -no-color
      - terraform plan -input=false -no-color
```

### cloudwatch_logs.tf

```
resource "aws_cloudwatch_log_group" "terraform" {
  name = "/aws/codebuild/${local.pipeline_name}"
}
```

### codebuild.tf

```
locals {
  plan_project_name  = "${local.pipeline_name}-plan"
  apply_project_name = "${local.pipeline_name}-apply"
}

resource "aws_codebuild_project" "plan" {
  name         = local.plan_project_name
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "public.ecr.aws/hashicorp/terraform:1.17.2"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ENV"
      value = "dev"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec-plan.yml")
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.terraform.name
      stream_name = "plan"
    }
  }

  depends_on = [
    aws_iam_role_policy.codebuild,
    aws_iam_role_policy_attachment.terraform_deploy_admin,
    aws_s3_bucket_versioning.state,
  ]
}

resource "aws_codebuild_project" "apply" {
  name         = local.apply_project_name
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "public.ecr.aws/hashicorp/terraform:1.17.2"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ENV"
      value = "dev"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec-apply.yml")
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.terraform.name
      stream_name = "apply"
    }
  }

  depends_on = [
    aws_iam_role_policy.codebuild,
    aws_iam_role_policy_attachment.terraform_deploy_admin,
    aws_s3_bucket_versioning.state,
  ]
}
```

### codecommit.tf

```
resource "aws_codecommit_repository" "terraform" {
  repository_name = "test-repo"
}

output "repository_clone_url" {
  value = aws_codecommit_repository.terraform.clone_url_http
}
```

### codepipeline.tf

```
resource "aws_codepipeline" "terraform" {
  name           = local.pipeline_name
  role_arn       = aws_iam_role.codepipeline.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.terraform.repository_name
        BranchName           = local.branch_name
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name            = "ValidateAndPlan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.plan.name
      }
    }
  }

  stage {
    name = "Approval1"

    action {
      name     = "Approve1"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval_1.arn
        CustomData      = "Terraform Plan のログを確認してください。\n問題がなければ、CodePipeline コンソールで承認してください。"
      }
    }
  }

  stage {
    name = "Approval2"

    action {
      name     = "Approve2"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval_2.arn
        CustomData      = "Terraform Plan のログを確認してください。\n問題がなければ、CodePipeline コンソールで承認してください。"
      }
    }
  }

  stage {
    name = "Approval3"

    action {
      name     = "Approve3"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval_3.arn
        CustomData      = "Terraform Plan のログを確認してください。\n問題がなければ、CodePipeline コンソールで承認してください。"
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.apply.name
      }
    }
  }

  depends_on = [aws_iam_role_policy.codepipeline]
}
```

### data.tf

```
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
```

### eventbridge.tf

```
resource "aws_cloudwatch_event_rule" "master_push" {
  name = "${local.pipeline_name}-master"

  event_pattern = jsonencode({
    source        = ["aws.codecommit"]
    "detail-type" = ["CodeCommit Repository State Change"]
    resources     = [aws_codecommit_repository.terraform.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [local.branch_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule     = aws_cloudwatch_event_rule.master_push.name
  arn      = aws_codepipeline.terraform.arn
  role_arn = aws_iam_role.eventbridge.arn

  # イベント発生時点のコミットを取得する。
  input_transformer {
    input_paths = {
      commit = "$.detail.commitId"
    }
    input_template = <<-JSON
      {
        "sourceRevisions": [
          {
            "actionName": "Source",
            "revisionType": "COMMIT_ID",
            "revisionValue": "<commit>"
          }
        ]
      }
    JSON
  }

  depends_on = [aws_iam_role_policy.eventbridge]
}
```

### iam.tf

```
resource "aws_iam_role" "codepipeline" {
  name = local.pipeline_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "pipeline"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive",
        ]
        Resource = aws_codecommit_repository.terraform.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObjectTagging",
          "s3:GetObjectVersionTagging",
          "s3:PutObjectTagging",
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = [aws_codebuild_project.plan.arn, aws_codebuild_project.apply.arn]
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = [
          aws_sns_topic.approval_1.arn,
          aws_sns_topic.approval_2.arn,
          aws_sns_topic.approval_3.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_role" "eventbridge" {
  name = "${local.pipeline_name}-eventbridge"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnEquals    = { "aws:SourceArn" = aws_cloudwatch_event_rule.master_push.arn }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge" {
  name = "start-pipeline"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "codepipeline:StartPipelineExecution"
      Resource = aws_codepipeline.terraform.arn
    }]
  })
}

locals {
  codebuild_project_arn_prefix = "arn:${local.partition}:codebuild:${var.aws_region}:${local.account_id}:project"
}

resource "aws_iam_role" "codebuild" {
  name = "${local.pipeline_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codebuild.amazonaws.com" }
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnEquals = {
          "aws:SourceArn" = [
            "${local.codebuild_project_arn_prefix}/${local.plan_project_name}",
            "${local.codebuild_project_arn_prefix}/${local.apply_project_name}",
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "terraform"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = local.workload_state_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${local.workload_state_arn}.tflock"
      },
      #{
      #  Effect   = "Allow"
      #  Action   = "logs:CreateLogGroup"
      #  Resource = "${aws_cloudwatch_log_group.terraform.arn}:*"
      #},
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.terraform.arn}:log-stream:plan*",
          "${aws_cloudwatch_log_group.terraform.arn}:log-stream:apply*",
        ]
      },
    ]
  })
}

resource "aws_iam_role" "terraform_exec" {
  name = "terraform-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = aws_iam_role.codebuild.arn }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_deploy_admin" {
  role       = aws_iam_role.terraform_exec.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}
```

### lint.tf

```
locals {
  lint_pipeline_name = "${local.pipeline_name}-lint"
}

resource "aws_codepipeline" "lint" {
  name           = local.lint_pipeline_name
  role_arn       = aws_iam_role.lint_codepipeline.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.terraform.repository_name
        BranchName           = local.branch_name
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Lint"

    action {
      name            = "TerraformLint"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.lint.name
      }
    }
  }

  depends_on = [aws_iam_role_policy.lint_codepipeline]
}

resource "aws_codebuild_project" "lint" {
  name         = local.lint_pipeline_name
  service_role = aws_iam_role.lint_codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "public.ecr.aws/hashicorp/terraform:1.17.2"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ENV"
      value = "dev"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec-lint.yml")
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.terraform.name
      stream_name = "lint"
    }
  }

  depends_on = [aws_iam_role_policy.lint_codebuild]
}

resource "aws_cloudwatch_event_rule" "lint_branch_push" {
  name = "${local.lint_pipeline_name}-branch-push"

  event_pattern = jsonencode({
    source        = ["aws.codecommit"]
    "detail-type" = ["CodeCommit Repository State Change"]
    resources     = [aws_codecommit_repository.terraform.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [{ "anything-but" = local.branch_name }]
    }
  })
}

resource "aws_cloudwatch_event_target" "lint_codepipeline" {
  rule     = aws_cloudwatch_event_rule.lint_branch_push.name
  arn      = aws_codepipeline.lint.arn
  role_arn = aws_iam_role.lint_eventbridge.arn

  # Source の既定ブランチをイベントのコミットで上書きする。
  input_transformer {
    input_paths = {
      commit = "$.detail.commitId"
    }
    input_template = <<-JSON
      {
        "sourceRevisions": [
          {
            "actionName": "Source",
            "revisionType": "COMMIT_ID",
            "revisionValue": "<commit>"
          }
        ]
      }
    JSON
  }

  depends_on = [aws_iam_role_policy.lint_eventbridge]
}

resource "aws_iam_role" "lint_codepipeline" {
  name = local.lint_pipeline_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lint_codepipeline" {
  name = "pipeline"
  role = aws_iam_role.lint_codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive",
        ]
        Resource = aws_codecommit_repository.terraform.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
        ]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObjectTagging",
          "s3:GetObjectVersionTagging",
          "s3:PutObjectTagging",
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ]
        Resource = aws_codebuild_project.lint.arn
      },
    ]
  })
}

resource "aws_iam_role" "lint_codebuild" {
  name = "${local.lint_pipeline_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codebuild.amazonaws.com" }
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnEquals    = { "aws:SourceArn" = "${local.codebuild_project_arn_prefix}/${local.lint_pipeline_name}" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "lint_codebuild" {
  name = "lint"
  role = aws_iam_role.lint_codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
        ]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.terraform.arn}:log-stream:lint*"
      },
    ]
  })
}

resource "aws_iam_role" "lint_eventbridge" {
  name = "${local.lint_pipeline_name}-eventbridge"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnEquals    = { "aws:SourceArn" = aws_cloudwatch_event_rule.lint_branch_push.arn }
      }
    }]
  })
}

resource "aws_iam_role_policy" "lint_eventbridge" {
  name = "start-pipeline"
  role = aws_iam_role.lint_eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "codepipeline:StartPipelineExecution"
      Resource = aws_codepipeline.lint.arn
    }]
  })
}
```

### providers.tf

```
terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.73.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### s3.tf

```
locals {
  buckets = {
    state     = aws_s3_bucket.state
    artifacts = aws_s3_bucket.artifacts
  }
}

##############################
# Terraform state bucket
##############################
resource "aws_s3_bucket" "state" {
  bucket_prefix = "test-repo-tf-state-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "noncurrent-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10 # 最新10世代は日数に関係なく保持
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

##############################
# Artifacts bucket for CodePipeline
##############################
resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "test-repo-artifacts-"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-artifacts"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
  }

  statement {
    sid     = "DenyInsecureConnections"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  policy = data.aws_iam_policy_document.artifacts.json

  depends_on = [aws_s3_bucket_public_access_block.this, aws_s3_bucket.artifacts]
}

##############################
# Public access block and ownership controls for S3 buckets
##############################
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = local.buckets
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
```

### sns.tf

```
resource "aws_sns_topic" "approval_1" {
  name = "${local.pipeline_name}-approval-1"
}

resource "aws_sns_topic_subscription" "approval_1" {
  topic_arn = aws_sns_topic.approval_1.arn
  protocol  = "email"
  endpoint  = "test01@great-obi.net"
}

resource "aws_sns_topic" "approval_2" {
  name = "${local.pipeline_name}-approval-2"
}

resource "aws_sns_topic_subscription" "approval_2" {
  topic_arn = aws_sns_topic.approval_2.arn
  protocol  = "email"
  endpoint  = "test02@great-obi.net"
}

resource "aws_sns_topic" "approval_3" {
  name = "${local.pipeline_name}-approval-3"
}

resource "aws_sns_topic_subscription" "approval_3" {
  topic_arn = aws_sns_topic.approval_3.arn
  protocol  = "email"
  endpoint  = "test03@great-obi.net"
}
```

### variables.tf

```
locals {
  pipeline_name      = "test-repo-terraform"
  branch_name        = "main"
  account_id         = data.aws_caller_identity.current.account_id
  partition          = data.aws_partition.current.partition
  workload_state_key = "workload/terraform.tfstate"
  workload_state_arn = "${aws_s3_bucket.state.arn}/${local.workload_state_key}"
}

variable "aws_region" {
  description = "CI/CD 基盤を作成する AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}
```
