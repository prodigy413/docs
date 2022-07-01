~~~
variable "vpc_flow_logs_name" {
  description = "xxxx"
  type        = string
}

variable "iam_role_arn" {
  description = "xxxx"
  type        = string
}

variable "traffic_type" {
  description = "xxxx"
  type        = string
}

variable "max_aggregation_interval" {
  description = "xxxx"
  type        = number
}

variable "cloudwatch_logs_name" {
  description = "xxxx"
  type        = string
}

variable "retention_in_days" {
  description = "xxxx"
  type        = number
}













resource "aws_flow_log" "flow" {
  vpc_id                   = "vpc-0aad9b2ba7d3acd74"
  iam_role_arn             = var.iam_role_arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow.arn
  traffic_type             = var.traffic_type
  max_aggregation_interval = var.max_aggregation_interval
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = var.cloudwatch_logs_name
  retention_in_days = var.retention_in_days
}











variable "vpc_flow_logs_name" {
  description = "xxxx"
  type        = string
  default     = "test"
}

variable "iam_role_arn" {
  description = "xxxx"
  type        = string
  default     = "sdsdddd"
}

variable "traffic_type" {
  description = "xxxx"
  type        = string
  default     = "REJECT"
}

variable "max_aggregation_interval" {
  description = "xxxx"
  type        = number
  default     = 600
}

variable "cloudwatch_logs_name" {
  description = "xxxx"
  type        = string
  default     = "test"
}

variable "retention_in_days" {
  description = "xxxx"
  type        = number
  default     = 7
}











module "vpc_flow_logs" {
  source                   = "../modules"
  vpc_flow_logs_name       = var.vpc_flow_logs_name
  iam_role_arn             = var.iam_role_arn
  traffic_type             = var.traffic_type
  max_aggregation_interval = var.max_aggregation_interval
  cloudwatch_logs_name     = var.cloudwatch_logs_name
  retention_in_days        = var.retention_in_days
}


~~~
