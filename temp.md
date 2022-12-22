~~~
##############################
# ALARM: EC2 Process / CRITICAL (work01)
##############################
variable "alarm_name_02" {
  description = "アラーム名"
  type        = string
  default     = "ALARM-mcid1t1t-EC2-work01-procstat-lookup-pid-count-sshd-CRIT"
}

variable "alarm_description_02" {
  description = "アラーム説明"
  type        = string
  default     = "Configuration to trigger critical alarms from EC2 process metrics."
}

variable "comparison_operator_02" {
  description = "StatisticとThresholdに利用する比較演算子"
  type        = string
  default     = "LessThanThreshold"
}

variable "evaluation_periods_02" {
  description = "指定しきい値を確認する回数"
  type        = number
  default     = 1
}

variable "threshold_02" {
  description = "監視するメトリクスのしきい値"
  type        = number
  default     = 1
}

variable "datapoints_to_alarm_02" {
  description = "アラームをトリガーするためのしきい値を超えた回数"
  type        = number
  default     = 1
}

variable "metric_name_02" {
  description = "監視するメトリクス名"
  type        = string
  default     = "procstat_lookup_pid_count"
}

variable "namespace_02" {
  description = "監視するメトリクスのネームスペース"
  type        = string
  default     = "CWAgent"
}

variable "period_02" {
  description = "メトリクスを確認する頻度（秒）"
  type        = number
  default     = 60
}

variable "statistic_02" {
  description = "メトリクスに適用される統計方法"
  type        = string
  default     = "Average"
}

variable "dimensions_02" {
  description = "監視するメトリクスのディメンション"
  type        = any
  default = {
    AutoScalingGroupName = "obi-auto-scaling-group"
    exe                  = "amazon-ssm-agent"
    pid_finder           = "native"
  }
}






















##############################
# ALARM: EC2 Process / CRITICAL (work01)
##############################
module "alarm_02" {
  source = "../modules"

  alarm_name          = var.alarm_name_02
  alarm_description   = var.alarm_description_02
  comparison_operator = var.comparison_operator_02
  evaluation_periods  = var.evaluation_periods_02
  datapoints_to_alarm = var.datapoints_to_alarm_02
  threshold           = var.threshold_02
  dimensions          = var.dimensions_02
  #alarm_actions = [
  #  data.aws_sns_topic.sns_02.arn,
  #  data.aws_sns_topic.sns_02.arn,
  #  data.aws_sns_topic.sns_03.arn
  #]

  metric_name = var.metric_name_02
  namespace   = var.namespace_02
  period      = var.period_02
  statistic   = var.statistic_02
}

output "alarm_02_id" {
  value = module.alarm_02.cloudwatch_alarm_id
}

output "alarm_02_arn" {
  value = module.alarm_02.cloudwatch_alarm_arn
}
~~~
