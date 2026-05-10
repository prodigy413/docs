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
  id = "12345678910"
}

import {
  to = aws_organizations_account.infrastructure
  id = "12345678910"
}

import {
  to = aws_organizations_account.audit
  id = "12345678910"
}

import {
  to = aws_organizations_account.log-archive
  id = "12345678910"
}






terraform init
terraform plan -generate-config-out=account.tf

^.*null.*\r?\n





resource "aws_organizations_account" "management" {
  email     = "root@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "infrastructure" {
  email     = "test04@test.com"
  name      = "infrastructure"
  parent_id = aws_organizations_organizational_unit.infra.id
  #parent_id = data.aws_organizations_organization.org.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    ManagedBy   = "testteam"
    Owner       = "testteam"
  }

  depends_on = [aws_organizations_organizational_unit.infra]
}

resource "aws_organizations_account" "log-archive" {
  email     = "test06@test.com"
  name      = "log-archive"
  parent_id = aws_organizations_organizational_unit.security.id
  #parent_id = data.aws_organizations_organization.org.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "testteam"
  }

  depends_on = [aws_organizations_organizational_unit.security]
}

resource "aws_organizations_account" "audit" {
  email     = "test05@test.com"
  name      = "audit"
  parent_id = aws_organizations_organizational_unit.security.id
  #parent_id = data.aws_organizations_organization.org.id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "testteam"
  }

  depends_on = [aws_organizations_organizational_unit.security]
}





############################
# Organization
############################
data "aws_organizations_organization" "org" {}

############################
# IAM Identity Center
############################
data "aws_ssoadmin_instances" "this" {}






import json
import subprocess
from typing import Any, Dict, List


def aws_cli(cmd: List[str]) -> Dict[str, Any]:
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=True
    )

    if not result.stdout.strip():
        return {}

    return json.loads(result.stdout)


########################################
# AWS Organizations
########################################

def get_organization():
    return aws_cli([
        "aws", "organizations", "describe-organization", "--output", "json"
    ])["Organization"]


def get_roots():
    data = aws_cli([
        "aws", "organizations", "list-roots", "--output", "json"
    ])
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


