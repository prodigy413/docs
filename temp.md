~~~
data "aws_cloudwatch_log_group" "lg_01" {
  name = "/aws/lambda/obi-test-lambda-01"
}
























##############################
# Metrics Filter CRITICAL (loggroup01)
##############################
module "metrics_filter_01" {
  source = "../modules"

  filter_name           = var.filter_name_01
  filter_pattern        = var.filter_pattern_01
  filter_log_group_name = data.aws_cloudwatch_log_group.lg_01.name
  metric_name           = var.metric_name_01
  metric_namespace      = var.metric_namespace_01
  metric_unit           = var.metric_unit
}

output "metric_filter_01_critical_id" {
  value = module.metrics_filter_01.metric_filter_id
}

output "metric_filter_01_critical_metric_name" {
  value = module.metrics_filter_01.metric_filter_metric_name
}

##############################
# Metrics Filter WARNING (loggroup01)
##############################
module "metrics_filter_02" {
  source = "../modules"

  filter_name           = var.filter_name_02
  filter_pattern        = var.filter_pattern_02
  filter_log_group_name = data.aws_cloudwatch_log_group.lg_01.name
  metric_name           = var.metric_name_02
  metric_namespace      = var.metric_namespace_02
  metric_unit           = var.metric_unit
}

output "metric_filter_02_warning_id" {
  value = module.metrics_filter_02.metric_filter_id
}

output "metric_filter_02_critical_metric_name" {
  value = module.metrics_filter_02.metric_filter_metric_name
}

##############################
# Metrics Filter CRITICAL (loggroup02)
##############################
module "metrics_filter_03" {
  source = "../modules"

  filter_name           = var.filter_name_03
  filter_pattern        = var.filter_pattern_03
  filter_log_group_name = data.aws_cloudwatch_log_group.lg_01.name
  metric_name           = var.metric_name_03
  metric_namespace      = var.metric_namespace_03
  metric_unit           = var.metric_unit
}

output "metric_filter_03_critical_id" {
  value = module.metrics_filter_03.metric_filter_id
}

output "metric_filter_03_critical_metric_name" {
  value = module.metrics_filter_03.metric_filter_metric_name
}















##############################
# Common
##############################
variable "metric_unit" {
  description = "メトリクスに設定する秒/個などの単位"
  type        = string
  default     = "Count"
}

##############################
# Metrics Filter CRITICAL (loggroup01)
##############################
variable "filter_name_01" {
  description = "メトリクスフィルター名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-01-CRIT"
}

variable "filter_pattern_01" {
  description = "ログを抽出するフィルターパターン"
  type        = string
  default     = "ERROR"
}

variable "metric_name_01" {
  description = "作成するメトリクス名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-01-CRIT-metrics"
}

variable "metric_namespace_01" {
  description = "メトリクス用ネームスペース名"
  type        = string
  default     = "CWLogs"
}

##############################
# Metrics Filter WARNING (loggroup01)
##############################
variable "filter_name_02" {
  description = "メトリクスフィルター名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-01-WARN"
}

variable "filter_pattern_02" {
  description = "ログを抽出するフィルターパターン"
  type        = string
  default     = "WARN"
}

variable "metric_name_02" {
  description = "作成するメトリクス名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-01-WARN-metrics"
}

variable "metric_namespace_02" {
  description = "メトリクス用ネームスペース名"
  type        = string
  default     = "CWLogs"
}

##############################
# Metrics Filter CRITICAL (loggroup02)
##############################
variable "filter_name_03" {
  description = "メトリクスフィルター名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-02-CRIT"
}

variable "filter_pattern_03" {
  description = "ログを抽出するフィルターパターン"
  type        = string
  default     = "xxxx"
}

variable "metric_name_03" {
  description = "作成するメトリクス名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-02-CRIT-metrics"
}

variable "metric_namespace_03" {
  description = "メトリクス用ネームスペース名"
  type        = string
  default     = "CWLogs"
}















data "aws_sns_topic" "sns_01" {
  name = "SNS-mcid1t1t-metrics-mail-CRIT"
}

data "aws_sns_topic" "sns_02" {
  name = "SNS-mcid1t1t-metrics-redmine-CRIT"
}

data "aws_sns_topic" "sns_03" {
  name = "SNS-mcid1t1t-metrics-slack-CRIT"
}




























##############################
# Metrics Filter CRITICAL ALARM (LogGroup: xxxxxxx)
##############################
module "alarm_01" {
  source = "../modules"

