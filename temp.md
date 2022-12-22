~~~
### CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "alarm" {
  actions_enabled = var.actions_enabled

  alarm_name        = var.alarm_name
  alarm_description = var.alarm_description

  alarm_actions                         = var.alarm_actions
  ok_actions                            = var.ok_actions
  insufficient_data_actions             = var.insufficient_data_actions
  comparison_operator                   = var.comparison_operator
  evaluation_periods                    = var.evaluation_periods
  threshold                             = var.threshold
  datapoints_to_alarm                   = var.datapoints_to_alarm
  treat_missing_data                    = var.treat_missing_data
  evaluate_low_sample_count_percentiles = var.evaluate_low_sample_count_percentiles

  # metric_query利用時は使用不可
  metric_name        = var.metric_name
  namespace          = var.namespace
  period             = var.period
  statistic          = var.statistic
  extended_statistic = var.extended_statistic
  dimensions         = var.dimensions
  unit               = var.unit

  # metric_name関連設定を利用時は使用不可
  dynamic "metric_query" {
    for_each = var.metric_query
    content {
      id          = lookup(metric_query.value, "id")
      account_id  = lookup(metric_query.value, "account_id", null)
      label       = lookup(metric_query.value, "label", null)
      return_data = lookup(metric_query.value, "return_data", null)
      expression  = lookup(metric_query.value, "expression", null)

      dynamic "metric" {
        for_each = lookup(metric_query.value, "metric", [])
        content {
          metric_name = lookup(metric.value, "metric_name")
          namespace   = lookup(metric.value, "namespace")
          period      = lookup(metric.value, "period")
          stat        = lookup(metric.value, "stat")
          unit        = lookup(metric.value, "unit", null)
          dimensions  = lookup(metric.value, "dimensions", null)
        }
      }
    }
  }
  threshold_metric_id = var.threshold_metric_id

  tags = {
    Terraform = "managed"
    Name      = var.alarm_name
  }
}

output "cloudwatch_alarm_id" {
  value = aws_cloudwatch_metric_alarm.alarm.id
}

output "cloudwatch_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.alarm.arn
}















variable "actions_enabled" {
  description = "アラームを有効/無効"
  type        = bool
  default     = true
}

variable "alarm_name" {
  description = "アラーム名"
  type        = string
}

variable "alarm_description" {
  description = "アラーム説明"
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "アラーム発生時のアクション"
  type        = list(string)
  default     = null
}

variable "ok_actions" {
  description = "アラームから正常になったときのアクション"
  type        = list(string)
  default     = null
}

variable "insufficient_data_actions" {
  description = "ステータスがINSUFFICIENT_DATAになったときのアクション"
  type        = list(string)
  default     = null
}

variable "comparison_operator" {
  description = "StatisticとThresholdに利用する比較演算子"
  type        = string
}

variable "evaluation_periods" {
  description = "指定しきい値を確認する回数"
  type        = number
}

variable "threshold" {
  description = "監視するメトリクスのしきい値"
  type        = number
  default     = null
}

variable "unit" {
  description = "監視するメトリクスの単位"
  type        = string
  default     = null
}

variable "datapoints_to_alarm" {
  description = "アラームをトリガーするためのしきい値を超えた回数"
  type        = number
  default     = null
}

variable "treat_missing_data" {
  description = "メトリクスが取得できなかった場合のアクション"
  type        = string
  default     = "missing"
}

variable "evaluate_low_sample_count_percentiles" {
  description = "percentileベースアラームを利用時、データが少なかった場合のアクション"
  type        = string
  default     = null
}

variable "metric_name" {
  description = "監視するメトリクス名"
  type        = string
  default     = null
}

variable "namespace" {
  description = "監視するメトリクスのネームスペース"
  type        = string
  default     = null
}

variable "period" {
  description = "メトリクスを確認する頻度（秒）"
  type        = number
  default     = null
}

