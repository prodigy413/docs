~~~
module "event" {
  source = "../modules"

  eventbus_name = var.eventbus_name_01

  event_rule_parameter = [
    {
      id          = 1
      name        = "EVENTRULE-mcid1t1t-LMD-SNS-evptrn001"
      description = "Rule for sending critical log events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["test.critical"]
        }
      )
    },
    {
      id          = 2
      name        = "EVENTRULE-mcid1t1t-LMD-SNS-evptrn002"
      description = "Rule for sending warning log events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["test.warning"]
        }
      )
    },
    {
      id          = 3
      name        = "EVENTRULE-mcid1t1t-LMD-SNS-evptrn003"
      description = "Rule for sending informational log events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["test.informational"]
        }
      )
    },
    {
      id          = 4
      name        = "EVENTRULE-mcid1t1t-HTL-SNS-evptrn001"
      description = "Rule for sending critical health events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["aws.health"]
        }
      )
    },
    {
      id          = 5
      name        = "EVENTRULE-mcid1t1t-HTL-SNS-evptrn002"
      description = "Rule for sending warning health events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["aws.health"]
        }
      )
    },
    {
      id          = 6
      name        = "EVENTRULE-mcid1t1t-HTL-SNS-evptrn003"
      description = "Rule for sending informational health events to SNS."
      event_pattern = jsonencode(
        {
          "source" : ["aws.health"]
        }
      )
    }
  ]

  event_target_parameter = [
    {
      id   = 1
      rule = module.event.event_rule_name[1]
      arn  = data.aws_sns_topic.sns01.arn
    },
    {
      id   = 2
      rule = module.event.event_rule_name[2]
      arn  = data.aws_sns_topic.sns02.arn
    },
    {
      id   = 3
      rule = module.event.event_rule_name[3]
      arn  = data.aws_sns_topic.sns03.arn
    },
    {
      id   = 4
      rule = module.event.event_rule_name[4]
      arn  = data.aws_sns_topic.sns04.arn
    },
    {
      id   = 5
      rule = module.event.event_rule_name[5]
      arn  = data.aws_sns_topic.sns05.arn
    },
    {
      id   = 6
      rule = module.event.event_rule_name[6]
      arn  = data.aws_sns_topic.sns06.arn
    }
  ]
}


























##############################
# Lambda
##############################
/*
module "lambda_01" {
  source = "../modules"

  function_name = var.function_name_lambda_01
  description   = var.description_lambda_01
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_01
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_01
  s3_key    = var.s3_key_lambda_01
  # env_variables = var.env_variables_lambda_01

  lambda_permission_principal  = var.lambda_permission_principal_lambda_01
  lambda_permission_source_arn = "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/lambda/obi-test-lambda-01"
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
*/

##############################
# Lambda: Subscription Filter JSON Log Event To EventBridge
##############################
module "lambda_logs_eventbridge01" {
  source = "../modules"

  function_name = var.function_name_lambda_logs_eventbridge01
  description   = var.description_lambda_logs_eventbridge01
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_logs_eventbridge01
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_logs_eventbridge01
  s3_key    = var.s3_key_lambda_logs_eventbridge01
  # env_variables = var.env_variables_lambda_02
}

output "lambda_logs_eventbridge01_id" {
  value = module.lambda_logs_eventbridge01.lambda_id
}

output "lambda_logs_eventbridge01_arn" {
  value = module.lambda_logs_eventbridge01.lambda_arn
}

output "lambda_logs_eventbridge01_name" {
  value = module.lambda_logs_eventbridge01.lambda_name
}

output "lambda_logs_eventbridge01_cloudwatch_logs_id" {
  value = module.lambda_logs_eventbridge01.cloudwatch_logs_id
}

output "lambda_logs_eventbridge01_cloudwatch_logs_arn" {
  value = module.lambda_logs_eventbridge01.cloudwatch_logs_arn
}

##############################
# Lambda: Subscription Filter NON-JSON Log Event To EventBridge
##############################
module "lambda_logs_eventbridge02" {
  source = "../modules"

  function_name = var.function_name_lambda_logs_eventbridge02
  description   = var.description_lambda_logs_eventbridge02
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_logs_eventbridge02
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_logs_eventbridge02
  s3_key    = var.s3_key_lambda_logs_eventbridge02
  # env_variables = var.env_variables_lambda_02
}

output "lambda_logs_eventbridge02_id" {
  value = module.lambda_logs_eventbridge02.lambda_id
}

