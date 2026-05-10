```
modules/config-recorder





# ------------------------------------------------------------
# AWS Config Service-linked role
#
# This creates:
# arn:aws:iam::<account-id>:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig
#
# The AWS managed policy below is attached by AWS automatically:
# arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy
# ------------------------------------------------------------

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "this" {
  name     = "default"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [
    aws_iam_service_linked_role.config
  ]
}

resource "aws_config_delivery_channel" "this" {
  name           = "default"
  s3_bucket_name = var.config_bucket_name
  s3_key_prefix  = var.config_s3_prefix

  depends_on = [
    aws_config_configuration_recorder.this
  ]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.this
  ]
}






variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config"
  type        = string
}

variable "config_s3_prefix" {
  description = "S3 prefix for AWS Config"
  type        = string
}






terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}






config.tf





########################################
# management account
# Enable AWS Config trusted access for Organizations
########################################

resource "aws_organizations_aws_service_access" "config" {
  provider = aws.management

  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_aws_service_access" "config_multiaccountsetup" {
  provider = aws.management

  service_principal = "config-multiaccountsetup.amazonaws.com"
}

########################################
# management account
# Register audit account as delegated administrator
########################################

resource "aws_organizations_delegated_administrator" "config" {
  provider = aws.management

  account_id        = local.audit_account_id
  service_principal = "config.amazonaws.com"

  depends_on = [
    aws_organizations_aws_service_access.config,
    aws_organizations_aws_service_access.config_multiaccountsetup
  ]
}

resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
  provider = aws.management

  account_id        = local.audit_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"

  depends_on = [
    aws_organizations_aws_service_access.config,
    aws_organizations_aws_service_access.config_multiaccountsetup
  ]
}

########################################
# log-archive account
# S3 bucket for AWS Config logs
########################################

resource "aws_s3_bucket" "config_logs" {
  provider = aws.log_archive

  bucket = local.config_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "config_logs" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.config_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_logs" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.config_logs.id

  rule {
    id     = "config-log-lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

########################################
# log-archive account
# S3 bucket policy for AWS Config
#
# This follows the Control Tower-style AWS Config bucket policy:
# <bucket>/<organizationID>/AWSLogs/*/*
########################################

data "aws_iam_policy_document" "config_logs_bucket_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.config_logs.arn,
      "${aws_s3_bucket.config_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false"
      ]
    }
  }

  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "config.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.config_logs.arn
    ]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "config.amazonaws.com"
      ]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.config_logs.arn
    ]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "config.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.config_logs.arn}/${data.aws_organizations_organization.current.id}/AWSLogs/*/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"

      values = [
        data.aws_organizations_organization.current.id
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "config_logs" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.config_logs.id
  policy = data.aws_iam_policy_document.config_logs_bucket_policy.json
}

########################################
# 5. All accounts:
#    AWS Config Recorder / Delivery Channel
#
#    Important:
#    s3_key_prefix = data.aws_organizations_organization.current.id
#
#    Final S3 path:
#    s3://<bucket>/<organizationID>/AWSLogs/<account-id>/Config/<region>/...
########################################

module "config_recorder_management" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.management
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config_recorder_infrastructure" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.infrastructure
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config_recorder_log_archive" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.log_archive
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config_recorder_audit" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.audit
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

########################################
# 6. audit account:
#    IAM role for AWS Config Organization Aggregator
########################################

data "aws_iam_policy_document" "config_aggregator_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "config.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "config_aggregator" {
  provider = aws.audit

  name               = "aws-config-organization-aggregator-role"
  assume_role_policy = data.aws_iam_policy_document.config_aggregator_assume_role.json
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  provider = aws.audit

  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

########################################
# 7. audit account:
#    AWS Config Aggregator
########################################

resource "aws_config_configuration_aggregator" "organization" {
  provider = aws.audit

  name = "organization-config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_iam_role_policy_attachment.config_aggregator,
    module.config_recorder_audit
  ]
}

/*
########################################
# 8. audit account:
#    Organization Config Rules
########################################

resource "aws_config_organization_managed_rule" "s3_bucket_public_read_prohibited" {
  provider = aws.audit

  name            = "s3-bucket-public-read-prohibited"
  rule_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"

  resource_types_scope = [
    "AWS::S3::Bucket"
  ]

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "s3_bucket_public_write_prohibited" {
  provider = aws.audit

  name            = "s3-bucket-public-write-prohibited"
  rule_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"

  resource_types_scope = [
    "AWS::S3::Bucket"
  ]

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "s3_bucket_server_side_encryption_enabled" {
  provider = aws.audit

  name            = "s3-bucket-server-side-encryption-enabled"
  rule_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"

  resource_types_scope = [
    "AWS::S3::Bucket"
  ]

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "cloudtrail_enabled" {
  provider = aws.audit

  name            = "cloudtrail-enabled"
  rule_identifier = "CLOUD_TRAIL_ENABLED"

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "encrypted_volumes" {
  provider = aws.audit

  name            = "encrypted-volumes"
  rule_identifier = "ENCRYPTED_VOLUMES"

  resource_types_scope = [
    "AWS::EC2::Volume"
  ]

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "incoming_ssh_disabled" {
  provider = aws.audit

  name            = "incoming-ssh-disabled"
  rule_identifier = "INCOMING_SSH_DISABLED"

  depends_on = [
    aws_organizations_delegated_administrator.config_multiaccountsetup,
    aws_config_configuration_aggregator.organization
  ]
}
*/






cspm.tf





########################################
# management account
# Enable AWS Config trusted access for Organizations
########################################

resource "aws_organizations_aws_service_access" "securityhub" {
  provider = aws.management

  service_principal = "securityhub.amazonaws.com"

  # destroy時の逆順実行を保証
  depends_on = [
    aws_securityhub_account.audit
  ]
}

############################################
# audit account
# Enable Security Hub
############################################

resource "aws_securityhub_account" "audit" {
  provider = aws.audit

  enable_default_standards = false
}

########################################
# management account
# Register audit account as delegated administrator
########################################

resource "aws_securityhub_organization_admin_account" "audit" {
  provider = aws.management

  admin_account_id = local.audit_account_id

  depends_on = [
    aws_securityhub_account.audit,
    aws_organizations_aws_service_access.securityhub # 追加
  ]
}

resource "time_sleep" "wait_for_org_sync" {
  depends_on      = [aws_securityhub_organization_admin_account.audit]
  create_duration = "30s"
}

########################################
# audit account
# Configure Finding Aggregator
########################################

resource "aws_securityhub_finding_aggregator" "this" {
  provider = aws.audit

  linking_mode = "NO_REGIONS"
  #  linking_mode      = "SPECIFIED_REGIONS"
  #  specified_regions = local.linked_regions

  depends_on = [
    time_sleep.wait_for_org_sync
  ]
}

########################################
# audit account
# Enable Central Configuration
########################################

resource "aws_securityhub_organization_configuration" "central" {
  provider = aws.audit

  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [
    aws_securityhub_finding_aggregator.this
  ]
}

########################################
# audit account
# Security Hub CSPM Configuration Policy
########################################

resource "aws_securityhub_configuration_policy" "baseline" {
  provider = aws.audit

  name        = "org-securityhub-baseline"
  description = "Organization-wide Security Hub CSPM baseline policy"

  configuration_policy {
    service_enabled = true

    enabled_standard_arns = [
      "arn:aws:securityhub:${local.home_region}::standards/aws-foundational-security-best-practices/v/1.0.0",
      "arn:aws:securityhub:${local.home_region}::standards/cis-aws-foundations-benchmark/v/5.0.0"
    ]

    security_controls_configuration {
      # 基本は無効化リスト方式を推奨
      # 新しいFSBPコントロールが追加された場合、自動的に有効化されやすい
      disabled_control_identifiers = [
        # 例:
        # "EC2.10",
        # "S3.5"
      ]
    }
  }

  depends_on = [
    aws_securityhub_organization_configuration.central
  ]
}

########################################
# audit account
# Associate policy to Organization Root
########################################
/*
resource "aws_securityhub_configuration_policy_association" "root" {
  provider = aws.audit

  target_id = data.aws_organizations_organization.current.roots[0].id
  policy_id = aws_securityhub_configuration_policy.baseline.id

  depends_on = [
    aws_securityhub_configuration_policy.baseline
  ]
}
*/






data "aws_organizations_organization" "current" {
  provider = aws.management
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_caller_identity" "audit" {
  provider = aws.audit
}





locals.tf

########################################
# Variable
########################################

locals {
  audit_account_id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "audit"
  ][0]

  config_bucket_name = "test-config-logs-01"

  # Security Hub CSPM Home Region
  home_region = "ap-northeast-1"

  # 必要なリージョンだけ指定することを推奨
  linked_regions = [
    "ap-northeast-3",
    "us-east-1"
  ]
}






provider "aws" {
  alias   = "management"
  region  = "ap-northeast-1"
  profile = "management"
}

provider "aws" {
  alias   = "infrastructure"
  region  = "ap-northeast-1"
  profile = "infra"
}

provider "aws" {
  alias   = "log_archive"
  region  = "ap-northeast-1"
  profile = "log-archive"
}

provider "aws" {
  alias   = "audit"
  region  = "ap-northeast-1"
  profile = "audit"
}

```
