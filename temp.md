```
########################################
# Data: AWS Organizations
########################################

data "aws_organizations_organization" "this" {}







terraform {
  required_version = ">= 1.4.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_organizations_organization" "this" {}

locals {
  organization_root_id = data.aws_organizations_organization.this.roots[0].id

  log_archive_bucket_name = "aws-controltower-logs-123456789012-ap-northeast-1"
  log_archive_bucket_arn  = "arn:aws:s3:::${local.log_archive_bucket_name}"

  # 必要に応じて、Terraform実行ロールやBreakGlassロールを例外にしてください。
  # 例外を入れない場合、該当操作は管理者権限でも拒否されます。
  exempt_principal_arns = [
    "arn:aws:iam::*:role/OrganizationAccountAccessRole",
    "arn:aws:iam::*:role/AWSControlTowerExecution",
    "arn:aws:iam::*:role/BreakGlassAdminRole"
  ]
}

resource "aws_organizations_policy" "security_guardrails" {
  name        = "security-guardrails"
  description = "Prevent changes to log archive bucket, CloudTrail, AWS Config, root access keys, and organization membership."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLogArchiveBucketDeletionAndObjectDeletion"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObjectTagging",
          "s3:DeleteObjectVersionTagging"
        ]
        Resource = [
          local.log_archive_bucket_arn,
          "${local.log_archive_bucket_arn}/*"
        ]
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = local.exempt_principal_arns
          }
        }
      },
      {
        Sid    = "DenyLogArchiveBucketSecuritySettingChanges"
        Effect = "Deny"
        Action = [
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketLogging",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutLifecycleConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketAcl",
          "s3:PutBucketOwnershipControls"
        ]
        Resource = [
          local.log_archive_bucket_arn
        ]
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = local.exempt_principal_arns
          }
        }
      },
      {
        Sid    = "DenyCloudTrailConfigurationChanges"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:PutInsightSelectors",
          "cloudtrail:AddTags",
          "cloudtrail:RemoveTags"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = local.exempt_principal_arns
          }
        }
      },
      {
        Sid    = "DenyAWSConfigConfigurationChanges"
        Effect = "Deny"
        Action = [
          "config:DeleteAggregationAuthorization",
          "config:PutAggregationAuthorization",
          "config:DeleteConfigurationAggregator",
          "config:PutConfigurationAggregator",
          "config:DeleteConfigurationRecorder",
          "config:PutConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:PutDeliveryChannel",
          "config:DeleteRetentionConfiguration",
          "config:PutRetentionConfiguration",
          "config:DeleteConfigRule",
          "config:PutConfigRule",
          "config:DeleteOrganizationConfigRule",
          "config:PutOrganizationConfigRule"
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = local.exempt_principal_arns
          }
        }
      },
      {
        Sid    = "DenyRootUserAccessKeyCreation"
        Effect = "Deny"
        Action = [
          "iam:CreateAccessKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      },
      {
        Sid    = "DenyMemberAccountLeavingOrganization"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "attach_to_root" {
  policy_id = aws_organizations_policy.security_guardrails.id
  target_id = local.organization_root_id
}

resource "aws_organizations_policy" "deny_iam_user_creation" {
  name        = "deny-iam-user-creation"
  description = "Deny IAM user creation because access is managed through IAM Identity Center."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyIAMUserCreation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateLoginProfile",
          "iam:CreateAccessKey",
          "iam:AttachUserPolicy",
          "iam:PutUserPolicy",
          "iam:AddUserToGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "deny_iam_user_creation" {
  name        = "deny-iam-user-creation"
  description = "Deny IAM user creation in member accounts."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCreateIAMUsers"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateLoginProfile",
          "iam:CreateAccessKey"
        ]
        Resource = "*"
      }
    ]
  })
}








########################################
# SCP: Basic mandatory guardrails
########################################

data "aws_iam_policy_document" "scp_basic_guardrails" {
  ########################################
  # Deny root user actions
  ########################################
  statement {
    sid    = "DenyRootUserActions"
    effect = "Deny"

    actions = ["*"]

    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }

  ########################################
  # Deny leaving AWS Organizations
  ########################################
  statement {
    sid    = "DenyLeaveOrganization"
    effect = "Deny"

    actions = ["organizations:LeaveOrganization"]

    resources = ["*"]
  }

  ########################################
  # Deny CloudTrail stop/delete
  ########################################
  statement {
    sid    = "DenyCloudTrailStopAndDelete"
    effect = "Deny"

    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail"
    ]

    resources = ["*"]
  }

  ########################################
  # Deny AWS Config stop/delete
  ########################################
  statement {
    sid    = "DenyConfigStopAndDelete"
    effect = "Deny"

    actions = [
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:DeleteConfigRule",
      "config:DeleteOrganizationConfigRule",
      "config:DeleteOrganizationConformancePack",
      "config:DeleteConformancePack"
    ]

    resources = ["*"]
  }

  ########################################
  # Deny Security Hub disable
  ########################################
  statement {
    sid    = "DenySecurityHubDisable"
    effect = "Deny"

    actions = [
      "securityhub:DisableSecurityHub",
      "securityhub:BatchDisableStandards",
      "securityhub:DeleteConfigurationPolicy",
      "securityhub:DeleteFindingAggregator"
    ]

    resources = ["*"]
  }

  ########################################
  # Deny GuardDuty disable/delete
  ########################################
  statement {
    sid    = "DenyGuardDutyDisableAndDelete"
    effect = "Deny"

    actions = [
      "guardduty:DeleteDetector",
      "guardduty:UpdateDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:DisassociateMembers",
      "guardduty:StopMonitoringMembers",
      "guardduty:DeleteMembers"
    ]

    resources = ["*"]
  }
}

resource "aws_organizations_policy" "scp_basic_guardrails" {
  name        = "org-mandatory-guardrails"
  description = "Basic mandatory SCP guardrails for member accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = data.aws_iam_policy_document.scp_basic_guardrails.json
}

########################################
# Attach SCP to OU or Root
########################################

resource "aws_organizations_policy_attachment" "scp_basic_guardrails" {
  policy_id = aws_organizations_policy.scp_basic_guardrails.id
  target_id = data.aws_organizations_organization.this.roots[0].id
  # target_id = "ou-xxxx-yyyyyyyy"
}







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

# From SCP Samples

/*
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_public_write_prohibited" {
  name = "s3-bucket-public-write-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
}

resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = "14"
    PasswordReusePrevention    = "24"
    MaxPasswordAge             = "90"
  })
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
resource "aws_securityhub_configuration_policy_association" "audit" {
  provider = aws.audit

  target_id = "578673726609"
  #target_id = data.aws_organizations_organization.current.roots[0].id
  policy_id = aws_securityhub_configuration_policy.baseline.id

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [
    aws_securityhub_configuration_policy.baseline
  ]
}

resource "aws_securityhub_configuration_policy_association" "infra" {
  provider = aws.audit

  target_id = "448047748860"
  #target_id = data.aws_organizations_organization.current.roots[0].id
  policy_id = aws_securityhub_configuration_policy.baseline.id

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [
    aws_securityhub_configuration_policy.baseline
  ]
}









data "aws_organizations_organization" "current" {
  provider = aws.management
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_caller_identity" "audit" {
  provider = aws.audit
}








########################################
# Variable
########################################

locals {
  audit_account_id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "audit"
  ][0]

  config_bucket_name = "mbt-config-logs-01"

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








### アカウント

- management
- audit
- log-archive
- infrastructure
- evs-common

### SCP

- ログアーカイブの削除を許可しない。
- ログアーカイブのS3バケットの暗号化設定の変更を許可しない。
- ログアーカイブのS3バケットのログ記録設定の変更を許可しない。
- ログアーカイブのS3バケットのバケットポリシーの変更を許可しない。
- ログアーカイブのS3バケットのパブリック読み取りアクセス設定を検出する。
- ログアーカイブのS3バケットのパブリック書き込みアクセス設定を検出する。
- ログアーカイブのS3バケットのライフサイクル設定の変更を許可しない。
- CloudTrailの設定変更を許可しない。
- CloudTrailログファイルの整合性検証を有効にする。
- AWS Configアグリゲーション認可の削除を許可しない。
- AWS Configの設定変更を許可しない。
- ルートユーザーのアクセスキーの作成を許可しない。
- ルートユーザーのMFAが有効になっているかを検出する。
- IAMユーザーのMFAが有効になっているかを検出する。
- メンバーアカウントが組織を離れるのを禁止する。
- 強力なパスワードポリシーを設定

| 項目                          |   SCPで可能か | 実装方法                               |
| --------------------------- | --------: | ---------------------------------- |
| ログアーカイブS3バケットの削除禁止          |        可能 | SCP                                |
| ログアーカイブS3バケットの暗号化設定変更禁止     |        可能 | SCP                                |
| ログアーカイブS3バケットのログ記録設定変更禁止    |        可能 | SCP                                |
| ログアーカイブS3バケットのバケットポリシー変更禁止  |        可能 | SCP                                |
| パブリック読み取りアクセス設定の検出          |   SCPでは不可 | AWS Config                         |
| パブリック書き込みアクセス設定の検出          |   SCPでは不可 | AWS Config                         |
| ログアーカイブS3バケットのライフサイクル設定変更禁止 |        可能 | SCP                                |
| CloudTrailの設定変更禁止           |        可能 | SCP                                |
| CloudTrailログファイル整合性検証を有効化   |   SCPでは不可 | `aws_cloudtrail`設定                 |
| AWS Configアグリゲーション認可の削除禁止   |        可能 | SCP                                |
| AWS Configの設定変更禁止           |        可能 | SCP                                |
| ルートユーザーのアクセスキー作成禁止          |        可能 | SCP                                |
| ルートユーザーMFAの検出               |   SCPでは不可 | AWS Config                         |
| IAMユーザーMFAの検出               |   SCPでは不可 | AWS Config                         |
| メンバーアカウントの組織離脱禁止            |        可能 | SCP                                |
| 強力なパスワードポリシー設定              | SCPでは設定不可 | IAM password policy / AWS Config検出 |


### グループ

- mck-admin
- mck
- bk-admin
- bk
- nw
- inet

### 許可セット

- org-admin
- workload-operator

### CloudTrail

- org-audit-trail

### S3

- mbt-cmn-management-logs

### IAM Idendity Centerの制約

- アイデンティソースがIdentity Center ディレクトリの場合、パスワードポリシーや有効期限の設定ができない。

### Audit アカウント

- CloudTrail
- Config
- SecurityHub CSPM
- GuardDuty

### Log Archive アカウント

- 各種ログ保管

### Workload用アカウント

- evs
- rosa-prd
- rosa-stg
- ec2
- workspaces

### 流れ (2026/04)

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - Managementアカウント追加
- アカウント追加
  - アカウントを招待
    ```
    aws organizations invite-account-to-organization \
      --target Id=root@test.com,Type=EMAIL \
      --notes "Please join our AWS Organization."
    ```
  - 許可セットをアカウントへ割当
  - AWSコマンド設定
    - メンバーアカウント追加
- CloudTrail作成
  - AuditアカウントをCloudTrail委任管理者に設定
    ```
    aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com
    aws organizations list-aws-service-access-for-organization
    aws cloudtrail register-organization-delegated-admin --member-account-id 123456789
    aws organizations list-delegated-administrators --service-principal cloudtrail.amazonaws.com
    ```
  - Terraformで以下作成
    - S3バケット
    - 証跡
- グループ/権限設定
  - アカウントをTerraformにImport
  - グループ作成
  - 許可セットの作成とアカウントへ割当
  - 初期設定用許可セットを削除
- ユーザー追加
  - Terraformで以下設定
    - ユーザーを作成
    - ユーザーをグループに追加

### 流れ (2026/05/09)

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - 全アカウント設定
- アカウント設定
  - 許可セットをアカウントへ割当
  - AWSコマンド設定
    - メンバーアカウント追加
- グループ/権限設定
  - アカウントをTerraformにImport
  - グループ作成
  - 許可セットの作成とアカウントへ割当
  - 初期設定用許可セットを削除
- ユーザー追加
  - Terraformで以下設定
    - ユーザーを作成
    - ユーザーをグループに追加

### SecurityHub CSPM

- AuditアカウントをSecurityHub CSPMの委任管理者にして、Central Configurationでルートに設定ポリシーおｗ運用するのが基本
- SecurityHub CSPMはOrganizationsと統合後、委任管理者アカウントから組織のアカウント/OUをまたいで複数リージョンに設定可能
- 流れ
  - Organizationsの管理アカウントで、AuditアカウントをSecurityHub CSPMの委任管理者に指定
  - Auditアカウント自身でSecurityHub CSPMを有効化
  - 中央設定を有効にし、設定ポリシーを作成して組織ルートに関連付け
  - 設定ポリシーはアカウント、OU、またはルートに関連付けられ、ルートに運用すると既存の全アカウント/OUに効き、以降追加する新規アカウントも継承
  - 必要に応じて、ホームリージョンとそのリンクリージョンを決める
  - 中央設定のポリシーは、ホームリージョンとそのリンクリージョンすべてに有効です。
  - サマリー
    - Organizationsの管理アカウントでAuditアカウントを委任管理者に指定
    - AuditアカウントでSecurityHub CSPMを有効化
    - 中央設定を開始
    - 東京をホームリージョンに設定
    - 大阪をリンクリージョンに含める
    - 推奨ポリシーまたはカスタムポリシーをルートに関連付ける
    - 併せて、各対象アカウント/リージョンでAWS Configの記録対象が要件を満たしていることを確認する<br>（SecurityHub CSPMのコントロール結果生成にはAWS Configが必要）

### AWS Config

- Organizationsの管理アカウントでAuditアカウントを委任管理者に指定
- 各アカウント・各対象リージョンにConfigruation Recorderを作成して開始
  - AWS公式では、組織全体にRecorderを展開する方法としてAWS system Manager Quick Setupの案内があり、複数のOUや複数リージョンにまたがってCustomer-Managed Configuration Recorderを作成可能

```
