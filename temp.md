~~~
provider.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}







s3.tf
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

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id = var.s3_lifecycle_rule_name
    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 1825
    }
    status = "Enabled"
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

  comment = aws_s3_bucket.s3_bucket.id
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










variables.tf
variable "s3_bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default     = { Terraform = "managed" }
}

variable "s3_lifecycle_rule_name" {
  description = "S3ライフサイクルルール名"
  type        = string
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











s3.tf
/*
##############################
# 静的コンテンツ(sorryページ)
##############################
module "s3_stcon" {
  source = "../modules/s3"

  s3_bucket_name         = var.s3_bucket_name_stcon
  s3_lifecycle_rule_name = var.s3_lifecycle_rule_name_stcon
  enable_cloudfront_oai  = var.enable_cloudfront_oai_stcon
}

output "s3_stcon_id" {
  value = module.s3_stcon.s3_id
}

output "s3_stcon_arn" {
  value = module.s3_stcon.s3_arn
}

##############################
# アプリケーション用領域
##############################
module "s3_aplfs" {
  source = "../modules/s3"

  s3_bucket_name         = var.s3_bucket_name_aplfs
  s3_lifecycle_rule_name = var.s3_lifecycle_rule_name_aplfs
}

output "s3_aplfs_id" {
  value = module.s3_aplfs.s3_id
}

output "s3_aplfs_arn" {
  value = module.s3_aplfs.s3_arn
}

##############################
# ウイルススキャン隔離用
##############################
module "s3_viqua" {
  source = "../modules/s3"

  s3_bucket_name         = var.s3_bucket_name_viqua
  s3_lifecycle_rule_name = var.s3_lifecycle_rule_name_viqua
}

output "s3_viqua_id" {
  value = module.s3_viqua.s3_id
}

output "s3_viqua_arn" {
  value = module.s3_viqua.s3_arn
}

##############################
# ウイルススキャンクリーン用
##############################
module "s3_vclen" {
  source = "../modules/s3"

  s3_bucket_name         = var.s3_bucket_name_vclen
  s3_lifecycle_rule_name = var.s3_lifecycle_rule_name_vclen
}

output "s3_vclen_id" {
  value = module.s3_vclen.s3_id
}

output "s3_vclen_arn" {
  value = module.s3_vclen.s3_arn
}

##############################
# SFTP領域
##############################
module "s3_ftpsv" {
  source = "../modules/s3"

  s3_bucket_name         = var.s3_bucket_name_ftpsv
  s3_lifecycle_rule_name = var.s3_lifecycle_rule_name_ftpsv
  enable_notification    = var.enable_notification_ftpsv
}

output "s3_ftpsv_id" {
  value = module.s3_ftpsv.s3_id
}

output "s3_ftpsv_arn" {
  value = module.s3_ftpsv.s3_arn
}

##############################
# ファイル/データバックアップ保管
##############################
module "s3_datbk" {
  source = "../modules/s3"

  s3_bucket_name            = var.s3_bucket_name_datbk
  s3_lifecycle_rule_name    = var.s3_lifecycle_rule_name_datbk
  enable_creating_directory = var.enable_creating_directory_datbk
  directory                 = var.directory_datbk
}

output "s3_datbk_id" {
  value = module.s3_datbk.s3_id
}

output "s3_datbk_arn" {
  value = module.s3_datbk.s3_arn
}

##############################
# ログファイル保管
##############################
module "s3_flogs01" {
  source = "../modules/s3"

  s3_bucket_name            = var.s3_bucket_name_flogs01
  s3_lifecycle_rule_name    = var.s3_lifecycle_rule_name_flogs01
  enable_logging_for_alb    = var.enable_logging_for_alb_flogs01
  enable_creating_directory = var.enable_creating_directory_flogs01
  directory                 = var.directory_flogs01
}

output "s3_flogs01_id" {
  value = module.s3_flogs01.s3_id
}

output "s3_flogs01_arn" {
  value = module.s3_flogs01.s3_arn
}

##############################
# CloudFrontアクセスログ領域
##############################
module "s3_flogs02" {
  source = "../modules/s3"

  s3_bucket_name                = var.s3_bucket_name_flogs02
  s3_lifecycle_rule_name        = var.s3_lifecycle_rule_name_flogs02
  enable_logging_for_cloudfront = var.enable_logging_for_cloudfront_flogs02
  enable_creating_directory     = var.enable_creating_directory_flogs02
  directory                     = var.directory_flogs02
}

output "s3_flogs02_id" {
  value = module.s3_flogs02.s3_id
}

output "s3_flogs02_arn" {
  value = module.s3_flogs02.s3_arn
}
*/















variables.tf
/*
##############################
# 静的コンテンツ(sorryページ)
##############################
variable "s3_bucket_name_stcon" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tstcon001"
}

variable "s3_lifecycle_rule_name_stcon" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tstcon001"
}

variable "enable_cloudfront_oai_stcon" {
  description = "Cloudfront OAI用設定を有効/無効"
  type        = bool
  default     = true
}

##############################
# アプリケーション用領域
##############################
variable "s3_bucket_name_aplfs" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1taplfs001"
}

variable "s3_lifecycle_rule_name_aplfs" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1taplfs001"
}

##############################
# ウイルススキャン隔離用
##############################
variable "s3_bucket_name_viqua" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tviqua001"
}

variable "s3_lifecycle_rule_name_viqua" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tviqua001"
}

##############################
# ウイルススキャンクリーン用
##############################
variable "s3_bucket_name_vclen" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tvclen001"
}

variable "s3_lifecycle_rule_name_vclen" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tvclen001"
}

##############################
# SFTP領域
##############################
variable "s3_bucket_name_ftpsv" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tftpsv001"
}

variable "s3_lifecycle_rule_name_ftpsv" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tftpsv001"
}

variable "enable_notification_ftpsv" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = true
}

##############################
# ファイル/データバックアップ保管
##############################
variable "s3_bucket_name_datbk" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tdatbk001"
}

variable "s3_lifecycle_rule_name_datbk" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tdatbk001"
}

variable "enable_creating_directory_datbk" {
  description = "S3フォルダ作成用設定を有効/無効"
  type        = bool
  default     = true
}

variable "directory_datbk" {
  description = "作成するフォルダ名"
  type        = list(string)
  default     = ["test01/", "test02/"]
}

##############################
# ログファイル保管
##############################
variable "s3_bucket_name_flogs01" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tflogs001"
}

variable "s3_lifecycle_rule_name_flogs01" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tflogs001"
}

variable "enable_logging_for_alb_flogs01" {
  description = "ALBログ用設定を有効/無効"
  type        = bool
  default     = true
}

variable "enable_creating_directory_flogs01" {
  description = "S3フォルダ作成用設定を有効/無効"
  type        = bool
  default     = true
}

variable "directory_flogs01" {
  description = "作成するフォルダ名"
  type        = list(string)
  default     = ["test01/", "test02/"]
}

##############################
# CloudFrontアクセスログ領域
##############################
variable "s3_bucket_name_flogs02" {
  description = "S3バケット名"
  type        = string
  default     = "s3-mcid1d1tflogs002"
}

variable "s3_lifecycle_rule_name_flogs02" {
  description = "S3ライフサイクルルール名"
  type        = string
  default     = "LC-s3-mcid1d1tflogs002"
}

variable "enable_logging_for_cloudfront_flogs02" {
  description = "Cloudfrontログ用設定を有効/無効"
  type        = bool
  default     = true
}

variable "enable_creating_directory_flogs02" {
  description = "S3フォルダ作成用設定を有効/無効"
  type        = bool
  default     = true
}

variable "directory_flogs02" {
  description = "作成するフォルダ名"
  type        = list(string)
  default     = ["test01/", "test02/"]
}
*/


~~~
