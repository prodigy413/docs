```
# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

import {
  to = aws_organizations_account.management
  id = "xxxxxx"
}

import {
  to = aws_organizations_account.audit
  id = "xxxxxx"
}

import {
  to = aws_organizations_account.log-archive
  id = "xxxxxx"
}

import {
  to = aws_organizations_account.infrastructure
  id = "xxxxxx"
}
import {
  to = aws_organizations_account.evs
  id = "xxxxxx"
}

import {
  to = aws_organizations_account.system-stg
  id = "xxxxxx"
}

import {
  to = aws_organizations_account.system-prd
  id = "xxxxxx"
}










^.*(?:null|__generated__|\{\}).*\r?\n









resource "aws_organizations_account" "management" {
  email     = "root@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "management"
    ManagedBy   = "mck"
    Owner       = "mck"
  }
}

resource "aws_organizations_account" "log-archive" {
  email     = "test08@test.com"
  name      = "log-archive"
  parent_id = aws_organizations_organizational_unit.root["security"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Security"
    ManagedBy   = "mck"
    Owner       = "mck"
  }

  depends_on = [aws_organizations_organizational_unit.root["security"]]
}

resource "aws_organizations_account" "audit" {
  email     = "test05@test.com"
  name      = "audit"
  parent_id = aws_organizations_organizational_unit.root["security"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Security"
    ManagedBy   = "mck"
    Owner       = "mck"
  }

  depends_on = [aws_organizations_organizational_unit.root["security"]]
}

resource "aws_organizations_account" "infrastructure" {
  email     = "test04@test.com"
  name      = "infrastructure"
  parent_id = aws_organizations_organizational_unit.root["infra"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Infrastructure"
    ManagedBy   = "mck"
    Owner       = "mck"
  }

  depends_on = [aws_organizations_organizational_unit.root["infra"]]
}

resource "aws_organizations_account" "system-prd" {
  email     = "test09@test.com"
  name      = "system-prd"
  parent_id = aws_organizations_organizational_unit.workload["prod"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Workload"
    ManagedBy   = "mck"
    Owner       = "bk"
  }

  depends_on = [aws_organizations_organizational_unit.workload["prod"]]
}

resource "aws_organizations_account" "system-stg" {
  email     = "test07@test.com"
  name      = "system-stg"
  parent_id = aws_organizations_organizational_unit.workload["non-prod"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Workload"
    ManagedBy   = "mck"
    Owner       = "bk"
  }

  depends_on = [aws_organizations_organizational_unit.workload["non-prod"]]
}

resource "aws_organizations_account" "evs" {
  email     = "test06@test.com"
  name      = "evs"
  parent_id = aws_organizations_organizational_unit.workload["common"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Workload"
    ManagedBy   = "mck"
    Owner       = "bk"
  }

  depends_on = [aws_organizations_organizational_unit.workload["common"]]
}










############################
# Variables
############################
locals {
  root_id           = data.aws_organizations_organization.this.roots[0].id
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

############################
# Organizational Units
############################
locals {
  root_ous = {
    security = "security"
    infra    = "infrastructure"
    workload = "workload"
  }

  workload_ous = {
    common   = "common"
    prod     = "prod"
    non-prod = "non-prod"
  }
}

resource "aws_organizations_organizational_unit" "root" {
  for_each = local.root_ous

  name      = each.value
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workload" {
  for_each = local.workload_ous

  name      = each.value
  parent_id = aws_organizations_organizational_unit.root["workload"].id
}

############################
# Groups
############################
locals {
  identity_store_groups = {
    mck-admin = "MultiCloud Kiban Team Administrators"
    mck       = "MultiCloud Kiban Team"
    bk        = "Bunsan Kiban Team"
    nw        = "Network Team"
    inet      = "Internet Team"
    assist    = "Assist Team"
  }
}

resource "aws_identitystore_group" "this" {
  for_each = local.identity_store_groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value
}

############################
# Permission Sets
############################
locals {
  ssoadmin_permission_sets = {
    org-admin = {
      name        = "org-admin"
      description = "Organization-wide administrator"
    }

    workload-operator = {
      name        = "workload-operator"
      description = "Workload operator"
    }
  }
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.ssoadmin_permission_sets

  instance_arn     = local.instance_arn
  name             = each.value.name
  description      = each.value.description
  session_duration = "PT8H"
}

############################
# Managed Policy Attachments
############################
locals {
  ssoadmin_managed_policy_attachments = {
    org_admin_adminaccess = {
      permission_set_arn = aws_ssoadmin_permission_set.this["org-admin"].arn
      managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
    }

    workload_operator_poweruser = {
      permission_set_arn = aws_ssoadmin_permission_set.this["workload-operator"].arn
      managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
    }
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.ssoadmin_managed_policy_attachments

  instance_arn       = local.instance_arn
  permission_set_arn = each.value.permission_set_arn
  managed_policy_arn = each.value.managed_policy_arn
}

############################
# Inline policy document for workload-operator
############################

data "aws_iam_policy_document" "workload-operator-inline" {
  ########################################
  # Organization / Account / Control Tower
  ########################################
  statement {
    sid    = "DenyOrganizationAccountAndControlTowerManagement"
    effect = "Deny"

    actions = [
      # AWS Organizations
      "organizations:*",

      # AWS Account Management
      "account:*",

      # AWS Control Tower
      "controltower:*",
      "controlcatalog:*"
    ]

    resources = ["*"]
  }

  ########################################
  # IAM Identity Center / Identity Store
  ########################################
  statement {
    sid    = "DenyIdentityCenterManagement"
    effect = "Deny"

    actions = [
      "sso:*",
      "sso-directory:*",
      "identitystore:*"
    ]

    resources = ["*"]
  }

  ########################################
  # Security / Audit / Governance Services
  ########################################
  statement {
    sid    = "DenySecurityAuditAndGovernanceServices"
    effect = "Deny"

    actions = [
      # Logging / Audit
      "cloudtrail:*",
      "config:*",
      "auditmanager:*",

      # Security posture / threat detection
      "securityhub:*",
      "guardduty:*",
      "detective:*",
      "inspector:*",
      "inspector2:*",
      "macie2:*",
      "securitylake:*",
      "access-analyzer:*",

      # Firewall / org-wide security management
      "fms:*",

      # AWS Artifact
      "artifact:*"
    ]

    resources = ["*"]
  }

  ########################################
  # Billing / Cost Management
  ########################################
  statement {
    sid    = "DenyBillingAndCostManagement"
    effect = "Deny"

    actions = [
      "billing:*",
      "ce:*",
      "budgets:*",
      "cur:*",
      "cur-reporting:*",
      "cost-optimization-hub:*",
      "bcm-data-exports:*",
      "pricing:*",
      "payments:*",
      "tax:*",
      "invoicing:*",
      "consolidatedbilling:*",
    ]

    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "workload-operator-inline" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this["workload-operator"].arn
  inline_policy      = data.aws_iam_policy_document.workload-operator-inline.json
}

############################
# Account Assignments
############################

locals {
  account_assignments = {
    ############################
    # mck-admin
    ############################
    mgmt-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.management.id
    }
    audit-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.audit.id
    }
    log-archive-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.log-archive.id
    }
    infra-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
    evs-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-prd-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.system-prd.id
    }
    system-stg-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["org-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }

    ############################
    # bk
    ############################
    evs-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-prd-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.system-prd.id
    }
    system-stg-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }

    ############################
    # assist
    ############################
    infra-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
    evs-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-prd-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.system-prd.id
    }
    system-stg-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }

    ############################
    # nw
    ############################
    infra-nw = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["nw"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignments

  instance_arn       = local.instance_arn
  permission_set_arn = each.value.permission_set

  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.target_id
  target_type = "AWS_ACCOUNT"
}

resource "terraform_data" "run-script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 10 && python3 get-org-info.py"
  }

  depends_on = [
    aws_ssoadmin_account_assignment.this
  ]
}









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










########################################
# Variable
########################################

locals {
  audit_account_id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "audit"
  ][0]

  config_bucket_name = "mbt-mgmt-logs-01"

  # Security Hub CSPM Home Region
  home_region = "ap-northeast-1"

  # 必要なリージョンだけ指定することを推奨
  linked_regions = [
    "ap-northeast-3",
    "us-east-1"
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










provider "aws" {
  alias   = "management"
  region  = "ap-northeast-1"
  profile = "management"
}

provider "aws" {
  alias   = "infrastructure"
  region  = "ap-northeast-1"
  profile = "infrastructure"
}

provider "aws" {
  alias   = "audit"
  region  = "ap-northeast-1"
  profile = "audit"
}

provider "aws" {
  alias   = "log-archive"
  region  = "ap-northeast-1"
  profile = "log-archive"
}

provider "aws" {
  alias   = "evs"
  region  = "ap-northeast-1"
  profile = "evs"
}

provider "aws" {
  alias   = "system-prd"
  region  = "ap-northeast-1"
  profile = "system-prd"
}

provider "aws" {
  alias   = "system-stg"
  region  = "ap-northeast-1"
  profile = "system-stg"
}











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
  provider = aws.log-archive

  bucket = local.config_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "config_logs" {
  provider = aws.log-archive

  bucket = aws_s3_bucket.config_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_logs" {
  provider = aws.log-archive

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
# S3 bucket policy for AWS Config logs
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
  provider = aws.log-archive

  bucket = aws_s3_bucket.config_logs.id
  policy = data.aws_iam_policy_document.config_logs_bucket_policy.json
}

########################################
# All accounts:
# AWS Config Recorder / Delivery Channel
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

module "config-recorder-infrastructure" {
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

module "config-recorder-audit" {
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

module "config-recorder-log-archive" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.log-archive
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config-recorder-evs" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.evs
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config-recorder-system-prd" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.system-prd
  }

  config_bucket_name = aws_s3_bucket.config_logs.bucket
  config_s3_prefix   = data.aws_organizations_organization.current.id

  depends_on = [
    aws_s3_bucket_policy.config_logs
  ]
}

module "config-recorder-system-stg" {
  source = "./modules/config-recorder"

  providers = {
    aws = aws.system-stg
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
    module.config-recorder-audit
  ]
}

########################################
# 8. audit account:
#    Organization Config Rules
########################################
resource "aws_config_organization_managed_rule" "cloudtrail_enabled" {
  provider = aws.audit

  name            = "cloudtrail-enabled"
  rule_identifier = "CLOUD_TRAIL_ENABLED"

  depends_on = [
    aws_config_configuration_aggregator.organization
  ]
}

resource "aws_config_organization_managed_rule" "securityhub_enabled" {
  provider = aws.audit

  name            = "securityhub-enabled"
  rule_identifier = "SECURITYHUB_ENABLED"

  depends_on = [
    aws_config_configuration_aggregator.organization
  ]
}

/*
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









/*
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
    aws_organizations_aws_service_access.securityhub
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
resource "aws_securityhub_configuration_policy_association" "root" {
  provider = aws.audit

  target_id = data.aws_organizations_organization.current.roots[0].id
  policy_id = aws_securityhub_configuration_policy.baseline.id

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [
    aws_securityhub_configuration_policy.baseline
  ]
}
/*
resource "aws_securityhub_configuration_policy_association" "audit" {
  provider = aws.audit

  target_id = "578673726609"
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
  policy_id = aws_securityhub_configuration_policy.baseline.id

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [
    aws_securityhub_configuration_policy.baseline
  ]
}
*/











############################
# 事前チェック
############################
resource "terraform_data" "run_script" {
  provisioner "local-exec" {
    command = "python3 checker.py"
  }

  triggers_replace = {
    always_run = timestamp()
  }
}

############################
# Variables
############################
locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  user_data         = csvdecode(file("${path.module}/users.csv"))

  # group列を ; で分割し、ユーザー × グループ の組み合わせに展開
  # 例:
  # user03@gtest.com, SuperAdmin;operator
  # =>
  # user03@gtest.com -> SuperAdmin
  # user03@gtest.com -> operator
  user_group_pairs = flatten([
    for u in local.user_data : [
      for g in split(";", u.group) : {
        username   = u.username
        group_name = trimspace(g)
      }
    ]
  ])

  # CSV内で利用されているグループ名を重複排除して取得
  # 例: SuperAdmin, operator, test
  group_names = toset([
    for pair in local.user_group_pairs : pair.group_name
  ])
}

############################
# Get group IDs
############################
data "aws_identitystore_group" "this" {
  for_each          = local.group_names
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }

  depends_on = [terraform_data.run_script]
}

############################
# Create users
############################
resource "aws_identitystore_user" "this" {
  for_each          = { for u in local.user_data : u.username => u }
  identity_store_id = local.identity_store_id

  display_name = "${each.value.firstname} ${each.value.lastname}"
  user_name    = each.value.username

  name {
    given_name  = each.value.firstname
    family_name = each.value.lastname
  }

  emails {
    primary = true
    value   = each.value.username
  }

  depends_on = [terraform_data.run_script]
}

############################
# Assign users to groups
############################
resource "aws_identitystore_group_membership" "this" {
  for_each = {
    for pair in local.user_group_pairs :
    "${pair.username}/${pair.group_name}" => pair
  }

  identity_store_id = local.identity_store_id

  group_id  = data.aws_identitystore_group.this[each.value.group_name].id
  member_id = aws_identitystore_user.this[each.value.username].user_id

  depends_on = [terraform_data.run_script]
}

############################
# Get user lists
############################
resource "terraform_data" "verify_groups_sequentially" {
  depends_on = [aws_identitystore_group_membership.this]

  provisioner "local-exec" {
    command = <<EOT
      %{for g_name, g_obj in data.aws_identitystore_group.this~}
      echo "=========================================================="
      echo "GROUP: ${g_name}"
      echo "----------------------------------------------------------"

      # Get member IDs
      USER_IDS=$(aws identitystore list-group-memberships \
        --identity-store-id ${local.identity_store_id} \
        --group-id ${g_obj.id} \
        --query "GroupMemberships[].MemberId.UserId" \
        --output text)

      if [ -z "$USER_IDS" ] || [ "$USER_IDS" = "None" ]; then
        echo "No members found in this group."
      else
        echo "Users:"
        # Retrieve details of each user sequentially
        for id in $USER_IDS; do
          aws identitystore describe-user \
            --identity-store-id ${local.identity_store_id} \
            --user-id $id \
            --query "UserName" \
            --output text
        done
      fi

      echo "=========================================================="
      echo ""
      %{endfor~}
EOT
  }
}











```
