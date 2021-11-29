resource "aws_acm_certificate" "alb_01_cert" {
  provider          = aws.east
  domain_name       = local.routing_domain
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "alb_01_cert" {
  provider                = aws.east
  certificate_arn         = aws_acm_certificate.alb_01_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_record_01 : record.fqdn]
}
