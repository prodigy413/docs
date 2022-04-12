~~~
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project
resource "aws_codebuild_project" "build_01" {
  name          = "test-project"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.role_01.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
    #type     = "S3"
    #location = aws_s3_bucket.example.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    #environment_variable {
    #  name  = "SOME_KEY1"
    #  value = "SOME_VALUE1"
    #}

    #environment_variable {
    #  name  = "SOME_KEY2"
    #  value = "SOME_VALUE2"
    #  type  = "PARAMETER_STORE"
    #}
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/CodeBuild"
      stream_name = "test-project"
    }

    #s3_logs {
    #  status   = "ENABLED"
    #  location = "${aws_s3_bucket.example.id}/build-log"
    #}
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.repo_01.clone_url_http
    git_clone_depth = 1

    #git_submodules_config {
    #  fetch_submodules = true
    #}
  }

  source_version = "refs/heads/main"

  #  vpc_config {
  #    vpc_id = aws_vpc.example.id
  #
  #    subnets = [
  #      aws_subnet.example1.id,
  #      aws_subnet.example2.id,
  #    ]
  #
  #    security_group_ids = [
  #      aws_security_group.example1.id,
  #      aws_security_group.example2.id,
  #    ]
  #  }

  depends_on = [
    aws_cloudwatch_log_group.log_01,
    aws_codecommit_repository.repo_01
  ]
}

data "aws_iam_policy_document" "sts_01" {
  statement {
    sid     = "CodebuildAssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_01" {
  name                  = "codebuild-role-01"
  assume_role_policy    = data.aws_iam_policy_document.sts_01.json
  force_detach_policies = true
}

resource "aws_iam_role_policy" "policy_01" {
  name   = "codebuild-policy-01"
  role   = aws_iam_role.role_01.name
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/CodeBuild",
                "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/CodeBuild:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codecommit:ap-northeast-1:844065555252:test"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:ap-northeast-1:844065555252:report-group/test-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:GetObject",
                "s3:List*",
                "s3:PutObject"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

#CodeBuildBasePolicy-test-ap-northeast-1
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Resource": [
#                "arn:aws:logs:ap-northeast-1:844065555252:log-group:CodeBuild",
#                "arn:aws:logs:ap-northeast-1:844065555252:log-group:CodeBuild:*"
#            ],
#            "Action": [
#                "logs:CreateLogGroup",
#                "logs:CreateLogStream",
#                "logs:PutLogEvents"
#            ]
#        },
#        {
#            "Effect": "Allow",
#            "Resource": [
#                "arn:aws:s3:::codepipeline-ap-northeast-1-*"
#            ],
#            "Action": [
#                "s3:PutObject",
#                "s3:GetObject",
#                "s3:GetObjectVersion",
#                "s3:GetBucketAcl",
#                "s3:GetBucketLocation"
#            ]
#        },
#        {
#            "Effect": "Allow",
#            "Resource": [
#                "arn:aws:codecommit:ap-northeast-1:844065555252:test"
#            ],
#            "Action": [
#                "codecommit:GitPull"
#            ]
#        },
#        {
#            "Effect": "Allow",
#            "Action": [
#                "codebuild:CreateReportGroup",
#                "codebuild:CreateReport",
#                "codebuild:UpdateReport",
#                "codebuild:BatchPutTestCases",
#                "codebuild:BatchPutCodeCoverages"
#            ],
#            "Resource": [
#                "arn:aws:codebuild:ap-northeast-1:844065555252:report-group/test-*"
#            ]
#        }
#    ]
#}

#CodeBuildCloudWatchLogsPolicy-test-ap-northeast-1
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Resource": [
#                "arn:aws:logs:ap-northeast-1:844065555252:log-group:CodeBuild",
#                "arn:aws:logs:ap-northeast-1:844065555252:log-group:CodeBuild:*"
#            ],
#            "Action": [
#                "logs:CreateLogGroup",
#                "logs:CreateLogStream",
#                "logs:PutLogEvents"
#            ]
#        }
#    ]
#}













version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - aws s3 cp s3://great-obi-s3-01/obi-test s3://great-obi-s3-01-bk/obi-test --recursive
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...








resource "aws_cloudwatch_log_group" "log_01" {
  name              = "/aws/CodeBuild"
  retention_in_days = 7
}








resource "aws_codecommit_repository" "repo_01" {
  repository_name = "test"
  description     = "This is the Test Repository"
}






locals {
  environment              = "dev"
  product_name             = "greatobi"
  terraform_operation_user = "xxxxxx"
  deletion_protection      = false
}

terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      environment = local.environment
      name        = local.product_name
    }
  }
}










##############################
# Source bucket
##############################
resource "aws_s3_bucket" "bucket_01" {
  bucket        = "great-obi-s3-01"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl_01" {
  bucket = aws_s3_bucket.bucket_01.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_01" {
  bucket = aws_s3_bucket.bucket_01.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_01" {
  bucket = aws_s3_bucket.bucket_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket_policy" "bucket_policy_01" {
#  bucket = aws_s3_bucket.bucket_01.id
#  policy = data.aws_iam_policy_document.s3_cloudfront_policy.json
#}

##############################
# Destination bucket
##############################
resource "aws_s3_bucket" "bucket_01_bk" {
  bucket        = "great-obi-s3-01-bk"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl_01_bk" {
  bucket = aws_s3_bucket.bucket_01_bk.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_01_bk" {
  bucket = aws_s3_bucket.bucket_01_bk.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_01_bk" {
  bucket = aws_s3_bucket.bucket_01_bk.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket_policy" "bucket_policy_01_bk" {
#  bucket = aws_s3_bucket.bucket_01_bk.id
#  policy = data.aws_iam_policy_document.s3_cloudfront_policy.json
#}



























import boto3

def lambda_handler(event, context):

  sourceBucket = "great-obi-s3-01"
  targetBucket = "great-obi-s3-01-bk"

  s3 = boto3.resource('s3')

  my_bucket = s3.Bucket(sourceBucket)

  for my_bucket_object in my_bucket.objects.all():
      bucketKey = my_bucket_object.key
      if bucketKey.startswith('obi-test/'):
          copy_source = {'Bucket': sourceBucket, 'Key': bucketKey}
          bucket = s3.Bucket(targetBucket)
          bucket.copy(copy_source, bucketKey)







variable "log_group" {
  default = [
    "test-lambda-01",
    "test-lambda-02"
  ]
  type = list(string)
}

resource "aws_cloudwatch_log_group" "test-lambda-01" {
  for_each          = toset(var.log_group)
  name              = "/aws/lambda/${local.product_name}-${each.key}-${local.environment}"
  retention_in_days = 7
}






resource "aws_iam_role" "test_lambda" {
  name               = "${local.product_name}-test-lambda-${local.environment}"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "lambda_access_policy" {
  name   = "${local.product_name}-test-lambda-${local.environment}"
  role   = aws_iam_role.test_lambda.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:GetObject",
                "s3:List*",
                "s3:PutObject"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}






data "archive_file" "zip_source" {
  type        = "zip"
  source_file = "upload_code/code/s3.py"
  output_path = "upload_code/zip/s3.zip"
}

resource "aws_lambda_function" "test_lambda_01" {
  filename         = data.archive_file.zip_source.output_path
  function_name    = "${local.product_name}-test-lambda-01-${local.environment}"
  role             = aws_iam_role.test_lambda.arn
  handler          = "s3.lambda_handler"
  source_code_hash = data.archive_file.zip_source.output_base64sha256
  runtime          = "python3.9"
  timeout          = 60
}








~~~
