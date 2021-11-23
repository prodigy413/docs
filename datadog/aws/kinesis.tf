resource "aws_kinesis_firehose_delivery_stream" "kinesis_01" {
  name        = "${local.product}-${local.env}-kinesis-01"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://awsmetrics-intake.datadoghq.com/v1/input"
    name               = "Datadog Metrics"
    access_key         = local.datadog_api_key
    buffering_size     = 4
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_role_01.arn
    s3_backup_mode     = "FailedDataOnly"
    request_configuration {
      content_encoding = "GZIP"
    }
  }

  s3_configuration {
    role_arn           = aws_iam_role.firehose_role_01.arn
    bucket_arn         = aws_s3_bucket.s3_01.arn
    buffer_size        = 4
    buffer_interval    = 60
    compression_format = "GZIP"
  }
}
