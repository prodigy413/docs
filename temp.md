- modules/config-recorder
```
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
# AWS Config Service-linked role
#
# This creates:
# arn:aws:iam::<account-id>:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig
#
# The AWS managed policy below is attached by AWS automatically:
# arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy
########################################
resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

########################################
# AWS Config Configuration Recorder
########################################
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
      days          = 360
      storage_class = "GLACIER"
    }

    expiration {
      days = 1800
    }

    noncurrent_version_expiration {
      noncurrent_days = 360
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
# Enable Security Hub
########################################
resource "aws_securityhub_account" "management" {
  provider = aws.management

  enable_default_standards = false
}

########################################
# management account
# Enable AWS Config trusted access for Organizations
########################################
resource "aws_organizations_aws_service_access" "securityhub" {
  provider = aws.management

  service_principal = "securityhub.amazonaws.com"

  depends_on = [
    aws_securityhub_account.audit
  ]
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
      "arn:aws:securityhub:${local.home_region}::standards/cis-aws-foundations-benchmark/v/5.0.0"
    ]

    security_controls_configuration {
      disabled_control_identifiers = [
        # example: disable EC2.10 and S3.5 controls
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

########################################
# Run script to get config and cspm info
########################################
resource "terraform_data" "run-script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "python3 get-config_cspm.py"
  }

  depends_on = [
    aws_securityhub_configuration_policy_association.root
  ]
}





get-config_cspm.py
import subprocess
import json

REGION = "ap-northeast-1"

PROFILES = [
    "management",
    "infrastructure",
    "audit",
    "log-archive",
    "evs",
    "system-prd",
    "system-stg",
]

MANAGEMENT = "management"
AUDIT = "audit"
LOG_ARCHIVE = "log-archive"


def aws(profile, args, region=REGION):
    cmd = ["aws"] + args + ["--profile", profile, "--output", "json", "--no-cli-pager"]

    if region:
        cmd += ["--region", region]

    r = subprocess.run(cmd, text=True, capture_output=True)

    if r.returncode != 0:
        return None

    return json.loads(r.stdout) if r.stdout.strip() else {}


def account_id(profile):
    r = aws(profile, ["sts", "get-caller-identity"], region=None)
    return r["Account"] if r else "ERROR"


def config_enabled(profile):
    r = aws(profile, ["configservice", "describe-configuration-recorder-status"])

    if not r:
        return False

    return any(
        x.get("recording") is True
        for x in r.get("ConfigurationRecordersStatus", [])
    )


def securityhub_enabled(profile):
    r = aws(profile, ["securityhub", "describe-hub"])
    return r is not None


def config_delegated_admin(audit_id):
    r = aws(
        MANAGEMENT,
        [
            "organizations",
            "list-delegated-administrators",
            "--service-principal",
            "config.amazonaws.com",
        ],
        region=None,
    )

    if not r:
        return False

    return any(
        x.get("Id") == audit_id
        for x in r.get("DelegatedAdministrators", [])
    )


def securityhub_delegated_admin(audit_id):
    r = aws(
        MANAGEMENT,
        [
            "securityhub",
            "list-organization-admin-accounts",
            "--feature",
            "SecurityHub",
        ],
    )

    if not r:
        return False

    return any(
        x.get("AccountId") == audit_id and x.get("Status") == "ENABLED"
        for x in r.get("AdminAccounts", [])
    )


def log_archive_buckets_exist():
    r = aws(LOG_ARCHIVE, ["s3api", "list-buckets"], region=None)

    if not r:
        return False

    return bool(r.get("Buckets"))


audit_id = account_id(AUDIT)

print("=== Account Check ===")
for p in PROFILES:
    aid = account_id(p)
    cfg = config_enabled(p)
    sh = securityhub_enabled(p)

    print(f"{p} AccountId: {aid}")
    print(f"- Config: {cfg}")
    print(f"- SecurityHubCSPM: {sh}")
    print()

print("=== Delegated Admin Check ===")
print(f"Config audit delegated admin: {config_delegated_admin(audit_id)}")
print(f"SecurityHub audit delegated admin: {securityhub_delegated_admin(audit_id)}")

print()
print("=== log-archive S3 Check ===")
print(f"S3 bucket exists: {log_archive_buckets_exist()}")





########################################
# Variable
########################################

locals {
  audit_account_id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "audit"
  ][0]

  # AWS Config Bucket Name
  config_bucket_name = "mbt-config-logs-01"

  # Security Hub CSPM Home Region
  home_region = "ap-northeast-1"

  # When you want to enable Security Hub CSPM in multiple regions, you can specify the linked regions here.
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
```

- rule
```
########################################
# audit account:
# Organization Config Rules
########################################
resource "aws_config_organization_managed_rule" "cloudtrail_enabled" {
  provider = aws.audit

  name              = "cloudtrail-enabled"
  rule_identifier   = "CLOUD_TRAIL_ENABLED"
  excluded_accounts = [local.mgmt_account_id]
}

resource "aws_config_organization_managed_rule" "securityhub_enabled" {
  provider = aws.audit

  name              = "securityhub-enabled"
  rule_identifier   = "SECURITYHUB_ENABLED"
  excluded_accounts = [local.mgmt_account_id]
}

resource "aws_config_organization_managed_rule" "root_account_mfa_enabled" {
  provider = aws.audit

  name              = "root-account-mfa-enabled"
  rule_identifier   = "ROOT_ACCOUNT_MFA_ENABLED"
  excluded_accounts = [local.mgmt_account_id]
}

resource "aws_config_organization_managed_rule" "iam_user_mfa_enabled" {
  provider = aws.audit

  name              = "iam-user-mfa-enabled"
  rule_identifier   = "IAM_USER_MFA_ENABLED"
  excluded_accounts = [local.mgmt_account_id]
}

resource "aws_config_organization_managed_rule" "iam_password_policy" {
  provider = aws.audit

  name              = "iam-password-policy"
  rule_identifier   = "IAM_PASSWORD_POLICY"
  excluded_accounts = [local.mgmt_account_id]

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

########################################
# management account:
# Config Rules
########################################
resource "aws_config_config_rule" "management_cloudtrail_enabled" {
  provider = aws.management

  name = "cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "management_securityhub_enabled" {
  provider = aws.management

  name = "securityhub-enabled"

  source {
    owner             = "AWS"
    source_identifier = "SECURITYHUB_ENABLED"
  }
}

resource "aws_config_config_rule" "management_root_account_mfa_enabled" {
  provider = aws.management

  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "management_iam_user_mfa_enabled" {
  provider = aws.management

  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "management_iam_password_policy" {
  provider = aws.management

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





data "aws_organizations_organization" "current" {
  provider = aws.management
}





########################################
# Variable
########################################

locals {
  mgmt_account_id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "management"
  ][0]
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

```