output "lambda_logs_eventbridge02_arn" {
  value = module.lambda_logs_eventbridge02.lambda_arn
}

output "lambda_logs_eventbridge02_name" {
  value = module.lambda_logs_eventbridge02.lambda_name
}

output "lambda_logs_eventbridge02_cloudwatch_logs_id" {
  value = module.lambda_logs_eventbridge02.cloudwatch_logs_id
}

output "lambda_logs_eventbridge02_cloudwatch_logs_arn" {
  value = module.lambda_logs_eventbridge02.cloudwatch_logs_arn
}

##############################
# Lambda: SNS(Log Events) To Slack
##############################
module "lambda_logs_slack01" {
  source = "../modules"

  function_name = var.function_name_lambda_logs_slack01
  description   = var.description_lambda_logs_slack01
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_logs_slack01
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_logs_slack01
  s3_key    = var.s3_key_lambda_logs_slack01
  # env_variables = var.env_variables_lambda_02
}

output "lambda_logs_slack01_id" {
  value = module.lambda_logs_slack01.lambda_id
}

output "lambda_logs_slack01_arn" {
  value = module.lambda_logs_slack01.lambda_arn
}

output "lambda_logs_slack01_name" {
  value = module.lambda_logs_slack01.lambda_name
}

output "lambda_logs_slack01_cloudwatch_logs_id" {
  value = module.lambda_logs_slack01.cloudwatch_logs_id
}

output "lambda_logs_slack01_cloudwatch_logs_arn" {
  value = module.lambda_logs_slack01.cloudwatch_logs_arn
}

##############################
# Lambda: SNS(Log Events) To Redmine
##############################
module "lambda_logs_redmine01" {
  source = "../modules"

  function_name = var.function_name_lambda_logs_redmine01
  description   = var.description_lambda_logs_redmine01
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_logs_redmine01
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_logs_redmine01
  s3_key    = var.s3_key_lambda_logs_redmine01
  # env_variables = var.env_variables_lambda_02
}

output "lambda_logs_redmine01_id" {
  value = module.lambda_logs_redmine01.lambda_id
}

output "lambda_logs_redmine01_arn" {
  value = module.lambda_logs_redmine01.lambda_arn
}

output "lambda_logs_redmine01_name" {
  value = module.lambda_logs_redmine01.lambda_name
}

output "lambda_logs_redmine01_cloudwatch_logs_id" {
  value = module.lambda_logs_redmine01.cloudwatch_logs_id
}

output "lambda_logs_redmine01_cloudwatch_logs_arn" {
  value = module.lambda_logs_redmine01.cloudwatch_logs_arn
}

##############################
# Lambda: SNS(Health Events) To Redmine
##############################
module "lambda_health_redmine01" {
  source = "../modules"

  function_name = var.function_name_lambda_health_redmine01
  description   = var.description_lambda_health_redmine01
  role          = aws_iam_role.lambda.arn
  handler       = var.handler_lambda_health_redmine01
  #vpc_security_group_ids = ["sg-a31165e0"]
  #vpc_subnet_ids         = ["subnet-9bb002d3", "subnet-b9e905e3", "subnet-c042c7eb"]
  s3_bucket = var.s3_bucket_lambda_health_redmine01
  s3_key    = var.s3_key_lambda_health_redmine01
  # env_variables = var.env_variables_lambda_02
}

output "lambda_health_redmine01_id" {
  value = module.lambda_health_redmine01.lambda_id
}

output "lambda_health_redmine01_arn" {
  value = module.lambda_health_redmine01.lambda_arn
}

output "lambda_health_redmine01_name" {
  value = module.lambda_health_redmine01.lambda_name
}

output "lambda_health_redmine01_cloudwatch_logs_id" {
  value = module.lambda_health_redmine01.cloudwatch_logs_id
}

output "lambda_health_redmine01_cloudwatch_logs_arn" {
  value = module.lambda_health_redmine01.cloudwatch_logs_arn
}























##############################
# Lambda Function (Metrics To Redmine)
##############################
/*
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
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}
*/
#variable "env_variables_lambda_01" {
#  description = "Lambda関数が利用する環境変数"
#  type        = map(string)
#  default     = null
#}

##############################
# Lambda: Subscription Filter JSON Log Event To EventBridge
##############################
variable "function_name_lambda_logs_eventbridge01" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-logs_to_eventbridge001"
}

variable "description_lambda_logs_eventbridge01" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda for forwarding log events(json format) to eventbridge."
}

