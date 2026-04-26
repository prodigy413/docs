- CloudTrail
```
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

########################################
# Providers
########################################

# Default provider (Management account)
provider "aws" {
  region  = "ap-northeast-1"
  profile = "management"
}

# Management account
provider "aws" {
  alias  = "management"
  region = "ap-northeast-1"

  profile = "management"
}

# Audit account
provider "aws" {
  alias  = "audit"
  region = "ap-northeast-1"

  profile = "audit"
}

# LogArchive account
provider "aws" {
  alias  = "logarchive"
  region = "ap-northeast-1"

  profile = "log-archive"
}






data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_caller_identity" "audit" {
  provider = aws.audit
}

data "aws_organizations_organization" "this" {
  provider = aws.management
}





########################################
# Variable
########################################

locals {
  trail_name  = "org-audit-trail"
  home_region = "ap-northeast-1"
  s3_prefix   = "cloudtrail"

  # S3 bucket name はグローバル一意にする必要があります
  cloudtrail_bucket_name = "obi-test-cmn-management-logs"

  # Organization Trail の ARN は Management Account ID を使う
  # organization_trail_arn = "arn:aws:cloudtrail:${local.home_region}:${data.aws_caller_identity.management.account_id}:trail/${local.trail_name}"
}

########################################
# Enable CloudTrail trusted access
# Management account only
########################################

resource "aws_organizations_aws_service_access" "this" {
  provider = aws.management

  service_principal = "cloudtrail.amazonaws.com"
}

########################################
# Register CloudTrail delegated administrator
# Management account only
########################################

resource "aws_cloudtrail_organization_delegated_admin_account" "audit" {
  provider = aws.management

  account_id = data.aws_caller_identity.audit.account_id

  depends_on = [aws_organizations_aws_service_access.this]
}

########################################
# S3 bucket for CloudTrail logs
# LogArchive account
########################################

resource "aws_s3_bucket" "cloudtrail_logs" {
  provider = aws.logarchive

  bucket        = local.cloudtrail_bucket_name
  force_destroy = true
}

#resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
#  provider = aws.logarchive
#
#  bucket = aws_s3_bucket.cloudtrail_logs.id
#
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  provider = aws.logarchive

  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

#resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
#  provider = aws.logarchive
#
#  bucket = aws_s3_bucket.cloudtrail_logs.id
#
#  rule {
#    apply_server_side_encryption_by_default {
#      sse_algorithm = "AES256"
#    }
#  }
#}

#resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
#  provider = aws.logarchive
#
#  bucket = aws_s3_bucket.cloudtrail_logs.id
#
#  rule {
#    object_ownership = "BucketOwnerPreferred"
#  }
#}

########################################
# S3 bucket policy for Organization CloudTrail
# LogArchive account
########################################

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
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
      aws_s3_bucket.cloudtrail_logs.arn,
      "${aws_s3_bucket.cloudtrail_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AWSBucketPermissionsCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.cloudtrail_logs.arn
    ]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.cloudtrail_logs.arn
    ]
  }

  statement {
    sid    = "AWSBucketDeliveryForOrganizationTrail"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      # Account-level trail 互換用
      "${aws_s3_bucket.cloudtrail_logs.arn}/${local.s3_prefix}/AWSLogs/${data.aws_caller_identity.management.account_id}/*",

      # Organization trail 用
      "${aws_s3_bucket.cloudtrail_logs.arn}/${local.s3_prefix}/AWSLogs/${data.aws_organizations_organization.this.id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [data.aws_organizations_organization.this.id]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  provider = aws.logarchive

  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

########################################
# Organization CloudTrail
# Created and managed from Audit account
########################################

resource "aws_cloudtrail" "organization" {
  provider = aws.audit

  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  s3_key_prefix = local.s3_prefix

  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true

  enable_logging             = true
  enable_log_file_validation = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_cloudtrail_organization_delegated_admin_account.audit,
    aws_s3_bucket_policy.cloudtrail_logs
  ]
}
```

```
aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com
aws organizations list-aws-service-access-for-organization
aws cloudtrail register-organization-delegated-admin --member-account-id 578673726609
```

```
aws cloudtrail describe-trails --profile management
aws s3 ls --profile management

aws cloudtrail describe-trails --profile audit
aws s3 ls --profile audit

aws cloudtrail describe-trails --profile log-archive
aws s3 ls --profile log-archive

aws cloudtrail describe-trails --profile infra
aws s3 ls --profile infra
```