  alarm_name          = var.alarm_name_01
  alarm_description   = var.alarm_description_01
  comparison_operator = var.comparison_operator_01
  evaluation_periods  = var.evaluation_periods_01
  datapoints_to_alarm = var.datapoints_to_alarm_01
  threshold           = var.threshold_01
  alarm_actions = [
    data.aws_sns_topic.sns_01.arn,
    data.aws_sns_topic.sns_02.arn,
    data.aws_sns_topic.sns_03.arn
  ]

  metric_name = var.metric_name_01
  namespace   = var.namespace_01
  period      = var.period_01
  statistic   = var.statistic_01
}

output "alarm_lgmf_id" {
  value = module.alarm_01.cloudwatch_alarm_id
}

output "alarm_lgmf_arn" {
  value = module.alarm_01.cloudwatch_alarm_arn
}

























##############################
# ALARM: Metrics Filter / CRITICAL (LogGroup: xxxxxxx)
##############################
variable "alarm_name_01" {
  description = "アラーム名"
  type        = string
  default     = "ALARM-mcid1t1t-FLTM-error-CRIT"
}

variable "alarm_description_01" {
  description = "アラーム説明"
  type        = string
  default     = "Configuration to trigger critical alarms from FLTM-based metrics."
}

variable "comparison_operator_01" {
  description = "StatisticとThresholdに利用する比較演算子"
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
}

variable "evaluation_periods_01" {
  description = "指定しきい値を確認する回数"
  type        = number
  default     = 1
}

variable "threshold_01" {
  description = "監視するメトリクスのしきい値"
  type        = number
  default     = 1
}

variable "datapoints_to_alarm_01" {
  description = "アラームをトリガーするためのしきい値を超えた回数"
  type        = number
  default     = 1
}

variable "metric_name_01" {
  description = "監視するメトリクス名"
  type        = string
  default     = "FLTM-mcid1t1t-log-group-01-CRIT-metrics"
}

variable "namespace_01" {
  description = "監視するメトリクスのネームスペース"
  type        = string
  default     = "CWLogs"
}

variable "period_01" {
  description = "メトリクスを確認する頻度（秒）"
  type        = number
  default     = 60
}

variable "statistic_01" {
  description = "メトリクスに適用される統計方法"
  type        = string
  default     = "Average"
}




/*
variable "dimensions_02" {
  description = "監視するメトリクスのディメンション"
  type        = any
  default = {
    exe        = "amazon-cloudwatch-agent"
    pid_finder = "native"
  }
}

      - metric_name               = "procstat_lookup_pid_count" -> null
      - namespace                 = "CWAgent" ->
*/














data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "obi-test-org"
    workspaces   = { name = "obi-test-ws-01" }
  }
}
/*
data "aws_sns_topic" "sns_01" {
  name = "SNS-mcid1t1t-metrics-redmine-CRIT"
}
*/
# role
#data "aws_sns_topic" "role_01" {
#  name = "SNS-mcid1t1t-ALARM_NOTIF_To_Email_01"
#}























##############################
# Lambda
##############################
module "lambda_01" {
  source = "../modules"

  function_name          = var.function_name_lambda_01
  description            = var.description_lambda_01
  role                   = aws_iam_role.lambda.arn
  handler                = var.handler_lambda_01
  vpc_security_group_ids = ["sg-a31165e0"]
  vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket              = var.s3_bucket_lambda_01
  s3_key                 = var.s3_key_lambda_01
  # env_variables = var.env_variables_lambda_01

  #lambda_permission_principal  = var.lambda_permission_principal_lambda_01
  #lambda_permission_source_arn = data.aws_sns_topic.sns_01.arn
}

output "lambda_01_id" {
  value = module.lambda_01.lambda_id
}

output "lambda_01_arn" {
  value = module.lambda_01.lambda_arn
}

output "lambda_01_name" {
  value = module.lambda_01.lambda_name
}

output "lambda_01_cloudwatch_logs_id" {
  value = module.lambda_01.cloudwatch_logs_id
}

output "lambda_01_cloudwatch_logs_arn" {
  value = module.lambda_01.cloudwatch_logs_arn
}

##############################
# Lambda
##############################

##############################
# Lambda
##############################
















##############################
# Lambda Function (Metrics To Redmine)
##############################
variable "function_name_lambda_01" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-metrics_to_redmine001"
}

variable "description_lambda_01" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda to notify redmine of metrics alarm."
}

variable "handler_lambda_01" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_01" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-filestore-01"
}

variable "s3_key_lambda_01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}

