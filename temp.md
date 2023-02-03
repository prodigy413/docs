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
~~~
