~~~
resource "aws_cloudfront_origin_access_identity" "cloud_front_01" {
  comment = "great-obi-s3-01"
}

resource "aws_cloudfront_distribution" "cloud_front_01" {
  aliases             = [local.routing_domain]
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  wait_for_deployment = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "great-obi-s3-01"
    viewer_protocol_policy = "redirect-to-https"
    #    response_headers_policy_id = aws_cloudfront_response_headers_policy.policy_01.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    #    lambda_function_association {
    #      event_type = "viewer-response"
    #      lambda_arn = "arn:aws:lambda:us-east-1:844065555252:function:test-lambda-01:1"
    #
    #      #lambda_arn = data.aws_lambda_function.header_lambda.qualified_arn
    #      #lambda_arn = aws_lambda_function.test_lambda_01.lambda_function_qualified_arn
    #    }
    #function_association {
    #  event_type   = "viewer-response"
    #  function_arn = aws_cloudfront_function.cloudfront_header_01.arn
    #}
  }

  origin {
    domain_name = aws_s3_bucket.obi_s3_01.bucket_regional_domain_name
    origin_id   = "great-obi-s3-01"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloud_front_01.cloudfront_access_identity_path
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.alb_01_cert.arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}

#resource "aws_cloudfront_function" "cloudfront_header_01" {
#  name    = "cloudfront-header-01"
#  runtime = "cloudfront-js-1.0"
#  publish = true
#  code    = file("source/headers.js")
#}
#
#output "cloudfront_function_arn" {
#  value = aws_cloudfront_function.cloudfront_header_01.arn
#}
#

#resource "aws_cloudfront_response_headers_policy" "policy_01" {
#  name = "great-obi-cloudfront-policy-01"
#
#  security_headers_config {
#    frame_options {
#      frame_option = "DENY"
#      override     = true
#    }
#
#    content_type_options {
#      override = true
#    }
#  }
#
#  custom_headers_config {
#    items {
#      header   = "cache-control"
#      override = true
#      value    = "no-cache, no-store, must-revalidate"
#    }
#
#    items {
#      header   = "X-Robots-Tag"
#      override = true
#      value    = "noindex, nofollow"
#    }
#  }
#}
#

~~~
