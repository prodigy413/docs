~~~
##############################
# IAM Role
##############################
resource "aws_iam_role" "lambda_01" {
  name               = "obi-test-lambda-role-01"
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

resource "aws_iam_role_policy" "lambda_01" {
  name   = "obi-test-lambda-policy-01"
  role   = aws_iam_role.lambda_01.id
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

##############################
# Zip source file 
##############################
data "archive_file" "lambda_01" {
  type        = "zip"
  source_file = "upload_code/code/code.py"
  output_path = "upload_code/zip/code.zip"
}

data "archive_file" "lambda_02" {
  type        = "zip"
  source_file = "upload_code/code/crit.py"
  output_path = "upload_code/zip/crit.zip"
}

data "archive_file" "lambda_03" {
  type        = "zip"
  source_file = "upload_code/code/warn.py"
  output_path = "upload_code/zip/warn.zip"
}

data "archive_file" "lambda_04" {
  type        = "zip"
  source_file = "upload_code/code/info.py"
  output_path = "upload_code/zip/info.zip"
}

##############################
# Lambda
##############################
resource "aws_lambda_function" "lambda_01" {
  filename         = data.archive_file.lambda_01.output_path
  function_name    = "obi-test-lambda-01"
  role             = aws_iam_role.lambda_01.arn
  handler          = "code.lambda_handler"
  source_code_hash = data.archive_file.lambda_01.output_base64sha256
  runtime          = "python3.9"

  depends_on = [
    aws_cloudwatch_log_group.lambda_01,
    aws_iam_role.lambda_01
  ]
}

resource "aws_lambda_function" "lambda_02" {
  filename         = data.archive_file.lambda_02.output_path
  function_name    = "obi-test-lambda-crit"
  role             = aws_iam_role.lambda_01.arn
  handler          = "crit.lambda_handler"
  source_code_hash = data.archive_file.lambda_02.output_base64sha256
  runtime          = "python3.9"

  depends_on = [
    aws_cloudwatch_log_group.lambda_02,
    aws_iam_role.lambda_01
  ]
}

resource "aws_lambda_permission" "lambda_02" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_02.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topic_01.arn

  depends_on = [aws_lambda_function.lambda_02]
}

resource "aws_lambda_function" "lambda_03" {
  filename         = data.archive_file.lambda_03.output_path
  function_name    = "obi-test-lambda-warn"
  role             = aws_iam_role.lambda_01.arn
  handler          = "warn.lambda_handler"
  source_code_hash = data.archive_file.lambda_03.output_base64sha256
  runtime          = "python3.9"

  depends_on = [
    aws_cloudwatch_log_group.lambda_03,
    aws_iam_role.lambda_01
  ]
}

resource "aws_lambda_permission" "lambda_03" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_03.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topic_01.arn

  depends_on = [aws_lambda_function.lambda_03]
}

resource "aws_lambda_function" "lambda_04" {
  filename         = data.archive_file.lambda_04.output_path
  function_name    = "obi-test-lambda-info"
  role             = aws_iam_role.lambda_01.arn
  handler          = "info.lambda_handler"
  source_code_hash = data.archive_file.lambda_04.output_base64sha256
  runtime          = "python3.9"

  depends_on = [
    aws_cloudwatch_log_group.lambda_04,
    aws_iam_role.lambda_01
  ]
}

resource "aws_lambda_permission" "lambda_04" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_04.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topic_01.arn

  depends_on = [aws_lambda_function.lambda_04]
}

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "lambda_01" {
  name              = "/aws/lambda/obi-test-lambda-01"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_02" {
  name              = "/aws/lambda/obi-test-lambda-crit"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_03" {
  name              = "/aws/lambda/obi-test-lambda-warn"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_04" {
  name              = "/aws/lambda/obi-test-lambda-info"
  retention_in_days = 7
}