- Account Import
```
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}






# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

import {
  to = aws_organizations_account.management
  id = "11111"
}

import {
  to = aws_organizations_account.infrastructure
  id = "411111"
}

import {
  to = aws_organizations_account.audit
  id = "511111"
}

import {
  to = aws_organizations_account.log-archive
  id = "11111111"
}
```

```
terraform init
terraform plan -generate-config-out=account.tf
```

- Account
```
# Get the organization data
data "aws_organizations_organization" "org" {}





import json
import subprocess


def aws_cli(cmd):
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=True
    )
    return json.loads(result.stdout)


def get_organization():
    return aws_cli([
        "aws", "organizations", "describe-organization", "--output", "json"
    ])["Organization"]


def get_roots():
    data = aws_cli(["aws", "organizations", "list-roots", "--output", "json"])
    return data.get("Roots", [])


def get_child_ous(parent_id):
    data = aws_cli([
        "aws", "organizations", "list-organizational-units-for-parent",
        "--parent-id", parent_id,
        "--output", "json"
    ])
    return sorted(data.get("OrganizationalUnits", []), key=lambda x: x["Name"])


def get_child_accounts(parent_id):
    data = aws_cli([
        "aws", "organizations", "list-accounts-for-parent",
        "--parent-id", parent_id,
        "--output", "json"
    ])
    return sorted(data.get("Accounts", []), key=lambda x: x["Name"])


def print_tree(parent_id, management_account_id=None, is_root=False, prefix=""):
    ous = get_child_ous(parent_id)
    accounts = get_child_accounts(parent_id)

    if is_root and management_account_id:
        mgmt_accounts = [a for a in accounts if a["Id"] == management_account_id]
        other_accounts = [a for a in accounts if a["Id"] != management_account_id]

        items = (
            [("account", a) for a in mgmt_accounts] +
            [("ou", ou) for ou in ous] +
            [("account", a) for a in other_accounts]
        )
    else:
        items = [("ou", ou) for ou in ous] + [("account", ac) for ac in accounts]

    for i, (kind, item) in enumerate(items):
        is_last = (i == len(items) - 1)
        branch = "└── " if is_last else "├── "
        next_prefix = prefix + ("    " if is_last else "│   ")

        if kind == "ou":
            print(f"{prefix}{branch}{item['Name']}")
            print_tree(item["Id"], management_account_id, False, next_prefix)
        else:
            print(f"{prefix}{branch}{item['Name']} [{item['Id']}]")


def main():
    org = get_organization()
    management_account_id = org["MasterAccountId"]

    roots = get_roots()
    for root in roots:
        print(root["Name"])
        print_tree(root["Id"], management_account_id, True)


if __name__ == "__main__":
    main()





# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

locals {
  root_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "security"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "infra" {
  name      = "infrastructure"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workload" {
  name      = "workload"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "evs" {
  name      = "evs"
  parent_id = aws_organizations_organizational_unit.workload.id
}

resource "aws_organizations_organizational_unit" "rosa-prd" {
  name      = "rosa-prd"
  parent_id = aws_organizations_organizational_unit.workload.id
}

resource "aws_organizations_organizational_unit" "rosa-stg" {
  name      = "rosa-stg"
  parent_id = aws_organizations_organizational_unit.workload.id
}

resource "aws_organizations_account" "management" {
  email = "zerozero413@gmail.com"
  name  = "management"

  depends_on = [
    aws_organizations_organizational_unit.security,
    aws_organizations_organizational_unit.infra,
    aws_organizations_organizational_unit.workload,
    aws_organizations_organizational_unit.evs,
    aws_organizations_organizational_unit.rosa-prd,
    aws_organizations_organizational_unit.rosa-stg,
  ]
}

resource "aws_organizations_account" "infrastructure" {
  email     = "test04@great-obi.com"
  name      = "infrastructure"
  parent_id = aws_organizations_organizational_unit.infra.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    ManagedBy   = "Kiban"
    Owner       = "Kiban"
  }

  depends_on = [
    aws_organizations_organizational_unit.security,
    aws_organizations_organizational_unit.infra,
    aws_organizations_organizational_unit.workload,
    aws_organizations_organizational_unit.evs,
    aws_organizations_organizational_unit.rosa-prd,
    aws_organizations_organizational_unit.rosa-stg,
  ]
}

resource "aws_organizations_account" "audit" {
  email     = "test05@great-obi.net"
  name      = "audit"
  parent_id = aws_organizations_organizational_unit.security.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [
    aws_organizations_organizational_unit.security,
    aws_organizations_organizational_unit.infra,
    aws_organizations_organizational_unit.workload,
    aws_organizations_organizational_unit.evs,
    aws_organizations_organizational_unit.rosa-prd,
    aws_organizations_organizational_unit.rosa-stg,
  ]
}

resource "aws_organizations_account" "log-archive" {
  email     = "test06@great-obi.net"
  name      = "log-archive"
  parent_id = aws_organizations_organizational_unit.security.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [
    aws_organizations_organizational_unit.security,
    aws_organizations_organizational_unit.infra,
    aws_organizations_organizational_unit.workload,
    aws_organizations_organizational_unit.evs,
    aws_organizations_organizational_unit.rosa-prd,
    aws_organizations_organizational_unit.rosa-stg,
  ]
}

resource "terraform_data" "run_script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "python3 get_account_list.py"
  }

  depends_on = [
    aws_organizations_account.management,
    aws_organizations_account.infrastructure,
    aws_organizations_account.audit,
    aws_organizations_account.log-archive
  ]
}

```

