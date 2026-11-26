### Personal

```
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = "ap-northeast-1"
  user_name  = "alice"
  name       = "terraform-${local.user_name}"

  repository_arn = "arn:aws:codecommit:${local.region}:${local.account_id}:${local.name}"
  pipeline_arn   = "arn:aws:codepipeline:${local.region}:${local.account_id}:${local.name}"
  codebuild_arn  = "arn:aws:codebuild:${local.region}:${local.account_id}:project/${local.name}"
  log_group_arn  = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/${local.name}"

  state_bucket    = "company-terraform-state"
  state_key       = "${local.user_name}/terraform.tfstate"
  artifact_bucket = "company-artifact-alice"
}



data "aws_iam_policy_document" "alice" {

  # 一覧表示
  statement {
    sid    = "ListResources"
    effect = "Allow"

    actions = [
      "codecommit:ListRepositories",
      "codepipeline:ListPipelines",
      "codebuild:ListProjects"
    ]

    resources = ["*"]
  }

  # CodeCommit：自分のRepositoryのみ操作可能
  statement {
    sid    = "CodeCommitAccess"
    effect = "Allow"

    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush",
      "codecommit:Get*",
      "codecommit:ListBranches",
      "codecommit:ListFileCommitHistory"
    ]

    resources = [local.repository_arn]
  }

  # CodePipeline：自分のPipelineのみReadOnly
  statement {
    sid    = "CodePipelineReadOnly"
    effect = "Allow"

    actions = [
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineState",
      "codepipeline:GetPipelineExecution",
      "codepipeline:ListPipelineExecutions",
      "codepipeline:ListActionExecutions"
    ]

    resources = [local.pipeline_arn]
  }

  # CodeBuild：自分のProjectのみReadOnly
  statement {
    sid    = "CodeBuildReadOnly"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetProjects",
      "codebuild:BatchGetBuilds",
      "codebuild:ListBuildsForProject"
    ]

    resources = [local.codebuild_arn]
  }

  # CloudWatch Logs：自分のログのみReadOnly
  statement {
    sid    = "CloudWatchLogsReadOnly"
    effect = "Allow"

    actions = [
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      local.log_group_arn,
      "${local.log_group_arn}:*"
    ]
  }
}
```

### Group

```
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = "ap-northeast-1"
}



resource "aws_iam_group" "terraform_users" {
  name = "terraform-users"
}

resource "aws_iam_user" "users" {
  for_each = toset(["alice", "bob", "charlie"])

  name = each.key
}

resource "aws_iam_group_membership" "terraform_users" {
  name  = "terraform-users-membership"
  group = aws_iam_group.terraform_users.name
  users = [for user in aws_iam_user.users : user.name]
}



data "aws_iam_policy_document" "terraform_users" {

  # 一覧表示
  statement {
    actions = [
      "codecommit:ListRepositories",
      "codepipeline:ListPipelines",
      "codebuild:ListProjects"
    ]

    resources = ["*"]
  }

  # CodeCommit
  statement {
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush",
      "codecommit:Get*",
      "codecommit:ListBranches",
      "codecommit:ListFileCommitHistory"
    ]

    resources = [
      "arn:aws:codecommit:${local.region}:${local.account_id}:terraform-&{aws:username}"
    ]
  }

  # CodePipeline ReadOnly
  statement {
    actions = [
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineState",
      "codepipeline:GetPipelineExecution",
      "codepipeline:ListPipelineExecutions",
      "codepipeline:ListActionExecutions"
    ]

    resources = [
      "arn:aws:codepipeline:${local.region}:${local.account_id}:terraform-&{aws:username}"
    ]
  }

  # CodeBuild ReadOnly
  statement {
    actions = [
      "codebuild:BatchGetProjects",
      "codebuild:BatchGetBuilds",
      "codebuild:ListBuildsForProject"
    ]

    resources = [
      "arn:aws:codebuild:${local.region}:${local.account_id}:project/terraform-&{aws:username}"
    ]
  }

  # CloudWatch Logs ReadOnly
  statement {
    actions = [
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/terraform-&{aws:username}",
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/terraform-&{aws:username}:*"
    ]
  }
}



resource "aws_iam_policy" "terraform_users" {
  name   = "terraform-users-policy"
  policy = data.aws_iam_policy_document.terraform_users.json
}

resource "aws_iam_group_policy_attachment" "terraform_users" {
  group      = aws_iam_group.terraform_users.name
  policy_arn = aws_iam_policy.terraform_users.arn
}




```
