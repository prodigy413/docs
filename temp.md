~~~
describe_export_task.py
import boto3

logs_client = boto3.client('logs')

def lambda_handler(event, context):
    task_id = event['iterator']['task_id']

    #エクスポートタスク ステータス取得
    response = logs_client.describe_export_tasks(
        taskId=task_id,
    )
    status_code = response['exportTasks'][0]['status']['code']

    return {
        'status_code': status_code
    }









describe_log_groups.py
import os
import json

def lambda_handler(event, context):
    log_groups = json.loads(os.environ['LOG_GROUP_LISTS'])
    print(log_groups)
    print(type(log_groups))

    return {
        'element_num':len(log_groups),
        'log_groups':log_groups
    }










export_log_group.py
import os
import boto3
import datetime

logs_client = boto3.client('logs')

def lambda_handler(event, context):
    export_bucket = os.environ['EXPORT_BUCKET']
    index = event['iterator']['index']
    count = event['describe_log_groups']['element_num']
    target_log_group = event['describe_log_groups']['log_groups']
    target_log_group_for_s3 = target_log_group[index].replace("/", "_")

    today = datetime.date.today()                    #実行日取得（例：2019-09-12）
    yesterday = today - datetime.timedelta(days=1)   #前日取得（例：2019-09-11）
    ##出力日時（from）取得（例：2019-09-11 00:00:00）
    #from_time = datetime.datetime(year=today.year, month=today.month, day=yesterday.day, hour=0, minute=0,second=0)
    ##出力日時（to）取得（例：2019-09-11 23:59:59.999999）
    #to_time = datetime.datetime(year=today.year, month=today.month, day=yesterday.day, hour=23, minute=59,second=59,microsecond=999999)
    #出力日時（from）取得（例：2019-09-11 00:00:00）
    from_time = datetime.datetime(year=today.year, month=today.month, day=today.day, hour=0, minute=0,second=0)
    #出力日時（to）取得（例：2019-09-11 23:59:59.999999）
    to_time = datetime.datetime(year=today.year, month=today.month, day=today.day, hour=23, minute=59,second=59,microsecond=999999)

    #エポック時刻取得(float型)
    epoc_from_time = from_time.timestamp()
    epoc_to_time = to_time.timestamp()
    #エポック時刻をミリ秒にしint型にキャスト（create_export_taskメソッドにintで渡すため）
    m_epoc_from_time = int(epoc_from_time * 1000)
    m_epoc_epoc_to_time = int(epoc_to_time * 1000)

    #CloudWatch Logsエクスポート
    response = logs_client.create_export_task(
        logGroupName = target_log_group[index],
        fromTime = m_epoc_from_time,
        to = m_epoc_epoc_to_time,
        destination = export_bucket,
        destinationPrefix = f"{yesterday.strftime('%Y%m%d')}/{target_log_group_for_s3}"
    )

    index += 1

    return {
        'index':index,
        'end_flg':count == index,
        'task_id':response['taskId']
    }











data.tf
data "aws_caller_identity" "current" {}










lambda.tf
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
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
  source_file = "codes/code/describe_log_groups.py"
  output_path = "codes/zip/describe_log_groups.zip"
}

data "archive_file" "lambda_02" {
  type        = "zip"
  source_file = "codes/code/export_log_group.py"
  output_path = "codes/zip/export_log_group.zip"
}

data "archive_file" "lambda_03" {
  type        = "zip"
  source_file = "codes/code/describe_export_task.py"
  output_path = "codes/zip/describe_export_task.zip"
}