variable "statistic" {
  description = "メトリクスに適用される統計方法"
  type        = string
  default     = null
}

variable "extended_statistic" {
  description = "メトリクスに適用されるpercentile統計"
  type        = string
  default     = null
}

variable "dimensions" {
  description = "監視するメトリクスのディメンション"
  type        = any
  default     = null
}

variable "metric_query" {
  description = "metric math expressionを利用したアラーム設定"
  type        = any
  default     = []
}

variable "threshold_metric_id" {
  description = "anomaly detection modelベースアラームを利用時、ANOMALY_DETECTION_BANDのIDを設定する"
  type        = string
  default     = null
}














### Metrics Filter
resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = var.filter_name
  pattern        = var.filter_pattern
  log_group_name = var.filter_log_group_name

  metric_transformation {
    name          = var.metric_name
    namespace     = var.metric_namespace
    value         = var.metric_value
    default_value = var.metric_default_value
    dimensions    = var.metric_dimensions
    unit          = var.metric_unit
  }
}

output "metric_filter_id" {
  value = aws_cloudwatch_log_metric_filter.metric_filter.id
}

output "metric_filter_metric_name" {
  value = aws_cloudwatch_log_metric_filter.metric_filter.metric_transformation[0].name
}
















variable "filter_name" {
  description = "メトリクスフィルター名"
  type        = string
}

variable "filter_pattern" {
  description = "ログを抽出するフィルターパターン"
  type        = string
}

variable "filter_log_group_name" {
  description = "メトリクスフィルターを設定するロググループ名"
  type        = string
}

variable "metric_name" {
  description = "作成するメトリクス名"
  type        = string
}

variable "metric_namespace" {
  description = "メトリクス用ネームスペース名"
  type        = string
}

variable "metric_value" {
  description = "一致するログが見つかったとき、メトリクスに発行する値"
  type        = string
  default     = "1"
}

variable "metric_default_value" {
  description = "一致するログが見つからなかったとき、メトリクスフィルターに設定する値（metric_dimensionsと衝突）"
  type        = string
  default     = null
}

variable "metric_dimensions" {
  description = "メトリクス用ディメンション設定（metric_default_valueと衝突）"
  type        = map(string)
  default     = null
}

variable "metric_unit" {
  description = "メトリクスに設定する秒/個などの単位"
  type        = string
  default     = null
}

















### Lambda
##############################
# Lambda
##############################
resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  description   = var.description
  role          = var.role
  handler       = var.handler
  memory_size   = var.memory_size
  runtime       = var.runtime
  timeout       = var.timeout
  architectures = var.architectures
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids
  }

  dynamic "environment" {
    for_each = var.env_variables == null ? [] : [true]

    content {
      variables = var.env_variables
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Terraform = "managed"
    Name      = var.function_name
  }
}

resource "aws_lambda_permission" "lambda" {
  count = var.lambda_permission_principal != null ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = var.lambda_permission_principal
  source_arn    = var.lambda_permission_source_arn
}

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.retention_in_days
}

##############################
# Output
##############################
output "lambda_id" {
  value = aws_lambda_function.lambda.id
}

output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.lambda.function_name
}

output "cloudwatch_logs_id" {
  value = aws_cloudwatch_log_group.lambda.id
}

output "cloudwatch_logs_arn" {
  value = aws_cloudwatch_log_group.lambda.arn
}























##############################
# Lambda Function
##############################
variable "function_name" {
  description = "Lambda関数名"
  type        = string
}

variable "description" {
  description = "Lambda関数の説明"
  type        = string
  default     = null
}

variable "role" {
  description = "Lambda関数用ロール名"
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda関数のハンドラー名"
  type        = string
}

variable "memory_size" {
  description = "Lambda関数のメモリサイズ"
  type        = number
  default     = 128
}

