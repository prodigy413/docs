~~~
data "aws_lambda_layer_version" "aws_managed_layer_01" {
  layer_name = "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension-Arm64"
  version    = 2
}

  layers = [
    aws_lambda_layer_version.lambda_01.arn,
    data.aws_lambda_layer_version.aws_managed_layer_01.arn
  ]
~~~
