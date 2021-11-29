resource "aws_route53_record" "domain_01" {
  name    = local.routing_domain
  zone_id = data.aws_route53_zone.main_domain.zone_id
  type    = "A"

#  weighted_routing_policy {
#    weight = 50
#  }
#
#  set_identifier = "blue"

  alias {
    name                   = aws_cloudfront_distribution.cloud_front_01.domain_name
    zone_id                = aws_cloudfront_distribution.cloud_front_01.hosted_zone_id
    evaluate_target_health = true
  }

}

#resource "aws_route53_record" "domain_02" {
#  name    = local.routing_domain
#  zone_id = data.aws_route53_zone.main_domain.zone_id
#  type    = "A"
#
##  weighted_routing_policy {
##    weight = 50
##  }
##
##  set_identifier = "green"
#
#  alias {
#    name                   = aws_cloudfront_distribution.cloud_front_02.domain_name
#    zone_id                = aws_cloudfront_distribution.cloud_front_02.hosted_zone_id
#    evaluate_target_health = true
#  }
#
#}

resource "aws_route53_record" "cert_record_01" {
  for_each = {
    for dvo in aws_acm_certificate.alb_01_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 700
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main_domain.zone_id
}

resource "aws_route53_record" "associate_alias_01" {
  name    = "_${local.routing_domain}"
  zone_id = data.aws_route53_zone.main_domain.zone_id
  type = "TXT"
  ttl = "10"
  records = [aws_cloudfront_distribution.cloud_front_02.domain_name]
}

#resource "aws_route53_record" "domain_01" {
#  name    = local.routing_domain
#  zone_id = data.aws_route53_zone.main_domain.zone_id
#  type    = "A"
#
#  alias {
#    name                   = aws_cloudfront_distribution.cloud_front_01.domain_name
#    zone_id                = aws_cloudfront_distribution.cloud_front_01.hosted_zone_id
#    evaluate_target_health = true
#  }
#
#}
#
#resource "aws_route53_record" "domain_02" {
#  name    = local.routing_domain_02
#  zone_id = data.aws_route53_zone.main_domain.zone_id
#  type    = "TXT"
#  ttl     = 700
#
#  records = [aws_cloudfront_distribution.cloud_front_01.domain_name]
#  #records = [aws_cloudfront_distribution.cloud_front_02.domain_name]
#
#}
#
#resource "aws_route53_record" "cert_record_01" {
#  for_each = {
#    for dvo in aws_acm_certificate.alb_01_cert.domain_validation_options : dvo.domain_name => {
#      name   = dvo.resource_record_name
#      type   = dvo.resource_record_type
#      record = dvo.resource_record_value
#    }
#  }
#
#  allow_overwrite = true
#  name            = each.value.name
#  records         = [each.value.record]
#  ttl             = 700
#  type            = each.value.type
#  zone_id         = data.aws_route53_zone.main_domain.zone_id
#}
#