~~~
module "s3" {
  source       = "../modules"
  name         = "obi-test-s3-01"
  s3_lifecycle = true
  lifecycle_parameter = {
    rule_name = "test-rule"
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
  count = var.s3_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.bucket_01.bucket

  rule {
    id = var.lifecycle_parameter.rule_name

    dynamic "expiration" {
      for_each = try(flatten([var.lifecycle_parameter.expiration]), [])

      content {
        days = try(expiration.value["days"], null)
      }
    }

    dynamic "transition" {
      for_each = try(flatten([var.lifecycle_parameter.transition]), [])

      content {
        days          = try(transition.value["days"], null)
        storage_class = try(transition.value["storage_class"], null)
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = try(flatten([var.lifecycle_parameter.noncurrent_version_expiration]), [])

      content {
        noncurrent_days = try(noncurrent_version_expiration.value["days"], null)
      }
    }

    dynamic "noncurrent_version_transition" {
      for_each = try(flatten([var.lifecycle_parameter.noncurrent_version_transition]), [])

      content {
        noncurrent_days = try(noncurrent_version_transition.value["days"], null)
        storage_class   = try(noncurrent_version_transition.value["storage_class"], null)
      }
    }

    status = "Enabled"
  }
}










variable "name" {
  type = string
}

variable "s3_lifecycle" {
  type    = bool
  default = false
}

variable "lifecycle_parameter" {
  #type    = map(map(string))
  type    = any
  default = null
}


~~~