##############################
# Metric Filter
##############################
resource "aws_cloudwatch_log_metric_filter" "metric_filter_01" {
  name           = "FLTM-mcid1t1t-log-group-01-CRIT"
  pattern        = "ERROR"
  log_group_name = "/aws/lambda/obi-test-lambda-01"

  metric_transformation {
    name      = "FLTM-mcid1t1t-log-group-01-CRIT"
    namespace = "TestNS"
    value     = 1
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_01]
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_02" {
  name           = "FLTM-mcid1t1t-log-group-01-WARN"
  pattern        = "WARN"
  log_group_name = "/aws/lambda/obi-test-lambda-01"

  metric_transformation {
    name      = "FLTM-mcid1t1t-log-group-01-WARN"
    namespace = "TestNS"
    value     = 1
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_01]
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter_03" {
  name           = "FLTM-mcid1t1t-log-group-01-INFO"
  pattern        = "INFO"
  log_group_name = "/aws/lambda/obi-test-lambda-01"

  metric_transformation {
    name      = "FLTM-mcid1t1t-log-group-01-INFO"
    namespace = "TestNS"
    value     = 1
    unit      = "Count"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_01]
}

##############################
# Alarm
##############################
resource "aws_cloudwatch_metric_alarm" "alarm_01" {
  actions_enabled = true

  alarm_name          = "ALARM-mcid1t1t-FLTM-error-CRIT"
  alarm_actions       = [aws_sns_topic.topic_01.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  datapoints_to_alarm = 1
  metric_name         = "FLTM-mcid1t1t-log-group-01-CRIT"
  namespace           = "TestNS"
  period              = 60
  statistic           = "Average"

  depends_on = [aws_sns_topic.topic_01]
}

resource "aws_cloudwatch_metric_alarm" "alarm_02" {
  actions_enabled = true

  alarm_name          = "ALARM-mcid1t1t-FLTM-error-WARN"
  alarm_actions       = [aws_sns_topic.topic_01.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  datapoints_to_alarm = 1
  metric_name         = "FLTM-mcid1t1t-log-group-01-WARN"
  namespace           = "TestNS"
  period              = 60
  statistic           = "Average"

  depends_on = [aws_sns_topic.topic_01]
}

resource "aws_cloudwatch_metric_alarm" "alarm_03" {
  actions_enabled = true

  alarm_name          = "ALARM-mcid1t1t-FLTM-error-INFO"
  alarm_actions       = [aws_sns_topic.topic_01.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  datapoints_to_alarm = 1
  metric_name         = "FLTM-mcid1t1t-log-group-01-INFO"
  namespace           = "TestNS"
  period              = 60
  statistic           = "Average"

  depends_on = [aws_sns_topic.topic_01]
}

##############################
# SNS Topic
##############################
resource "aws_sns_topic" "topic_01" {
  name = "sns-for-notification"
}

##############################
# SNS Topic Subscription
##############################
resource "aws_sns_topic_subscription" "sub_01" {
  topic_arn           = aws_sns_topic.topic_01.arn
  protocol            = "lambda"
  endpoint            = aws_lambda_function.lambda_02.arn
  filter_policy_scope = "MessageBody"
  #filter_policy       = jsonencode({ "AlarmName" : [{ "anything-but" : ["ALARM-mcid1t1t-FLTM-error-WARN", "ALARM-mcid1t1t-FLTM-error-INFO"] }] })
  filter_policy = jsonencode({ "AlarmName" : [{ "anything-but" : ["WARN", "INFO"] }] })

  depends_on = [aws_lambda_function.lambda_02]
}

resource "aws_sns_topic_subscription" "sub_02" {
  topic_arn           = aws_sns_topic.topic_01.arn
  protocol            = "lambda"
  endpoint            = aws_lambda_function.lambda_03.arn
  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode(
    {
      "AlarmName" : [
        "ALARM-mcid1t1t-FLTM-error-WARN"
      ]
    }
  )

  depends_on = [aws_lambda_function.lambda_03]
}

resource "aws_sns_topic_subscription" "sub_03" {
  topic_arn           = aws_sns_topic.topic_01.arn
  protocol            = "lambda"
  endpoint            = aws_lambda_function.lambda_04.arn
  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode(
    {
      "AlarmName" : [
        "ALARM-mcid1t1t-FLTM-error-INFO"
      ]
    }
  )

  depends_on = [aws_lambda_function.lambda_04]
}

~~~