- Group
```
############################
# IAM Identity Center instance
############################
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}





# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

############################
# Groups
############################
resource "aws_identitystore_group" "kiban_admin" {
  identity_store_id = local.identity_store_id
  display_name      = "kiban-admin"
  description       = "Platform team admin group with AWS administrator privileges"
}

resource "aws_identitystore_group" "kiban" {
  identity_store_id = local.identity_store_id
  display_name      = "kiban"
  description       = "Platform team group"
}

resource "aws_identitystore_group" "bk" {
  identity_store_id = local.identity_store_id
  display_name      = "bk"
  description       = "bk team group"
}

############################
# Permission Sets
############################
resource "aws_ssoadmin_permission_set" "organization_admin" {
  instance_arn     = local.instance_arn
  name             = "organization-admin"
  description      = "Organization-wide administrator"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set" "workload_operator" {
  instance_arn     = local.instance_arn
  name             = "workload-operator"
  description      = "Workload operator"
  session_duration = "PT8H"
}

############################
# Managed Policy Attachments
############################
resource "aws_ssoadmin_managed_policy_attachment" "organization_admin_adminaccess" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "workload_operator_poweruser" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_operator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

############################
# Inline policy document for workload-operator
############################
data "aws_iam_policy_document" "workload_operator_inline" {
  statement {
    sid    = "DenySecurityAuditAndGovernanceServices"
    effect = "Deny"

    actions = [
      "cloudtrail:*",
      "config:*",
      "securityhub:*",
      "guardduty:*",
      "detective:*",
      "inspector:*",
      "inspector2:*",
      "macie2:*",
      "securitylake:*",
      "auditmanager:*",
      "access-analyzer:*",
      "fms:*",
      "artifact:*",
      "organizations:*",
      "account:*",
      "sso:*",
      "sso-directory:*",
      "identitystore:*"
    ]

    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "workload_operator_inline" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_operator.arn
  inline_policy      = data.aws_iam_policy_document.workload_operator_inline.json
}

############################
# Account Assignments
############################

# Management account
resource "aws_ssoadmin_account_assignment" "management_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = "8111111111" # management account ID
  target_type = "AWS_ACCOUNT"
}

# Audit account
resource "aws_ssoadmin_account_assignment" "audit_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = "11111111119" # audit account ID
  target_type = "AWS_ACCOUNT"
}

# Log archive account
resource "aws_ssoadmin_account_assignment" "logarchive_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = "91111111111" # log archive account ID
  target_type = "AWS_ACCOUNT"
}

# EVS account
resource "aws_ssoadmin_account_assignment" "evs_bk_workload_operator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_operator.arn

  principal_id   = aws_identitystore_group.bk.group_id
  principal_type = "GROUP"

  target_id   = "41111111111" # EVS account ID
  target_type = "AWS_ACCOUNT"
}

```

