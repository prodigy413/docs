~~~
##############################
# IAM Role for Lambda
##############################
data "aws_iam_policy_document" "lambda_role" {
  statement {
    actions = ["sts:AssumeRole", ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", ]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateExportTask",
      "logs:DescribeExportTasks"
    ]
    resources = ["arn:aws:logs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "IAM_R_LMD_xt_ExportTask"
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
}

resource "aws_iam_policy" "lambda" {
  name   = "IAM_P_xt_ExportTask"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_01" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "lambda_02" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

##############################
# Lambda
##############################
data "archive_file" "lambda_01" {
  type        = "zip"
  source_dir  = "codes/code/describe_log_groups"
  output_path = "codes/zip/describe_log_groups.zip"
}

data "archive_file" "lambda_02" {
  type        = "zip"
  source_dir  = "codes/code/export_log_group"
  output_path = "codes/zip/export_log_group.zip"
}

data "archive_file" "lambda_03" {
  type        = "zip"
  source_dir  = "codes/code/describe_export_task"
  output_path = "codes/zip/describe_export_task.zip"
}

data "archive_file" "lambda_04" {
  type        = "zip"
  source_dir  = "codes/code/copy_s3_data"
  output_path = "codes/zip/copy_s3_data.zip"
}

resource "aws_lambda_function" "lambda_01" {
  filename         = data.archive_file.lambda_01.output_path
  function_name    = "LMD-mcid1x1t-DescribeLogGroups"
  role             = aws_iam_role.lambda.arn
  handler          = "describe_log_groups.lambda_handler"
  source_code_hash = data.archive_file.lambda_01.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["arm64"]
  layers           = [data.aws_lambda_layer_version.aws_managed_layes_01.arn]
  timeout          = 600

  environment {
    variables = {
      #LOG_GROUP_LISTS = "[\"/aws/lambda/cwlogs-monitoring\", \"/aws/lambda/LMD-mcid1k0t-ops-upload_temp_file_delete\"]"
      #LOG_GROUP_LISTS = "[\"/aws/lambda/LMD-mcid1x1t-DescribeLogGroupsxxx\", \"/aws/lambda/LMD-mcid1x1t-ExportLogGroup\", \"/aws/lambda/LMD-mcid1x1t-DescribeExportTask\"]"
      #PARAMETERS_SECRETS_EXTENSION_LOG_LEVEL = "error"
      #SSM_PARAMETER_STORE_TIMEOUT_MILLIS     = "5000"
      LOG_GROUP_LISTS = join(",", [
        "/aws/lambda/LMD-mcid1x1t-DescribeLogGroups",
        "/aws/lambda/LMD-mcid1x1t-ExportLogGroup",
        "/aws/lambda/test01",
        "/aws/lambda/test02",
        "/aws/lambda/LMD-mcid1x1t-DescribeExportTask"
        #"\"/aws/lambda/LMD-mcid1x1t-DescribeLogGroups\"",
        #"\"/aws/lambda/LMD-mcid1x1t-ExportLogGroup\"",
        #"\"/aws/lambda/LMD-mcid1x1t-DescribeExportTask\""
      ])
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_01,
    aws_cloudwatch_log_group.lambda_01
  ]
}

resource "aws_lambda_function" "lambda_02" {
  filename         = data.archive_file.lambda_02.output_path
  function_name    = "LMD-mcid1x1t-ExportLogGroup"
  role             = aws_iam_role.lambda.arn
  handler          = "export_log_group.lambda_handler"
  source_code_hash = data.archive_file.lambda_02.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["arm64"]
  timeout          = 600

  environment {
    variables = {
      EXPORT_BUCKET = aws_s3_bucket.bucket_01.id
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_01,
    aws_cloudwatch_log_group.lambda_02
  ]
}

resource "aws_lambda_function" "lambda_03" {
  filename         = data.archive_file.lambda_03.output_path
  function_name    = "LMD-mcid1x1t-DescribeExportTask"
  role             = aws_iam_role.lambda.arn
  handler          = "describe_export_task.lambda_handler"
  source_code_hash = data.archive_file.lambda_03.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["arm64"]
  timeout          = 600

  depends_on = [
    aws_iam_role_policy_attachment.lambda_01,
    aws_cloudwatch_log_group.lambda_03
  ]
}

resource "aws_lambda_function" "lambda_04" {
  filename         = data.archive_file.lambda_04.output_path
  function_name    = "LMD-mcid1x1t-CopyS3Data"
  role             = aws_iam_role.lambda.arn
  handler          = "copy_s3_data.lambda_handler"
  source_code_hash = data.archive_file.lambda_04.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["arm64"]
  timeout          = 900

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.bucket_01.id
      TARGET_BUCKET = aws_s3_bucket.bucket_02.id
      SERVICE_LISTS = join(",", [
        "LAMBDA",
        "CHATBOT"
      ])
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_01,
    aws_cloudwatch_log_group.lambda_04
  ]
}

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "lambda_01" {
  name              = "/aws/lambda/LMD-mcid1x1t-DescribeLogGroups"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_02" {
  name              = "/aws/lambda/LMD-mcid1x1t-ExportLogGroup"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_03" {
  name              = "/aws/lambda/LMD-mcid1x1t-DescribeExportTask"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_04" {
  name              = "/aws/lambda/LMD-mcid1x1t-CopyS3Data"
  retention_in_days = 7
}

##############################
# Parameter Store
##############################
#resource "aws_ssm_parameter" "parameter_01" {
#  name        = "log_group_lists"
#  description = "The parameter description"
#  type        = "StringList"
#  value       = "/aws/lambda/LMD-mcid1x1t-DescribeLogGroups, /aws/lambda/LMD-mcid1x1t-ExportLogGroup, /aws/lambda/LMD-mcid1x1t-DescribeExportTask"
#}
































import os
import boto3
from datetime import datetime, timedelta
import logger

s3 = boto3.client('s3')

mylogger = logger.MCIDLogger(__name__)
mylogger.setup("INFO", True)

def upload_task_01(source_bucket):
    s3 = boto3.client('s3')
    for i in range(11):
        with open(f'/tmp/file{i}', 'w') as f:
            f.write('This is test file.')
        s3.upload_file(
            Filename=f'/tmp/file{i}',
            Bucket=source_bucket,
            Key=f'logfile/LAMBDA/2023/02/02/file{i}/test.txt'
        )

def upload_task_02(source_bucket):
    s3 = boto3.client('s3')
    for i in range(11):
        with open(f'/tmp/file{i}', 'w') as f:
            f.write('This is test file.')
        s3.upload_file(
            Filename=f'/tmp/file{i}',
            Bucket=source_bucket,
            Key=f'logfile/EC2/2023/02/02/file{i}'
        )

def copy_task(source_bucket, target_bucket, key):
    s3 = boto3.resource('s3')
    source_info = {
        'Bucket': source_bucket,
        'Key': key
    }
    s3.Object(target_bucket, key).copy(source_info)


def lambda_handler(event, context):

    # Get ENV
    source_bucket = os.environ['SOURCE_BUCKET']
    target_bucket = os.environ['TARGET_BUCKET']
    service_list = os.environ['SERVICE_LISTS'].split(',')

    # Var for counting copied_objects
    copied_objects = 0

    #upload_task_01(source_bucket)
    #upload_task_02(source_bucket)

    # 前日取得（例：2023-01-30 - 1 = 2023-01-29）
    yesterday = datetime.now().date() - timedelta(days=1)

    # list_objects fff
    paginator = s3.get_paginator('list_objects_v2')

    for service_name in service_list:
        prefix = f"logfile/{service_name}/{yesterday.strftime('%Y/%m/%d')}"
        pages = paginator.paginate(Bucket=source_bucket, Prefix=prefix)

        for page in pages:
            if 'Contents' in page.keys():
                for obj in page['Contents']:
                    if not obj['Key'].endswith('/aws-logs-write-test'):
                        copy_task(source_bucket, target_bucket, obj['Key'])
                        copied_objects += 1
            else:
                mylogger.warning(f'{prefix} is empty.')

    mylogger.info(f'{str(copied_objects)} objects copied.')

~~~
