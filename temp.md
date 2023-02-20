~~~
resource "aws_lambda_permission" "lambda_04" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_02.function_name
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:*"

  depends_on = [
    aws_lambda_function.lambda_01,
    aws_lambda_function.lambda_02,
    aws_lambda_function.lambda_03,
    aws_lambda_function.lambda_04,
    aws_lambda_function.lambda_05
  ]
}
~~~
