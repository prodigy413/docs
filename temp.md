~~~
  conditions = [{
    string_equals = [
      {
        key   = "AWSBackup"
        value = "managed"
      }
    ]
  }]
  
  
  
  
  
  
variable "conditions" {
  description = "バックアップ対象用タグ"
  type        = any
  default     = null
}






  condition {
    dynamic "string_equals" {
      for_each = lookup(element(var.conditions, count.index), "string_equals", [])
      content {
        key   = "aws:ResourceTag/${string_equals.value.key}"
        value = string_equals.value.value
      }
    }
    dynamic "string_like" {
      for_each = lookup(element(var.conditions, count.index), "string_like", [])
      content {
        key   = "aws:ResourceTag/${string_like.value.key}"
        value = string_like.value.value
      }
    }
    dynamic "string_not_equals" {
      for_each = lookup(element(var.conditions, count.index), "string_not_equals", [])
      content {
        key   = "aws:ResourceTag/${string_not_equals.value.key}"
        value = string_not_equals.value.value
      }
    }
    dynamic "string_not_like" {
      for_each = lookup(element(var.conditions, count.index), "string_not_like", [])
      content {
        key   = "aws:ResourceTag/${string_not_like.value.key}"
        value = string_not_like.value.value
      }
    }
  }
~~~