variable "runtime" {
  description = "Lambda関数が利用するランタイム"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Lambda関数実行のタイムアウト（秒）"
  type        = number
  default     = 3
}

variable "architectures" {
  description = "Lambda関数が利用するアーキテクチャ"
  type        = list(string)
  default     = ["arm64"]
}

variable "s3_bucket" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
}

variable "s3_key" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
}

variable "ephemeral_storage_size" {
  description = "Lambda関数実行時のストレージサイズ(/tmp)"
  type        = number
  default     = 512
}

variable "vpc_subnet_ids" {
  description = "Lambda関数が利用するVPCのサブネットID."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Lambda関数が利用するVPCのセキュリティグループID."
  type        = list(string)
  default     = []
}

variable "env_variables" {
  description = "Lambda関数が利用する環境変数"
  type        = map(string)
  default     = null
}

##############################
# Lambda Permission
##############################
variable "lambda_permission_principal" {
  description = "Lambda関数にアクセス可能なサービス"
  type        = string
  default     = null
}

variable "lambda_permission_source_arn" {
  description = "Lambda関数にアクセス可能なサービスのArn"
  type        = string
  default     = null
}

##############################
# Cloudwatch Logs
##############################
variable "retention_in_days" {
  description = "Lambdaログの保存期間"
  type        = number
  default     = 90
}






















### SNS
##############################
# SNS Topic
##############################
resource "aws_sns_topic" "topic" {
  name        = var.topic_name
  name_prefix = var.topic_name_prefix

  display_name                             = var.display_name
  policy                                   = var.policy
  delivery_policy                          = var.delivery_policy
  application_success_feedback_role_arn    = var.application_success_feedback_role_arn
  application_success_feedback_sample_rate = var.application_success_feedback_sample_rate
  application_failure_feedback_role_arn    = var.application_failure_feedback_role_arn
  http_success_feedback_role_arn           = var.http_success_feedback_role_arn
  http_success_feedback_sample_rate        = var.http_success_feedback_sample_rate
  http_failure_feedback_role_arn           = var.http_failure_feedback_role_arn
  lambda_success_feedback_role_arn         = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate      = var.lambda_success_feedback_sample_rate
  lambda_failure_feedback_role_arn         = var.lambda_failure_feedback_role_arn
  sqs_success_feedback_role_arn            = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate         = var.sqs_success_feedback_sample_rate
  sqs_failure_feedback_role_arn            = var.sqs_failure_feedback_role_arn
  firehose_success_feedback_role_arn       = var.firehose_success_feedback_role_arn
  firehose_success_feedback_sample_rate    = var.firehose_success_feedback_sample_rate
  firehose_failure_feedback_role_arn       = var.firehose_failure_feedback_role_arn
  kms_master_key_id                        = var.kms_master_key_id
  fifo_topic                               = var.fifo_topic
  content_based_deduplication              = var.content_based_deduplication

  tags = {
    Terraform = "managed"
    Name      = var.topic_name
  }
}

##############################
# SNS Topic Policy
##############################
resource "aws_sns_topic_policy" "topic" {
  count = var.topic_policy != null ? 1 : 0

  arn    = aws_sns_topic.topic.arn
  policy = var.topic_policy
}

##############################
# SNS Topic Subscription
##############################
resource "aws_sns_topic_subscription" "topic" {
  for_each = var.subscription_parameter != null ? { for parameter in var.subscription_parameter : parameter.id => parameter } : {}

  topic_arn                       = aws_sns_topic.topic.arn
  protocol                        = each.value.protocol
  endpoint                        = each.value.endpoint
  subscription_role_arn           = lookup(each.value, "subscription_role_arn", null)
  confirmation_timeout_in_minutes = lookup(each.value, "confirmation_timeout_in_minutes", null)
  delivery_policy                 = lookup(each.value, "delivery_policy", null)
  endpoint_auto_confirms          = lookup(each.value, "endpoint_auto_confirms", null)
  filter_policy                   = lookup(each.value, "filter_policy", null)
  filter_policy_scope             = lookup(each.value, "filter_policy_scope", null)
  raw_message_delivery            = lookup(each.value, "raw_message_delivery", null)
  redrive_policy                  = lookup(each.value, "redrive_policy", null)

  depends_on = [aws_sns_topic.topic]
}