resource "aws_lambda_function" "lambda_01" {
  filename         = data.archive_file.lambda_01.output_path
  function_name    = "LMD-mcid1x1t-DescribeLogGroups"
  role             = aws_iam_role.lambda.arn
  handler          = "describe_log_groups.lambda_handler"
  source_code_hash = data.archive_file.lambda_01.output_base64sha256
  runtime          = "python3.9"
  timeout          = 600

  environment {
    variables = {
      #LOG_GROUP_LISTS = "[\"/aws/lambda/cwlogs-monitoring\", \"/aws/lambda/LMD-mcid1k0t-ops-upload_temp_file_delete\"]"
      LOG_GROUP_LISTS = "[\"/aws/lambda/LMD-mcid1x1t-DescribeLogGroups\", \"/aws/lambda/LMD-mcid1x1t-ExportLogGroup\"]"
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
  timeout          = 600

  environment {
    variables = {
      EXPORT_BUCKET = "bucket-for-export-log-test-20230120"
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
  timeout          = 600

  depends_on = [
    aws_iam_role_policy_attachment.lambda_01,
    aws_cloudwatch_log_group.lambda_03
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




















preconfiguration.tf
##############################
# Test bucket
##############################
resource "aws_s3_bucket" "bucket_01" {
  bucket        = "bucket-for-export-log-task-test-20230120"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_01" {
  bucket = aws_s3_bucket.bucket_01.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "bucket_01" {
  bucket = aws_s3_bucket.bucket_01.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_01" {
  bucket = aws_s3_bucket.bucket_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################
# Test bucket policy
##############################
data "aws_iam_policy_document" "bucket_01" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.ap-northeast-1.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.bucket_01.arn]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.ap-northeast-1.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.bucket_01.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_01" {
  bucket = aws_s3_bucket.bucket_01.id
  policy = data.aws_iam_policy_document.bucket_01.json
}

















step_functions.tf
##############################
# IAM Role for Step Functions
##############################
data "aws_iam_policy_document" "sfn" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}
/*
data "aws_iam_policy_document" "this_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction", # To run lambda
      "lambda:InvokeAsync"     # To run lambda
    ]
    resources = ["*"]
  }
}
*/
resource "aws_iam_role" "sfn" {
  name               = "IAM_R_SFU_xt_ExportTask"
  assume_role_policy = data.aws_iam_policy_document.sfn.json
}
/*
resource "aws_iam_policy" "this" {
  name   = "obi-test-policy-step-function-01"
  policy = data.aws_iam_policy_document.this_policy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
*/
resource "aws_iam_role_policy_attachment" "sfn_01" {
  role       = aws_iam_role.sfn.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

##############################
# Step Functions
##############################
resource "aws_sfn_state_machine" "sfn" {
  name     = "SFU-mcid1x1t-ExportTask"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  definition = <<EOF
{
    "StartAt": "Configure",
    "TimeoutSeconds": 14400,
    "States": {
        "Configure": {
            "Type": "Pass",
            "Result": {
                "index": 0
            },
            "ResultPath": "$.iterator",
            "Next": "DescribeLogGroups"
        },
        "DescribeLogGroups": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_01.arn}",
            "ResultPath": "$.describe_log_groups",
            "Next": "ExportLogGroup"
        },
        "ExportLogGroup": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_02.arn}",
            "ResultPath": "$.iterator",
            "Next": "DescribeExportTask"
        },
        "DescribeExportTask": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_03.arn}",
            "ResultPath": "$.describe_export_task",
            "Next": "IsExportTask"
        },
        "IsExportTask": {
            "Type": "Choice",
            "Choices": [
                {
                    "Variable": "$.describe_export_task.status_code",
                    "StringEquals": "COMPLETED",
                    "Next": "IsComplete"
                },
                {
                    "Or": [
                        {
                            "Variable": "$.describe_export_task.status_code",
                            "StringEquals": "PENDING"
                        },
                        {
                            "Variable": "$.describe_export_task.status_code",
                            "StringEquals": "RUNNING"
                        }
                    ],
                    "Next": "WaitSeconds"
                }
            ],
            "Default": "Fail"
        },
        "WaitSeconds": {
            "Type": "Wait",
            "Seconds": 1,
            "Next": "DescribeExportTask"
        },
        "IsComplete": {
            "Type": "Choice",
            "Choices": [
                {
                    "Variable": "$.iterator.end_flg",
                    "BooleanEquals": true,
                    "Next": "Succeed"
                }
            ],
            "Default": "ExportLogGroup"
        },
        "Succeed": {
            "Type": "Succeed"
        },
        "Fail": {
            "Type": "Fail"
        }
    }
}
EOF
}


~~~
