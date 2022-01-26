~~~
resource "aws_cloudwatch_log_group" "os_log_01" {
  name              = "/aws/OpenSearchService/domains/${local.product_name}-es-${local.environment}-01/application-logs"
  retention_in_days = 7
}
~~~