- User
```
import csv
import subprocess
import sys
import shutil
import os

# Variables
CSV_FILE = "users.csv"
REQUIRED_HEADER = ["firstname", "lastname", "username", "group"]
REQUIRED_CMDS = ["python3", "aws", "terraform"]


def run_aws_cmd(cmd):
    """Execute a subprocess command and return the result. Exit the script on error."""
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return res
    except Exception as e:
        print(f"Error: Command execution failed. {e}")
        sys.exit(1)


def main():
    # 1. 環境チェック (コマンド存在確認)
    for cmd in REQUIRED_CMDS:
        if not shutil.which(cmd):
            print(f"Error: Command '{cmd}' not found in PATH.")
            sys.exit(1)

    if not os.path.exists(CSV_FILE):
        print(f"Error: CSV file '{CSV_FILE}' not found.")
        sys.exit(1)

    # --- CSVデータの読み込みと事前バリデーション ---
    user_data = []
    with open(CSV_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader, None)

        if header != REQUIRED_HEADER:
            print(f"Error: CSV header must be exactly {REQUIRED_HEADER}")
            sys.exit(1)

        for line_num, row in enumerate(reader, start=2):
            if not any(row): continue  # 空行スキップ
            if len(row) != 4:
                print(f"Error: Invalid column count at line {line_num}")
                sys.exit(1)

            # --- 全値のスペース・空文字チェック (AWS確認前) ---
            for i, val in enumerate(row):
                # 空文字チェック
                if not val or val.strip() == "":
                    print(f"Error: Empty value detected at line {line_num}, column '{REQUIRED_HEADER[i]}'")
                    sys.exit(1)
                # スペースチェック
                if " " in val or "　" in val:
                    print(f"Error: Space detected in value '{val}' at line {line_num}")
                    sys.exit(1)

            user_data.append({"line": line_num, "row": row})

    # --- 2. AWS Identity Store ID の取得 ---
    # バリデーションが通ったので、AWSへの通信を開始
    instance_res = run_aws_cmd([
        "aws", "sso-admin", "list-instances", 
        "--query", "Instances[0].IdentityStoreId", 
        "--output", "text"
    ])
    
    identity_store_id = instance_res.stdout.strip()
    if instance_res.returncode != 0 or not identity_store_id or identity_store_id == "None":
        print(f"Error: Failed to retrieve Identity Store ID. {instance_res.stderr.strip()}")
        sys.exit(1)

    # --- 3. ユーザーとグループの存在確認 ---
    for item in user_data:
        line_num = item["line"]
        firstname, lastname, username, group_str = item["row"]

        # グループの分割確認 (セミコロン区切り)
        groups = group_str.split(';')
        for group in groups:
            group_filter = f'{{"UniqueAttribute":{{"AttributePath":"DisplayName","AttributeValue":"{group}"}}}}'
            group_res = run_aws_cmd([
                "aws", "identitystore", "get-group-id",
                "--identity-store-id", identity_store_id,
                "--alternate-identifier", group_filter
            ])
            
            if group_res.returncode != 0:
                print(f"Error: Group '{group}' does not exist in IAM Identity Center (Line {line_num}).")
                sys.exit(1)

        # ユーザーの重複確認
        user_filter = f'{{"UniqueAttribute":{{"AttributePath":"UserName","AttributeValue":"{username}"}}}}'
        user_res = run_aws_cmd([
            "aws", "identitystore", "get-user-id",
            "--identity-store-id", identity_store_id,
            "--alternate-identifier", user_filter
        ])
        if user_res.returncode == 0:
            print(f"Error: User '{username}' already exists (Line {line_num}).")
            sys.exit(1)

    print("All syntax and existence checks passed successfully.")


if __name__ == "__main__":
    main()





# IAM Identity Center instance / identity store information retrieval
data "aws_ssoadmin_instances" "this" {}





# Pythonスクリプトの実行 (事前チェック)
resource "terraform_data" "run_script" {
  provisioner "local-exec" {
    command = "python3 checker.py"
  }

  triggers_replace = {
    always_run = timestamp()
  }
}

# Variables
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

# Retrieve existing group IDs
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

# Create users
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

# Assign users to groups
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

# Get user lists
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





firstname,lastname,username,group
Jun,Kazama,user03@test.com,SuperAdmin;operator
Forest,Law,user04@test.com,SuperAdmin
Marshall,Law,user05@test.com,test

```

### アカウント

- management
- audit
- log-archive
- infrastructure
- evs-common

### SCP

- 

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

### 流れ

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - Managementアカウント追加
- アカウント追加
  - アカウントを招待
    ```
    aws organizations invite-account-to-organization \
      --target Id=greatobi413@gmail.com,Type=EMAIL \
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
    aws cloudtrail register-organization-delegated-admin --member-account-id 578673726609
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

