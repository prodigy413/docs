~~~
lambda.tf
##############################
# Lambda Codes
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
##############################
# Lambda For Step Functions: Describe Log Groups
##############################
module "lambda_sfn_describe_log_groups" {
  source = "../modules"
  function_name = var.function_name_lambda_sfn_describe_log_groups
  description   = var.description_lambda_sfn_describe_log_groups
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_sfn_describe_log_groups
  timeout       = var.timeout
  s3_bucket     = var.s3_bucket_lambda_sfn_describe_log_groups
  s3_key        = var.s3_key_lambda_sfn_describe_log_groups
  env_variables = var.env_variables_lambda_sfn_describe_log_groups
}
output "lambda_sfn_describe_log_groups_id" {
  value = module.lambda_sfn_describe_log_groups.lambda_id
}
output "lambda_sfn_describe_log_groups_arn" {
  value = module.lambda_sfn_describe_log_groups.lambda_arn
}
output "lambda_sfn_describe_log_groups_name" {
  value = module.lambda_sfn_describe_log_groups.lambda_name
}
output "lambda_sfn_describe_log_groups_cloudwatch_logs_id" {
  value = module.lambda_sfn_describe_log_groups.cloudwatch_logs_id
}
output "lambda_sfn_describe_log_groups_cloudwatch_logs_arn" {
  value = module.lambda_sfn_describe_log_groups.cloudwatch_logs_arn
}
##############################
# Lambda For Step Functions: Export Log Group
##############################
module "lambda_sfn_export_log_group" {
  source = "../modules"
  function_name = var.function_name_lambda_sfn_export_log_group
  description   = var.description_lambda_sfn_export_log_group
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_sfn_export_log_group
  timeout       = var.timeout
  s3_bucket     = var.s3_bucket_lambda_sfn_export_log_group
  s3_key        = var.s3_key_lambda_sfn_export_log_group
  env_variables = {
    EXPORT_BUCKET = aws_s3_bucket.bucket_01.id
  }
}
output "lambda_sfn_export_log_group_id" {
  value = module.lambda_sfn_export_log_group.lambda_id
}
output "lambda_sfn_export_log_group_arn" {
  value = module.lambda_sfn_export_log_group.lambda_arn
}
output "lambda_sfn_export_log_group_name" {
  value = module.lambda_sfn_export_log_group.lambda_name
}
output "lambda_sfn_export_log_group_cloudwatch_logs_id" {
  value = module.lambda_sfn_export_log_group.cloudwatch_logs_id
}
output "lambda_sfn_export_log_group_cloudwatch_logs_arn" {
  value = module.lambda_sfn_export_log_group.cloudwatch_logs_arn
}
##############################
# Lambda For Step Functions: Describe Export Task
##############################
module "lambda_sfn_describe_export_task" {
  source = "../modules"
  function_name = var.function_name_lambda_sfn_describe_export_task
  description   = var.description_lambda_sfn_describe_export_task
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_sfn_describe_export_task
  timeout       = var.timeout
  s3_bucket     = var.s3_bucket_lambda_sfn_describe_export_task
  s3_key        = var.s3_key_lambda_sfn_describe_export_task
}
output "lambda_sfn_describe_export_task_id" {
  value = module.lambda_sfn_describe_export_task.lambda_id
}
output "lambda_sfn_describe_export_task_arn" {
  value = module.lambda_sfn_describe_export_task.lambda_arn
}
output "lambda_sfn_describe_export_task_name" {
  value = module.lambda_sfn_describe_export_task.lambda_name
}
output "lambda_sfn_describe_export_task_cloudwatch_logs_id" {
  value = module.lambda_sfn_describe_export_task.cloudwatch_logs_id
}
output "lambda_sfn_describe_export_task_cloudwatch_logs_arn" {
  value = module.lambda_sfn_describe_export_task.cloudwatch_logs_arn
}
variables.tf
##############################
# Lambda For Step Functions: Describe Log Groups
##############################
variable "timeout" {
  description = "Lambda関数実行のタイムアウト（秒）"
  type        = number
  default     = 600
}
##############################
# Lambda For Step Functions: Describe Log Groups
##############################
variable "function_name_lambda_sfn_describe_log_groups" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-sfn-DescribeLogGroups"
}
variable "description_lambda_sfn_describe_log_groups" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda for checking target log groups in step functions."
}
variable "handler_lambda_sfn_describe_log_groups" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "describe_log_groups.lambda_handler"
}
variable "s3_bucket_lambda_sfn_describe_log_groups" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}
variable "s3_key_lambda_sfn_describe_log_groups" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}
variable "env_variables_lambda_sfn_describe_log_groups" {
  description = "Lambda関数が利用する環境変数"
  type        = map(string)
  default = {
    LOG_GROUP_LISTS = "[\"/aws/lambda/LMD-mcid1t1t-sfn-DescribeLogGroups\", \"/aws/lambda/LMD-mcid1t1t-sfn-ExportLogGroup\"]"
  }
}
##############################
# Lambda For Step Functions: Export Log Group
##############################
variable "function_name_lambda_sfn_export_log_group" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-sfn-ExportLogGroup"
}
variable "description_lambda_sfn_export_log_group" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda for transferring logs from log group to S3 in step functions."
}
variable "handler_lambda_sfn_export_log_group" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "export_log_group.lambda_handler"
}
variable "s3_bucket_lambda_sfn_export_log_group" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}
variable "s3_key_lambda_sfn_export_log_group" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}
##############################
# Lambda For Step Functions: Describe Export Task
##############################
variable "function_name_lambda_sfn_describe_export_task" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-sfn-DescribeExportTask"
}
variable "description_lambda_sfn_describe_export_task" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda for checking the task status in step functions."
}
variable "handler_lambda_sfn_describe_export_task" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "describe_export_task.lambda_handler"
}
variable "s3_bucket_lambda_sfn_describe_export_task" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}
variable "s3_key_lambda_sfn_describe_export_task" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}
eventbridge.tf
##############################
# Event Bus
##############################
resource "aws_cloudwatch_event_bus" "event" {
  count = var.eventbus_name != null ? 1 : 0
  name = var.eventbus_name
  tags = {
    Terraform = "managed"
    Name      = var.eventbus_name
  }
}
##############################
# Event Rule
##############################
resource "aws_cloudwatch_event_rule" "event" {
  for_each = var.event_rule_parameter != null ? { for k, v in var.event_rule_parameter : v.id => v } : {}
  name                = each.value.name
  event_bus_name      = aws_cloudwatch_event_bus.event[0].name
  description         = lookup(each.value, "description", null)
  is_enabled          = lookup(each.value, "is_enabled", true)
  event_pattern       = lookup(each.value, "event_pattern", null)
  schedule_expression = lookup(each.value, "schedule_expression", null)
  depends_on = [aws_cloudwatch_event_bus.event]
  tags = {
    Terraform = "managed"
    Name      = each.value.name
  }
}
##############################
# Event Target
##############################
resource "aws_cloudwatch_event_target" "event" {
  for_each = var.event_target_parameter != null ? { for k, v in var.event_target_parameter : v.id => v } : {}
  event_bus_name = aws_cloudwatch_event_bus.event[0].name
  rule           = lookup(each.value, "rule", null)
  arn            = lookup(each.value, "arn", null)
  role_arn       = lookup(each.value, "role_arn", null)
  depends_on = [aws_cloudwatch_event_rule.event]
}
##############################
# Output
##############################
output "eventbus_id" {
  value = aws_cloudwatch_event_bus.event[0].id
}
output "eventbus_arn" {
  value = aws_cloudwatch_event_bus.event[0].arn
}
output "event_rule_name" {
  value = tomap({ for k, v in aws_cloudwatch_event_rule.event : k => v.name })
}
variables.tf
##############################
# Event Bus
##############################
variable "eventbus_name" {
  description = "EventBus名"
  type        = string
}
##############################
# Event Rule
##############################
variable "event_rule_parameter" {
  description = "イベントルール設定用パラメータ"
  type        = any
  default     = null
}
##############################
# Event Target
##############################
variable "event_target_parameter" {
  description = "イベントターゲット設定用パラメータ"
  type        = any
  default     = null
}
eventbridge.tf
module "event" {
  source = "../modules"
  event_rule_parameter = [
    {
      id                  = 1
      name                = "EVENTRULE-mcid1t1t-SFU-ExportTask"
      description         = "Rule for periodically executing step functions for Export Task."
      schedule_expression = "cron(0 18 * * ? *)"
    }
  ]
  event_target_parameter = [
    {
      id       = 1
      rule     = module.event.event_rule_name[1]
      arn      = data.aws_sns_topic.sns01.arn
      role_arn = aws_iam_role.event_role.arn
    }
  ]
}
variables.tf
# no variables
step_functions.tf
##############################
# Step Functions
##############################
resource "aws_sfn_state_machine" "sfn" {
  name       = var.sfn_name
  role_arn   = var.role_arn
  definition = var.definition
  type       = var.type
  dynamic "logging_configuration" {
    for_each = var.enable_logging ? [true] : []
    content {
      log_destination        = "${aws_cloudwatch_log_group.sfn[0].arn}:*"
      include_execution_data = var.include_execution_data
      level                  = var.level
    }
  }
  tags = {
    Terraform = "managed"
    Name      = var.sfn_name
  }
}
##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "sfn" {
  count = var.enable_logging ? 1 : 0
  name              = "/aws/vendedlogs/states/${var.sfn_name}"
  retention_in_days = 7
}
variables.tf
##############################
# Step Functions
##############################
variable "sfn_name" {
  description = "Step Functions名"
  type        = string
}
variable "definition" {
  description = "Step FunctionsのAmazon States Language定義"
  type        = string
}
variable "role_arn" {
  description = "Step Functionsが利用するIAMロールのArn"
  type        = string
}
variable "type" {
  description = "作成するstate machineのタイプ(Standard / Express)"
  type        = string
  default     = "STANDARD"
}
variable "include_execution_data" {
  description = "Step Functionsログに実行データを含める"
  type        = bool
  default     = false
}
variable "level" {
  description = "ログ出力するStep Functionsイベントのレベル"
  type        = string
  default     = "ERROR"
}
##############################
# Cloudwatch Logs
##############################
variable "enable_logging" {
  description = "Step Functionsのロギング機能を有効"
  type        = bool
  default     = true
}
variable "retention_in_days" {
  description = "ログの保存期間"
  type        = number
  default     = 90
}
step_functions.tf
module "sfn" {
  source = "../modules"
  sfn_name   = var.sfn_name
  role_arn   = aws_iam_role.sfn.arn
  definition = <<EOF
  {
    "Comment": "A description of my state machine",
    "StartAt": "Hello",
    "States": {
        "Hello": {
            "Type": "Pass",
            "Result": "Hello",
            "Next": "World"
        },
        "World": {
            "Type": "Pass",
            "Result": "Hello World is completed!",
            "End": true
        }
    }
}
EOF
}
/*
  definition     = <<EOF
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
            "Resource": "${data.aws_lambda_function.lambda_01.arn}",
            "ResultPath": "$.describe_log_groups",
            "Next": "ExportLogGroup"
        },
        "ExportLogGroup": {
            "Type": "Task",
            "Resource": "${data.aws_lambda_function.lambda_02.arn}",
            "ResultPath": "$.iterator",
            "Next": "DescribeExportTask"
        },
        "DescribeExportTask": {
            "Type": "Task",
            "Resource": "${data.aws_lambda_function.lambda_03.arn}",
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
*/
variables.tf
##############################
# Step Functions
##############################
variable "sfn_name" {
  description = "The name of the Step Function"
  type        = string
  default     = "SFU-mcid1x1t-ExportTask"
}
~~~