variable "handler_lambda_logs_eventbridge01" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_logs_eventbridge01" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_logs_eventbridge01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}

##############################
# Lambda: Subscription Filter NON-JSON Log Event To EventBridge
##############################
variable "function_name_lambda_logs_eventbridge02" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-logs_to_eventbridge002"
}

variable "description_lambda_logs_eventbridge02" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda for forwarding log events(non-json format) to eventbridge."
}

variable "handler_lambda_logs_eventbridge02" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_logs_eventbridge02" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_logs_eventbridge02" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}

##############################
# Lambda: SNS(Log Events) To Slack
##############################
variable "function_name_lambda_logs_slack01" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-logs_to_slack001"
}

variable "description_lambda_logs_slack01" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda to notify slack of log events."
}

variable "handler_lambda_logs_slack01" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_logs_slack01" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_logs_slack01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}

##############################
# Lambda: SNS(Log Events) To Redmine
##############################
variable "function_name_lambda_logs_redmine01" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-logs_to_redmine001"
}

variable "description_lambda_logs_redmine01" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda to notify redmine of log events."
}

variable "handler_lambda_logs_redmine01" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_logs_redmine01" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_logs_redmine01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}

##############################
# Lambda: SNS(Health Events) To Redmine
##############################
variable "function_name_lambda_health_redmine01" {
  description = "Lambda関数名"
  type        = string
  default     = "LMD-mcid1t1t-health_to_redmine001"
}

variable "description_lambda_health_redmine01" {
  description = "Lambda関数の説明"
  type        = string
  default     = "Lambda to notify redmine of log events."
}

variable "handler_lambda_health_redmine01" {
  description = "Lambda関数のハンドラー名"
  type        = string
  default     = "code.lambda_handler"
}

variable "s3_bucket_lambda_health_redmine01" {
  description = "アーティファクトを保存するS3バケット名"
  type        = string
  default     = "obi-test-tfstate"
}

variable "s3_key_lambda_health_redmine01" {
  description = "アーティファクトを保存するS3バケットのキー名"
  type        = string
  default     = "codes/code.zip"
}



























/*
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
module "sns_logs_crit_01" {
  source = "../modules"

  topic_name = var.topic_name_04
  # subscription_parameter = var.subscription_parameter_04
}

output "sns_logs_crit_01_id" {
  value = module.sns_logs_crit_01.sns_topic_id
}

output "sns_logs_crit_01_arn" {
  value = module.sns_logs_crit_01.sns_topic_arn
}

output "sns_logs_crit_01_subscription_04_arn" {
  value = module.sns_logs_crit_01.sns_subscription_arn
}

##############################
# SNS Topic (INFO Alarm To ChatBot)
##############################
module "sns_logs_warn_01" {
  source = "../modules"

  topic_name = var.topic_name_05
  # subscription_parameter = var.subscription_parameter_05
}

output "sns_logs_warn_01_id" {
  value = module.sns_logs_warn_01.sns_topic_id
}

output "sns_logs_warn_01_arn" {
  value = module.sns_logs_warn_01.sns_topic_arn
}

output "sns_logs_warn_01_subscription_05_arn" {
  value = module.sns_logs_warn_01.sns_subscription_arn
}
*/