def get_all_accounts():
    data = aws_cli([
        "aws", "organizations", "list-accounts", "--output", "json"
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


########################################
# IAM Identity Center
########################################

def get_identity_center_instance():
    data = aws_cli([
        "aws", "sso-admin", "list-instances", "--output", "json"
    ])

    instances = data.get("Instances", [])

    if not instances:
        raise RuntimeError(
            "IAM Identity Center instance was not found. "
            "Check AWS profile and region."
        )

    if len(instances) > 1:
        print("[WARN] Multiple IAM Identity Center instances found. Using the first one.")

    return instances[0]


def get_identity_center_groups(identity_store_id):
    data = aws_cli([
        "aws", "identitystore", "list-groups",
        "--identity-store-id", identity_store_id,
        "--output", "json"
    ])

    groups = data.get("Groups", [])

    return sorted(groups, key=lambda x: x.get("DisplayName", ""))


def get_permission_sets(instance_arn):
    data = aws_cli([
        "aws", "sso-admin", "list-permission-sets",
        "--instance-arn", instance_arn,
        "--output", "json"
    ])

    return data.get("PermissionSets", [])


def describe_permission_set(instance_arn, permission_set_arn):
    data = aws_cli([
        "aws", "sso-admin", "describe-permission-set",
        "--instance-arn", instance_arn,
        "--permission-set-arn", permission_set_arn,
        "--output", "json"
    ])

    return data["PermissionSet"]


def get_permission_set_aws_managed_policies(instance_arn, permission_set_arn):
    data = aws_cli([
        "aws", "sso-admin", "list-managed-policies-in-permission-set",
        "--instance-arn", instance_arn,
        "--permission-set-arn", permission_set_arn,
        "--output", "json"
    ])

    return data.get("AttachedManagedPolicies", [])


def get_permission_set_customer_managed_policies(instance_arn, permission_set_arn):
    data = aws_cli([
        "aws", "sso-admin", "list-customer-managed-policy-references-in-permission-set",
        "--instance-arn", instance_arn,
        "--permission-set-arn", permission_set_arn,
        "--output", "json"
    ])

    return data.get("CustomerManagedPolicyReferences", [])


def get_permission_set_inline_policy(instance_arn, permission_set_arn):
    data = aws_cli([
        "aws", "sso-admin", "get-inline-policy-for-permission-set",
        "--instance-arn", instance_arn,
        "--permission-set-arn", permission_set_arn,
        "--output", "json"
    ])

    return data.get("InlinePolicy")


def get_permission_set_boundary(instance_arn, permission_set_arn):
    try:
        data = aws_cli([
            "aws", "sso-admin", "get-permissions-boundary-for-permission-set",
            "--instance-arn", instance_arn,
            "--permission-set-arn", permission_set_arn,
            "--output", "json"
        ])
        return data.get("PermissionsBoundary")
    except subprocess.CalledProcessError:
        return None


def get_permission_sets_provisioned_to_account(instance_arn, account_id):
    data = aws_cli([
        "aws", "sso-admin", "list-permission-sets-provisioned-to-account",
        "--instance-arn", instance_arn,
        "--account-id", account_id,
        "--output", "json"
    ])

    return data.get("PermissionSets", [])


def get_account_assignments(instance_arn, account_id, permission_set_arn):
    data = aws_cli([
        "aws", "sso-admin", "list-account-assignments",
        "--instance-arn", instance_arn,
        "--account-id", account_id,
        "--permission-set-arn", permission_set_arn,
        "--output", "json"
    ])

    return data.get("AccountAssignments", [])


def build_group_id_name_map(groups):
    return {
        group["GroupId"]: group.get("DisplayName", group["GroupId"])
        for group in groups
    }


def print_identity_center_groups(groups):
    print("\n")
    print("IAM Identity Center Groups")
    print("==========================")

    if not groups:
        print("No groups found.")
        return

    for group in groups:
        print(f"- {group.get('DisplayName')}")


def print_permission_sets(instance_arn):
    print("\n")
    print("Permission Sets")
    print("===============")

    permission_set_arns = get_permission_sets(instance_arn)

    if not permission_set_arns:
        print("No permission sets found.")
        return {}

    permission_set_name_map = {}

    for ps_arn in permission_set_arns:
        ps = describe_permission_set(instance_arn, ps_arn)
        ps_name = ps["Name"]
        permission_set_name_map[ps_arn] = ps_name

        print(f"\n- {ps_name}")
        print(f"  SessionDuration: {ps.get('SessionDuration', '-')}")
        print(f"  RelayState: {ps.get('RelayState', '-')}")
        print(f"  Description: {ps.get('Description', '-')}")

        aws_managed_policies = get_permission_set_aws_managed_policies(instance_arn, ps_arn)
        customer_managed_policies = get_permission_set_customer_managed_policies(instance_arn, ps_arn)
        inline_policy = get_permission_set_inline_policy(instance_arn, ps_arn)
        permissions_boundary = get_permission_set_boundary(instance_arn, ps_arn)

        print("  AWS Managed Policies:")
        if aws_managed_policies:
            for policy in aws_managed_policies:
                print(f"    - {policy.get('Name')}")
        else:
            print("    - None")

        print("  Customer Managed Policies:")
        if customer_managed_policies:
            for policy in customer_managed_policies:
                path = policy.get("Path", "/")
                name = policy.get("Name")
                print(f"    - {path}{name}")
        else:
            print("    - None")

        print("  Inline Policy:")
        if inline_policy:
            try:
                parsed_policy = json.loads(inline_policy)
                formatted_policy = json.dumps(parsed_policy, indent=4, ensure_ascii=False)
                for line in formatted_policy.splitlines():
                    print(f"    {line}")
            except json.JSONDecodeError:
                for line in inline_policy.splitlines():
                    print(f"    {line}")
        else:
            print("    - None")

        print("  Permissions Boundary:")
        if permissions_boundary:
            print_permissions_boundary_without_arn(permissions_boundary)
        else:
            print("    - None")

    return permission_set_name_map


def print_permissions_boundary_without_arn(permissions_boundary):
    customer_managed_policy_reference = permissions_boundary.get(
        "CustomerManagedPolicyReference"
    )
    managed_policy_arn = permissions_boundary.get("ManagedPolicyArn")

    if customer_managed_policy_reference:
        path = customer_managed_policy_reference.get("Path", "/")
        name = customer_managed_policy_reference.get("Name")
        print(f"    - Customer Managed Policy: {path}{name}")
    elif managed_policy_arn:
        policy_name = managed_policy_arn.split("/")[-1]
        print(f"    - AWS Managed Policy: {policy_name}")
    else:
        print("    - Unknown")


def print_account_group_permission_set_assignments(
    instance_arn,
    accounts,
    group_id_name_map,
    permission_set_name_map
):
    print("\n")
    print("Account Assignments: Groups and Permission Sets")
    print("==============================================")

    for account in accounts:
        account_id = account["Id"]
        account_name = account["Name"]

        provisioned_permission_sets = get_permission_sets_provisioned_to_account(
            instance_arn,
            account_id
        )

        group_assignments = []

        for ps_arn in provisioned_permission_sets:
            assignments = get_account_assignments(
                instance_arn,
                account_id,
                ps_arn
            )

            for assignment in assignments:
                if assignment.get("PrincipalType") != "GROUP":
                    continue

                group_id = assignment.get("PrincipalId")
                group_name = group_id_name_map.get(group_id, group_id)
                ps_name = permission_set_name_map.get(ps_arn, ps_arn)

                group_assignments.append({
                    "GroupName": group_name,
                    "PermissionSetName": ps_name
                })

        print(f"\n- {account_name} [{account_id}]")

        if not group_assignments:
            print("  - No group assignments found.")
            continue

        group_assignments = sorted(
            group_assignments,
            key=lambda x: (x["GroupName"], x["PermissionSetName"])
        )

        for item in group_assignments:
            print(
                f"  - Group: {item['GroupName']} "
                f"=> Permission Set: {item['PermissionSetName']}"
            )


########################################
# Main
########################################

def main():
    org = get_organization()
    management_account_id = org["MasterAccountId"]

    print("AWS Organizations Tree")
    print("======================")

    roots = get_roots()
    for root in roots:
        print(root["Name"])
        print_tree(root["Id"], management_account_id, True)

    instance = get_identity_center_instance()
    instance_arn = instance["InstanceArn"]
    identity_store_id = instance["IdentityStoreId"]

    groups = get_identity_center_groups(identity_store_id)
    group_id_name_map = build_group_id_name_map(groups)

    print_identity_center_groups(groups)

    permission_set_name_map = print_permission_sets(instance_arn)

    accounts = get_all_accounts()

    print_account_group_permission_set_assignments(
        instance_arn=instance_arn,
        accounts=accounts,
        group_id_name_map=group_id_name_map,
        permission_set_name_map=permission_set_name_map
    )


if __name__ == "__main__":
    main()







############################
# Variables
############################
locals {
  root_id           = data.aws_organizations_organization.org.roots[0].id
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

############################
# Organizational Units
############################
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

  target_id   = aws_organizations_account.management.id
  target_type = "AWS_ACCOUNT"
}

# Audit account
resource "aws_ssoadmin_account_assignment" "audit_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.audit.id
  target_type = "AWS_ACCOUNT"
}

# Log archive account
resource "aws_ssoadmin_account_assignment" "logarchive_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.log-archive.id
  target_type = "AWS_ACCOUNT"
}

# EVS account
/*
resource "aws_ssoadmin_account_assignment" "evs_bk_workload_operator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_operator.arn

  principal_id   = aws_identitystore_group.bk.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.evs.id
  target_type = "AWS_ACCOUNT"
}
*/

resource "terraform_data" "run_script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 10 && python3 get_org_info.py"
  }

  depends_on = [
    aws_organizations_account.management,
    aws_organizations_account.infrastructure,
    aws_organizations_account.audit,
    aws_organizations_account.log-archive
  ]
}







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
Kazuya,Mishima,user02@test.com,bk
Jun,Kazama,user03@test.com,kiban;kiban-admin
Forest,Law,user04@test.com,kiban

```
