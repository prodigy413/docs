~~~
  dynamic "custom_error_response" {
    for_each = var.custom_error_response

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = try(custom_error_response.value.response_code, null)
      response_page_path    = try(custom_error_response.value.response_page_path, null)
      error_caching_min_ttl = try(custom_error_response.value.error_caching_min_ttl, null)
    }
  }



variable "custom_error_response" {
  description = "One or more custom error response elements"
  type        = any
  default     = {}
}



  custom_error_response = [
    {
      error_code            = 404
      response_code         = 404
      response_page_path    = "/test/test.html"
      error_caching_min_ttl = 10
    }
  ]
~~~
