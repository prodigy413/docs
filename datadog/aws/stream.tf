resource "aws_cloudwatch_metric_stream" "stream_01" {
  name          = "${local.product}-${local.env}-stream-01"
  role_arn      = aws_iam_role.stream_role_01.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.kinesis_01.arn
  output_format = "opentelemetry0.7"

  include_filter {
    namespace = "ECS/ContainerInsights"
  }

  include_filter {
    namespace = "CWAgent"
  }

  depends_on = [aws_kinesis_firehose_delivery_stream.kinesis_01]
}





