~~~
##############################
# S3 Bucket Basic
##############################
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name

  tags = merge(
    {
      Name = var.s3_bucket_name
    },
    var.terraform_tag
  )
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration { status = "Enabled" }
}

##############################
# Lifecycle
##############################
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id

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

##############################
# Ownership Controls
##############################
resource "aws_s3_bucket_ownership_controls" "s3_bucket" {
  count = var.enable_logging_for_cloudfront ? 0 : 1

  bucket = aws_s3_bucket.s3_bucket.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

##############################
# ALB Access Logs
##############################
data "aws_elb_service_account" "main" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "alb_access_logs" {
  count = var.enable_logging_for_alb ? 1 : 0

  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/logfile/ALB/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count = var.enable_logging_for_alb ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.alb_access_logs[count.index].json
}

##############################
# CloudFront Origin Access Identity
##############################
resource "aws_cloudfront_origin_access_identity" "cloudfront_access_logs" {
  count = var.enable_cloudfront_oai ? 1 : 0

  comment = "OAI-${aws_s3_bucket.s3_bucket.id}.s3.ap-northeast-1.amazonaws.com"
}

data "aws_iam_policy_document" "cloudfront_access_logs" {
  count = var.enable_cloudfront_oai ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfront_access_logs[count.index].iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access_logs" {
  count = var.enable_cloudfront_oai ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_access_logs[count.index].json
}

##############################
# CloudFront Access Logs
##############################
data "aws_cloudfront_log_delivery_canonical_user_id" "current" {}
data "aws_canonical_user_id" "current_user" {}

resource "aws_s3_bucket_acl" "cloudfront_access_logs" {
  count = var.enable_logging_for_cloudfront ? 1 : 0

  bucket = aws_s3_bucket.s3_bucket.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current_user.id
    }

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current_user.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
  }
}

##############################
# S3 Directory
##############################
resource "aws_s3_object" "s3_bucket" {
  count = var.enable_creating_directory ? length(var.directory) : 0

  bucket = aws_s3_bucket.s3_bucket.id
  key    = element(var.directory, count.index)
}

##############################
# S3 Notification
##############################
resource "aws_s3_bucket_notification" "s3_bucket" {
  count = var.enable_notification ? 1 : 0

  bucket      = aws_s3_bucket.s3_bucket.id
  eventbridge = true
}

##############################
# S3 Cross Region Replication
##############################

# IAM Policy, Role
data "aws_iam_policy_document" "sts" {
  count = var.enable_replication ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_bucket" {
  count = var.enable_replication ? 1 : 0

  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [var.source_s3_bucket_arn]
  }
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${var.source_s3_bucket_arn}/*"]
  }
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = ["${var.destination_s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role" "s3_bucket" {
  count = var.enable_replication ? 1 : 0

  name               = var.replication_role_name
  assume_role_policy = data.aws_iam_policy_document.sts[count.index].json
}

resource "aws_iam_policy" "s3_bucket" {
  count = var.enable_replication ? 1 : 0

  name   = var.replication_policy_name
  policy = data.aws_iam_policy_document.s3_bucket[count.index].json
}

resource "aws_iam_role_policy_attachment" "s3_bucket" {
  count = var.enable_replication ? 1 : 0

  policy_arn = aws_iam_policy.s3_bucket[count.index].arn
  role       = aws_iam_role.s3_bucket[count.index].name
}

# S3 Cross Region Replication
resource "aws_s3_bucket_replication_configuration" "s3_bucket" {
  count = var.enable_replication ? 1 : 0

  bucket = var.source_s3_bucket_name
  role   = aws_iam_role.s3_bucket[count.index].arn

  rule {
    id     = var.replication_rule_name
    status = "Enabled"

    destination {
      bucket        = var.destination_s3_bucket_arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket.s3_bucket]
}

##############################
# Output
##############################
output "s3_arn" {
  value = aws_s3_bucket.s3_bucket.arn
}

output "s3_id" {
  value = aws_s3_bucket.s3_bucket.id
}

output "s3_domain_name" {
  value = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "s3_regional_domain_name" {
  value = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
}


















variable "s3_bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default     = { Terraform = "managed" }
}

variable "enable_lifecycle" {
  description = "S3ライフサイクル設定を有効/無効"
  type        = bool
  default     = false
}

variable "lifecycle_parameter" {
  description = "S3ライフサイクル設定用パラメータ"
  type        = any
  default     = null
}

variable "enable_creating_directory" {
  description = "S3フォルダ作成用設定を有効/無効"
  type        = bool
  default     = false
}

variable "directory" {
  description = "作成するフォルダ名"
  type        = list(string)
  default     = [null]
}

variable "enable_cloudfront_oai" {
  description = "Cloudfront OAI用設定を有効/無効"
  type        = bool
  default     = false
}

variable "enable_logging_for_alb" {
  description = "ALBログ用設定を有効/無効"
  type        = bool
  default     = false
}

variable "enable_logging_for_cloudfront" {
  description = "Cloudfrontログ用設定を有効/無効"
  type        = bool
  default     = false
}

variable "enable_notification" {
  description = "Notification設定を有効/無効"
  type        = bool
  default     = false
}

variable "enable_replication" {
  description = "Replication設定を有効/無効"
  type        = bool
  default     = false
}

variable "replication_rule_name" {
  description = "レプリケーションルール名"
  type        = string
  default     = null
}

variable "source_s3_bucket_arn" {
  description = "レプリケーションソースバケットのArn"
  type        = string
  default     = null
}

variable "destination_s3_bucket_arn" {
  description = "レプリケーションデスティネーションバケットのArn"
  type        = string
  default     = null
}

variable "source_s3_bucket_name" {
  description = "レプリケーションソースバケット名"
  type        = string
  default     = null
}

variable "replication_role_name" {
  description = "レプリケーション用IAMロール名"
  type        = string
  default     = null
}

variable "replication_policy_name" {
  description = "レプリケーション用IAMポリシー名"
  type        = string
  default     = null
}

~~~