#variable "env_variables_lambda_01" {
#  description = "Lambda関数が利用する環境変数"
#  type        = map(string)
#  default     = null
#}

variable "lambda_permission_principal_lambda_01" {
  description = ""
  type        = string
  default     = "sns.amazonaws.com"
}



















data "aws_lambda_function" "lambda" {
  function_name = "LMD-mcid1t1t-metrics_to_redmine001"
}

















##############################
# SNS Topic (CRITICAL Alarm To Email)
##############################
module "sns_01" {
  source = "../modules"

  topic_name             = var.topic_name_01
  subscription_parameter = var.subscription_parameter_01
}

output "sns_01_id" {
  value = module.sns_01.sns_topic_id
}

output "sns_01_arn" {
  value = module.sns_01.sns_topic_arn
}

output "sns_01_subscription_01_arn" {
  value = module.sns_01.sns_subscription_arn[1]
}

##############################
# SNS Topic (CRITICAL Alarm To Lambda)
##############################
module "sns_02" {
  source = "../modules"

  topic_name = var.topic_name_02
  subscription_parameter = [
    {
      id       = 1
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda.arn
    }
  ]
}

output "sns_02_id" {
  value = module.sns_02.sns_topic_id
}

output "sns_02_arn" {
  value = module.sns_02.sns_topic_arn
}

output "sns_02_subscription_02_arn" {
  value = module.sns_02.sns_subscription_arn
}

##############################
# SNS Topic (CRITICAL Alarm To ChatBot)
##############################
module "sns_03" {
  source = "../modules"

  topic_name = var.topic_name_03
  # subscription_parameter = var.subscription_parameter_03
}

output "sns_03_id" {
  value = module.sns_03.sns_topic_id
}

output "sns_03_arn" {
  value = module.sns_03.sns_topic_arn
}

output "sns_03_subscription_03_arn" {
  value = module.sns_03.sns_subscription_arn
}

##############################
# SNS Topic (WARNING Alarm To ChatBot)
##############################
module "sns_04" {
  source = "../modules"

  topic_name = var.topic_name_04
  # subscription_parameter = var.subscription_parameter_04
}

output "sns_04_id" {
  value = module.sns_04.sns_topic_id
}

output "sns_04_arn" {
  value = module.sns_04.sns_topic_arn
}

output "sns_04_subscription_04_arn" {
  value = module.sns_04.sns_subscription_arn
}

##############################
# SNS Topic (INFO Alarm To ChatBot)
##############################
module "sns_05" {
  source = "../modules"

  topic_name = var.topic_name_05
  # subscription_parameter = var.subscription_parameter_05
}

output "sns_05_id" {
  value = module.sns_05.sns_topic_id
}

output "sns_05_arn" {
  value = module.sns_05.sns_topic_arn
}

output "sns_05_subscription_05_arn" {
  value = module.sns_05.sns_subscription_arn
}

















##############################
# SNS 01
##############################
variable "topic_name_01" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = "SNS-mcid1t1t-metrics-mail-CRIT"
}

variable "subscription_parameter_01" {
  description = "サブスクリプション設定用パラメータ"
  type        = any
  default = [
    {
      id       = 1
      protocol = "email"
      endpoint = "zerozero413@gmail.com"
    }
  ]
}

##############################
# SNS 02
##############################
variable "topic_name_02" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = "SNS-mcid1t1t-metrics-redmine-CRIT"
}

##############################
# SNS 03
##############################
variable "topic_name_03" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = "SNS-mcid1t1t-metrics-slack-CRIT"
}

variable "subscription_parameter_03" {
  description = "サブスクリプション設定用パラメータ"
  type        = any
  default = [
    {
      protocol = "email"
      endpoint = "zerozero413pgmail.com"
    }
  ]
}

##############################
# SNS 04
##############################
variable "topic_name_04" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = "SNS-mcid1t1t-metrics-slack-WARN"
}

variable "subscription_parameter_04" {
  description = "サブスクリプション設定用パラメータ"
  type        = any
  default = [
    {
      protocol = "email"
      endpoint = "zerozero413pgmail.com"
    }
  ]
}

##############################
# SNS 05
##############################
variable "topic_name_05" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = "SNS-mcid1t1t-metrics-slack-INFO"
}

variable "subscription_parameter_05" {
  description = "サブスクリプション設定用パラメータ"
  type        = any
  default = [
    {
      protocol = "email"
      endpoint = "zerozero413pgmail.com"
    }
  ]
}

~~~
