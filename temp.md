https://github.com/JamesWoolfenden/terraform-aws-cloudfront/blob/master/aws_cloudfront_response_headers_policy.example.tf

~~~
module "test" {
  source = "../modules"

  response_headers_policy_parameter = [
    {
      id          = 1
      policy_name = "test-policy-01"
      security_headers_config = {
        content_security_policy = {
          content_security_policy = "default-src 'none'"
          override                = true
        }
        content_type_options = {
          override = true
        }
        frame_options = {
          frame_option = "SAMEORIGIN"
          override     = true
        }
        referrer_policy = {
          referrer_policy = "no-referrer"
          override        = true
        }
        strict_transport_security = {
          access_control_max_age_sec = 31536000
          include_subdomains         = true
          override                   = true
          preload                    = true
        }
        xss_protection = {
          mode_block = true
          override   = true
          protection = true
        }
      }
      custom_headers_config = {
        items = [
          {
            header   = "cache-control"
            override = true
            value    = "no-cache, no-store, must-revalidate"
          },
          {
            header   = "X-Robots-Tag"
            override = true
            value    = "noindex, nofollow"
          }
        ]
      }
    }
  ]
}

output "test_id" {
  value = module.test.test[1]
}































resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = var.response_headers_policy_parameter != null ? { for param in var.response_headers_policy_parameter : param.id => param } : {}
  name     = each.value.policy_name

  dynamic "security_headers_config" {
    for_each = try(flatten([each.value.security_headers_config]), [])
    iterator = shc

    content {
      dynamic "content_security_policy" {
        for_each = try(flatten([shc.value.content_security_policy]), [])
        iterator = csp

        content {
          content_security_policy = csp.value.content_security_policy
          override                = csp.value.override
        }
      }

      dynamic "content_type_options" {
        for_each = try(flatten([shc.value.content_type_options]), [])

        content {
          override = content_type_options.value.override
        }
      }

      dynamic "frame_options" {
        for_each = try(flatten([shc.value.frame_options]), [])
        iterator = fo

        content {
          frame_option = fo.value.frame_option
          override     = fo.value.override
        }
      }

      dynamic "referrer_policy" {
        for_each = try(flatten([shc.value.referrer_policy]), [])
        iterator = rp

        content {
          referrer_policy = rp.value.referrer_policy
          override        = rp.value.override
        }
      }

      dynamic "strict_transport_security" {
        for_each = try(flatten([shc.value.strict_transport_security]), [])
        iterator = sts

        content {
          access_control_max_age_sec = sts.value.access_control_max_age_sec
          include_subdomains         = sts.value.include_subdomains
          override                   = sts.value.override
          preload                    = sts.value.preload
        }
      }

      dynamic "xss_protection" {
        for_each = try(flatten([shc.value.xss_protection]), [])
        iterator = xp

        content {
          mode_block = xp.value.mode_block
          override   = xp.value.override
          protection = xp.value.protection
        }
      }
    }
  }

  dynamic "custom_headers_config" {
    for_each = try(flatten([each.value.custom_headers_config]), [])
    iterator = chc

    content {
      dynamic "items" {
        for_each = chc.value.items

        content {
          header   = items.value.header
          override = items.value.override
          value    = items.value.value
        }
      }
    }
  }
}

output "test" {
  value = tomap({ for k, v in aws_cloudfront_response_headers_policy.this : k => v.id })
}
























variable "response_headers_policy_parameter" {
  description = ""
  type        = any
  default     = null
}

~~~
