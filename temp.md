~~~
module "s3" {
  source           = "../modules"
  name             = "obi-test-s3-01"
  enable_lifecycle = true
  lifecycle_parameter = [
    {
      id = "test-rule-01"
      filter = {
        prefix = "logs/"
      }
      expiration = {
        days = 60
      }
      transition = {
        days          = 30
        storage_class = "GLACIER"
      }
      noncurrent_version_expiration = {
        days = 60
      }
      noncurrent_version_transition = {
        days          = 30
        storage_class = "GLACIER"
      }
    },
    {
      id = "test-rule-02"
      expiration = {
        days = 60
      }
      transition = {
        days          = 30
        storage_class = "GLACIER"
      }
      noncurrent_version_expiration = {
        days = 60
      }
      noncurrent_version_transition = {
        days          = 30
        storage_class = "GLACIER"
      }
    }
  ]
}










resource "aws_s3_bucket" "bucket_01" {
  bucket        = var.name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl_01" {
  bucket = aws_s3_bucket.bucket_01.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_01" {
  bucket = aws_s3_bucket.bucket_01.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_01" {
  bucket = aws_s3_bucket.bucket_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_01" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.bucket_01.bucket

  dynamic "rule" {
    for_each = var.lifecycle_parameter

    content {
      id = try(rule.value.id, null)

      dynamic "filter" {
        for_each = try(flatten([rule.value.filter]), [])

        content {
          prefix = try(filter.value.prefix, null)
        }
      }

      dynamic "expiration" {
        for_each = try(flatten([rule.value.expiration]), [])

        content {
          days = try(expiration.value.days, null)
        }
      }

      dynamic "transition" {
        for_each = try(flatten([rule.value.transition]), [])

        content {
          days          = try(transition.value.days, null)
          storage_class = try(transition.value.storage_class, null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(flatten([rule.value.noncurrent_version_expiration]), [])

        content {
          noncurrent_days = try(noncurrent_version_expiration.value.days, null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(flatten([rule.value.noncurrent_version_transition]), [])

        content {
          noncurrent_days = try(noncurrent_version_transition.value.days, null)
          storage_class   = try(noncurrent_version_transition.value.storage_class, null)
        }
      }

      status = "Enabled"
    }
  }
}










variable "name" {
  type = string
}

variable "enable_lifecycle" {
  type    = bool
  default = false
}

variable "lifecycle_parameter" {
  type    = any
  default = null
}

~~~
