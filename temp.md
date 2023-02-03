~~~
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

data "aws_iam_policy_document" "sfn_01" {
  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "sfn" {
  name               = "IAM_R_SFU_xt_ExportTask"
  assume_role_policy = data.aws_iam_policy_document.sfn.json
}

resource "aws_iam_policy" "sfn_01" {
  name   = "obi-test-policy-step-function-01"
  policy = data.aws_iam_policy_document.sfn_01.json
}

resource "aws_iam_role_policy_attachment" "sfn_01" {
  role       = aws_iam_role.sfn.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_iam_role_policy_attachment" "sfn_02" {
  role       = aws_iam_role.sfn.name
  policy_arn = aws_iam_policy.sfn_01.arn
}

##############################
# Step Functions
##############################
resource "aws_sfn_state_machine" "sfn" {
  name     = "SFU-mcid1x1t-ExportTask"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  logging_configuration {
    include_execution_data = false
    level                  = "ERROR"
    log_destination        = "${aws_cloudwatch_log_group.sfn_01.arn}:*"
  }

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
                    "Next": "CopyS3Data"
                }
            ],
            "Default": "ExportLogGroup"
        },
        "CopyS3Data": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.lambda_04.arn}",
            "Next": "Succeed"
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

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "sfn_01" {
  name              = "/aws/vendedlogs/SFU-mcid1x1t-ExportTask"
  retention_in_days = 7
}

~~~
