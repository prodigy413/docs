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
    role_arn     = "arn:aws:iam::${data.aws_caller_identity.base.account_id}:role/test-repo-terraform-deploy"
    session_name = "terraform-deploy"
  }
}

resource "aws_cloudwatch_log_group" "terraform" {
  name = "/aws/codebuild/test"
}
```

```tf
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


##############################
# CodeCommit Repository
##############################
resource "aws_codecommit_repository" "repo" {
  repository_name = "test-repo"
}

##############################
# IAM Group
##############################
resource "aws_iam_group" "groups" {
  name = "codecommit-user"
}

resource "aws_iam_group" "groups-none" {
  name = "codecommit-user-none"
}

##############################
# IAM Group Policy
##############################
resource "aws_iam_group_policy_attachment" "commit" {
  for_each = toset([
    "IAMUserChangePassword",
    "SignInLocalDevelopmentAccess",
    "AWSCodeCommitPowerUser"
  ])

  group      = aws_iam_group.groups.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_group_policy_attachment" "commit-none" {
  for_each = toset([
    "IAMUserChangePassword",
    "SignInLocalDevelopmentAccess"
  ])

  group      = aws_iam_group.groups-none.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

/*
resource "aws_iam_group_policy" "codecommit" {
  name  = "CodeCommitGitAccess"
  group = aws_iam_group.groups.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # 基本操作可能
          "codecommit:GitPull",
          "codecommit:GitPush",
          "codecommit:GetRepository",
          # 閲覧など
          "codecommit:GetObjectIdentifier",
          "codecommit:GetTree",
          "codecommit:GetBlob",
          "codecommit:GetBranch",
          "codecommit:ListBranches",
          "codecommit:GetCommit",
          "codecommit:GetCommitHistory",
          "codecommit:GetReferences",
          "codecommit:GetDifferences",
          # プルリクエスト関連
          "codecommit:ListPullRequests",
          "codecommit:GetPullRequest",
          "codecommit:GetPullRequestApprovalStates",
          "codecommit:GetPullRequestOverrideState"
        ]
        Resource = "arn:aws:codecommit:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = "codecommit:ListRepositories"
        Resource = "*"
      }
    ]
  })
}
*/

##############################
# IAM Group Policy - Access Key & MFA
##############################
resource "aws_iam_group_policy" "self_credentials" {
  name  = "SelfCredentialsManagement"
  group = aws_iam_group.groups.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 自分のAccess Key管理
      {
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:ListAccessKeys",
          "iam:GetAccessKeyLastUsed",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },

      # MFAデバイスの作成
      {
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::*:mfa/*"
      },

      # 自分のMFA管理
      {
        Effect = "Allow"
        Action = [
          "iam:EnableMFADevice",
          "iam:DeactivateMFADevice",
          "iam:GetMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },

      # MFA一覧の参照
      {
        Effect = "Allow"
        Action = [
          "iam:ListVirtualMFADevices",
          "iam:ListUsers"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################
# IAM User
##############################
resource "awscc_iam_user" "users" {
  for_each = var.users

  user_name = each.key
  groups    = [aws_iam_group.groups.name]

  login_profile = {
    password                = var.initial_password
    password_reset_required = true
  }

  lifecycle {
    # 初期パスワードは新規作成時にだけ設定する。
    ignore_changes = [login_profile]
  }
}

resource "awscc_iam_user" "users-none" {
  for_each = var.users-none

  user_name = each.key
  groups    = [aws_iam_group.groups-none.name]

  login_profile = {
    password                = var.initial_password
    password_reset_required = true
  }

  lifecycle {
    # 初期パスワードは新規作成時にだけ設定する。
    ignore_changes = [login_profile]
  }
}


output "console_url" {
  value = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console/"
}

output "repository_url" {
  value = "https://git-codecommit.${data.aws_region.current.region}.amazonaws.com/v1/repos/${aws_codecommit_repository.repo.repository_name}"
}

output "groups" {
  value = aws_iam_group.groups.name
}

output "users" {
  value = [
    for user in awscc_iam_user.users : user.user_name
  ]
}


terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "awscc" {
  region = "ap-northeast-1"
}


#variable "aws_region" {
#  type    = string
#  default = "ap-northeast-1"
#}

variable "users" {
  description = "IAMユーザー名"
  type        = set(string)
  default = [
    "user01",
    "user02"
  ]
}

variable "users-none" {
  description = "IAMユーザー名"
  type        = set(string)
  default = [
    "user-none"
  ]
}

variable "initial_password" {
  description = "ユーザーの初期パスワード"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd"
}

```

```
### buildspec-apply.yml
version: "0.2"

phases:
  install:
    commands:
      - >-
        curl -fsSL https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
        -o /tmp/terraform_1.17.1_linux_amd64.zip
      - echo '4638628058e71a55212b1c563712eac03b902128f40740f3dc8174df12135061  /tmp/terraform_1.17.1_linux_amd64.zip' | sha256sum -c -
      - unzip -oq /tmp/terraform_1.17.1_linux_amd64.zip terraform -d /usr/local/bin
  build:
    commands:
      - terraform init -input=false -no-color
      - terraform apply -input=false -auto-approve -no-color


### buildspec.yml
version: "0.2"

phases:
  install:
    commands:
      - >-
        curl -fsSL https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
        -o /tmp/terraform_1.17.1_linux_amd64.zip
      - echo '4638628058e71a55212b1c563712eac03b902128f40740f3dc8174df12135061  /tmp/terraform_1.17.1_linux_amd64.zip' | sha256sum -c -
      - unzip -oq /tmp/terraform_1.17.1_linux_amd64.zip terraform -d /usr/local/bin
  build:
    commands:
      - terraform init -input=false -no-color
      - terraform validate -no-color
      - terraform plan -input=false -no-color


resource "aws_cloudwatch_log_group" "terraform" {
  name = "/aws/codebuild/${local.pipeline_name}"
}


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
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_VAR_deploy_role_arn"
      value = aws_iam_role.terraform_deploy.arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
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
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_VAR_deploy_role_arn"
      value = aws_iam_role.terraform_deploy.arn
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


resource "aws_codecommit_repository" "terraform" {
  repository_name = "test-repo"
}

output "repository_clone_url" {
  value = aws_codecommit_repository.terraform.clone_url_http
}


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
        Effect   = "Allow"
        Action   = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:GetBucketVersioning"]
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
        Effect   = "Allow"
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
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
        Effect   = "Allow"
        Action   = ["s3:GetBucketAcl", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.state.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = local.workload_state_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.workload_state_arn}.tflock"
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "${aws_cloudwatch_log_group.terraform.arn}:*"
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "${aws_cloudwatch_log_group.terraform.arn}:log-stream:plan*",
          "${aws_cloudwatch_log_group.terraform.arn}:log-stream:apply*",
        ]
      },
    ]
  })
}

resource "aws_iam_role" "terraform_deploy" {
  name = "${local.pipeline_name}-deploy"

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
  role       = aws_iam_role.terraform_deploy.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}
```

```
git -c credential.helper='!aws codecommit credential-helper $@' `
    -c credential.UseHttpPath=true `
    clone https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/test-repo


git -c credential.helper= `
    -c credential.helper='!aws codecommit credential-helper $@' `
    -c credential.UseHttpPath=true `
    clone https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/test-repo


git config --local credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true



git config --local credential.helper ''
git config --local --add credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true

git config --local --unset-all credential.helper
git config --local --add credential.helper """"
git config --local --add credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true

git config --local --unset-all credential.helper
git config --local --add credential.helper ''
git config --local --add credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true

git config --local user.email "obi@test.local"
git config --local user.name "obi"

```