##############################
# Output
##############################
output "sns_topic_id" {
  value = aws_sns_topic.topic.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.topic.arn
}

output "sns_subscription_arn" {
  value = var.subscription_parameter != null ? tomap({ for k, v in aws_sns_topic_subscription.topic : k => v.arn }) : null
}



















##############################
# SNS Topic
##############################
variable "topic_name" {
  description = "SNS topic名（※topic_name_prefixと衝突）"
  type        = string
  default     = null
}

variable "topic_name_prefix" {
  description = "SNS topic名のプレフィックス（※topic_nameと衝突）"
  type        = string
  default     = null
}

variable "display_name" {
  description = "SNS topicのディスプレイ名"
  type        = string
  default     = null
}

variable "policy" {
  description = "JSON形式のTopic用ポリシー"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "SNS配信ポリシー"
  type        = string
  default     = null
}

variable "application_success_feedback_role_arn" {
  description = "アプリケーション配信成功フィードバック用ロール"
  type        = string
  default     = null
}

variable "application_success_feedback_sample_rate" {
  description = "アプリケーション配信成功をログ記録する比率"
  type        = string
  default     = null
}

variable "application_failure_feedback_role_arn" {
  description = "アプリケーション配信失敗フィードバック用ロール"
  type        = string
  default     = null
}

variable "http_success_feedback_role_arn" {
  description = "HTTP配信成功フィードバック用ロール"
  type        = string
  default     = null
}

variable "http_success_feedback_sample_rate" {
  description = "HTTP配信成功をログ記録する比率"
  type        = string
  default     = null
}

variable "http_failure_feedback_role_arn" {
  description = "HTTP配信失敗フィードバック用ロール"
  type        = string
  default     = null
}

variable "lambda_success_feedback_role_arn" {
  description = "Lambda配信成功フィードバック用ロール"
  type        = string
  default     = null
}

variable "lambda_success_feedback_sample_rate" {
  description = "Lambda配信成功をログ記録する比率"
  type        = string
  default     = null
}

variable "lambda_failure_feedback_role_arn" {
  description = "Lambda配信失敗フィードバック用ロール"
  type        = string
  default     = null
}

variable "sqs_success_feedback_role_arn" {
  description = "SQS配信成功フィードバック用ロール"
  type        = string
  default     = null
}

variable "sqs_success_feedback_sample_rate" {
  description = "SQS配信成功をログ記録する比率"
  type        = string
  default     = null
}

variable "sqs_failure_feedback_role_arn" {
  description = "SQS配信失敗フィードバック用ロール"
  type        = string
  default     = null
}

variable "firehose_success_feedback_role_arn" {
  description = "Firehose配信成功フィードバック用ロール"
  type        = string
  default     = null
}

variable "firehose_success_feedback_sample_rate" {
  description = "Firehose配信成功をログ記録する比率"
  type        = string
  default     = null
}

variable "firehose_failure_feedback_role_arn" {
  description = "Firehose配信失敗フィードバック用ロール"
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "SNS用KMSキーID"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "FIFO Topicを有効/無効"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "FIFO TopicのContent based deduplicationを有効/無効"
  type        = bool
  default     = false
}

##############################
# SNS Topic Policy
##############################
variable "topic_policy" {
  description = "JSON形式のTopic用ポリシーコンテンツ"
  type        = string
  default     = null
}

##############################
# SNS Topic Subscription
##############################
variable "subscription_parameter" {
  description = "サブスクリプション設定用パラメータ"
  type        = any
  default     = null
}

~~~
