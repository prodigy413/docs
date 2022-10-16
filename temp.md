~~~
module "waf_acl_01" {
  source = "../modules"

  name                   = "test-WebACL-01"
  description            = "test-WebACL-01"
  scope                  = "REGIONAL"
  enable_custom_response = "true"
  #enable_custom_response = "false"

  custom_response_parameter = [{
    content       = "<h1>Test</h1>"
    content_type  = "TEXT_HTML"
    key           = "WAF-obi-block-respons-01"
    response_code = "403"
  }]
}















variable "custom_response_parameter" {
  description = ""
  type = list(object({
    content       = string
    content_type  = string
    key           = string
    response_code = string
  }))
  default = null
}










resource "aws_wafv2_web_acl" "web_acl_01" {
  name        = var.name
  description = var.description
  scope       = var.scope

  dynamic "custom_response_body" {
    for_each = var.enable_custom_response ? var.custom_response_parameter : []
    content {
      key          = custom_response_body.value.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  default_action {
    block {
      dynamic "custom_response" {
        for_each = var.enable_custom_response ? var.custom_response_parameter : []
        content {
          custom_response_body_key = custom_response.value.key
          response_code            = custom_response.value.response_code
        }
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = var.name
    sampled_requests_enabled   = false
  }
}

~~~