##############################
# SNS Policy Document (EventRule > SNS)
##############################
data "aws_iam_policy_document" "sns_policy_eventbridge_sns" {
  statement {
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

##############################
# SNS04: CRITICAL Log Events To Email/Lambda
##############################
module "sns_logs_crit_01" {
  source = "../modules"

  topic_name = var.topic_name_logs_crit_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
  subscription_parameter = [
    {
      id       = 1
      protocol = "email"
      endpoint = "xxxxxxxx@xxxxxxxx.xxx"
    },
    {
      id       = 2
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda03.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    },
    {
      id       = 3
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda04.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    }
  ]
}

output "sns_logs_crit_01_id" {
  value = module.sns_logs_crit_01.sns_topic_id
}

output "sns_logs_crit_01_arn" {
  value = module.sns_logs_crit_01.sns_topic_arn
}

output "sns_logs_crit_01_subscription_01_arn" {
  value = module.sns_logs_crit_01.sns_subscription_arn[1]
}

output "sns_logs_crit_01_subscription_02_arn" {
  value = module.sns_logs_crit_01.sns_subscription_arn[2]
}

output "sns_logs_crit_01_subscription_03_arn" {
  value = module.sns_logs_crit_01.sns_subscription_arn[3]
}

##############################
# SNS05: WARNING Log Events To Lambda
##############################
module "sns_logs_warn_01" {
  source = "../modules"

  topic_name = var.topic_name_logs_warn_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
  subscription_parameter = [
    {
      id       = 1
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda03.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    },
    {
      id       = 2
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda04.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    }
  ]
}

output "sns_logs_warn_01_id" {
  value = module.sns_logs_warn_01.sns_topic_id
}

output "sns_logs_warn_01_arn" {
  value = module.sns_logs_warn_01.sns_topic_arn
}

output "sns_logs_warn_01_subscription_01_arn" {
  value = module.sns_logs_warn_01.sns_subscription_arn[1]
}

output "sns_logs_warn_01_subscription_02_arn" {
  value = module.sns_logs_warn_01.sns_subscription_arn[2]
}

##############################
# SNS06: INFO Log Events To Lambda
##############################
module "sns_logs_info_01" {
  source = "../modules"

  topic_name = var.topic_name_logs_info_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
  subscription_parameter = [
    {
      id       = 1
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda03.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    }
  ]
}

output "sns_logs_info_01_id" {
  value = module.sns_logs_info_01.sns_topic_id
}

output "sns_logs_info_01_arn" {
  value = module.sns_logs_info_01.sns_topic_arn
}

output "sns_logs_info_01_subscription_01_arn" {
  value = module.sns_logs_info_01.sns_subscription_arn[1]
}

##############################
# SNS07: CRITICAL Health Events To Email/Lambda/Chatbot
##############################
module "sns_health_crit_01" {
  source = "../modules"

  topic_name = var.topic_name_health_crit_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
  subscription_parameter = [
    {
      id       = 1
      protocol = "email"
      endpoint = "xxxxxx@xxxx.xxx"
    },
    {
      id       = 2
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda05.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    }
  ]
}

output "sns_health_crit_01_id" {
  value = module.sns_health_crit_01.sns_topic_id
}

output "sns_health_crit_01_arn" {
  value = module.sns_health_crit_01.sns_topic_arn
}

output "sns_health_crit_01_subscription_01_arn" {
  value = module.sns_health_crit_01.sns_subscription_arn[1]
}

output "sns_health_crit_01_subscription_02_arn" {
  value = module.sns_health_crit_01.sns_subscription_arn[2]
}

##############################
# SNS08: WARNING Health Events To Lambda/Chatbot
##############################
module "sns_health_warn_01" {
  source = "../modules"

  topic_name = var.topic_name_health_warn_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
  subscription_parameter = [
    {
      id       = 1
      protocol = "lambda"
      endpoint = data.aws_lambda_function.lambda05.arn
      #endpoint = data.terraform_remote_state.lambda.outputs.lambda_logs_to_redmine_01_arn
    }
  ]
}

output "sns_health_warn_01_id" {
  value = module.sns_health_warn_01.sns_topic_id
}

output "sns_health_warn_01_arn" {
  value = module.sns_health_warn_01.sns_topic_arn
}

output "sns_health_warn_01_subscription_01_arn" {
  value = module.sns_health_warn_01.sns_subscription_arn[1]
}

##############################
# SNS09: INFO Health Events To Chatbot
##############################
module "sns_health_info_01" {
  source = "../modules"

  topic_name = var.topic_name_health_info_01
  policy     = data.aws_iam_policy_document.sns_policy_eventbridge_sns.json
}

output "sns_health_info_01_id" {
  value = module.sns_health_info_01.sns_topic_id
}

output "sns_health_info_01_arn" {
  value = module.sns_health_info_01.sns_topic_arn
}





















/*
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
*/

##############################
# SNS04: CRITICAL Log Events To Email/Lambda
##############################
variable "topic_name_logs_crit_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-logs-CRIT"
}

##############################
# SNS05: WARNING Log Events To Lambda
##############################
variable "topic_name_logs_warn_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-logs-WARN"
}

##############################
# SNS06: INFO Log Events To Lambda
##############################
variable "topic_name_logs_info_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-logs-INFO"
}

##############################
# SNS07: CRITICAL Health Events To Email/Lambda/Chatbot
##############################
variable "topic_name_health_crit_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-health-CRIT"
}

##############################
# SNS08: WARNING Health Events To Lambda/Chatbot
##############################
variable "topic_name_health_warn_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-health-WARN"
}

##############################
# SNS09: INFO Health Events To Chatbot
##############################
variable "topic_name_health_info_01" {
  description = "SNS topic名"
  type        = string
  default     = "SNS-mcid1t1t-health-INFO"
}

~~~
