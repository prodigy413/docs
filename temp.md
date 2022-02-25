~~~tf
data "aws_route53_zone" "main_domain" {
  name = local.origin_domain
}

resource "aws_route53_record" "domain_01" {
  name    = local.origin_domain
  zone_id = data.aws_route53_zone.main_domain.zone_id
  type    = "MX"
  ttl     = "3600"
  records = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ALT3.ASPMX.L.GOOGLE.COM.",
    "10 ALT4.ASPMX.L.GOOGLE.COM."
  ]
}
~~~
