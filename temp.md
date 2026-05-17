```
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}









# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

import {
  to = aws_organizations_account.management
  id = "id"
}

import {
  to = aws_organizations_account.infrastructure
  id = "id"
}

import {
  to = aws_organizations_account.audit
  id = "id"
}

import {
  to = aws_organizations_account.log-archive
  id = "id"
}

import {
  to = aws_organizations_account.rosa-stg
  id = "id"
}








terraform init
terraform plan -generate-config-out=account.tf

^.*null.*\r?\n










resource "aws_organizations_account" "management" {
  email     = "mgmt@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "log-archive" {
  email     = "test06@test.com"
  name      = "log-archive"
  parent_id = aws_organizations_organizational_unit.security.id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.security]
}

resource "aws_organizations_account" "infrastructure" {
  email     = "test04@test.com"
  name      = "infrastructure"
  parent_id = aws_organizations_organizational_unit.infra.id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Security"
    Environment = "Common"
    ManagedBy   = "Kiban"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.infra]
}

resource "aws_organizations_account" "audit" {
  email     = "test05@test.com"
  name      = "audit"
  parent_id = aws_organizations_organizational_unit.security.id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.security]
}

resource "aws_organizations_account" "rosa-stg" {
  email     = "test07@test.com"
  name      = "rosa-stg"
  parent_id = aws_organizations_organizational_unit.rosa-stg.id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  depends_on = [aws_organizations_organizational_unit.rosa-stg]
}








############################
# Organization
############################
data "aws_organizations_organization" "this" {}

############################
# IAM Identity Center
############################
data "aws_ssoadmin_instances" "this" {}






get-org-info.py

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
  root_id           = data.aws_organizations_organization.this.roots[0].id
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
resource "aws_identitystore_group" "mck-admin" {
  identity_store_id = local.identity_store_id
  display_name      = "mck-admin"
  description       = "Platform team admin group with AWS administrator privileges"
}

resource "aws_identitystore_group" "mck" {
  identity_store_id = local.identity_store_id
  display_name      = "mck"
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
resource "aws_ssoadmin_permission_set" "organization-admin" {
  instance_arn     = local.instance_arn
  name             = "organization-admin"
  description      = "Organization-wide administrator"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set" "workload-operator" {
  instance_arn     = local.instance_arn
  name             = "workload-operator"
  description      = "Workload operator"
  session_duration = "PT8H"
}

############################
# Managed Policy Attachments
############################
resource "aws_ssoadmin_managed_policy_attachment" "organization-admin-adminaccess" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization-admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "workload-operator-poweruser" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
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
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn
  inline_policy      = data.aws_iam_policy_document.workload-operator-inline.json
}

############################
# Account Assignments
############################

# Management account
resource "aws_ssoadmin_account_assignment" "management-mck-admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization-admin.arn

  principal_id   = aws_identitystore_group.mck-admin.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.management.id
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.organization-admin,
    aws_identitystore_group.mck-admin,
    aws_organizations_account.management
  ]
}

# Audit account
resource "aws_ssoadmin_account_assignment" "audit-mck-admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization-admin.arn

  principal_id   = aws_identitystore_group.mck-admin.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.audit.id
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.organization-admin,
    aws_identitystore_group.mck-admin,
    aws_organizations_account.audit
  ]
}

# Log archive account
resource "aws_ssoadmin_account_assignment" "log-archive-mck-admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization-admin.arn

  principal_id   = aws_identitystore_group.mck-admin.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.log-archive.id
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.organization-admin,
    aws_identitystore_group.mck-admin,
    aws_organizations_account.log-archive
  ]
}
/*
# EVS account
resource "aws_ssoadmin_account_assignment" "evs-bk-workload-operator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn

  principal_id   = aws_identitystore_group.bk.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.evs.id
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.workload-operator,
    aws_identitystore_group.bk,
    aws_organizations_account.evs
  ]
}
*/
# rosa-stg account
resource "aws_ssoadmin_account_assignment" "rosa-stg-bk-workload-operator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn

  principal_id   = aws_identitystore_group.mck.group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.rosa-stg.id
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.workload-operator,
    aws_identitystore_group.mck,
    aws_organizations_account.rosa-stg
  ]
}

resource "terraform_data" "run-script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 10 && python3 get-org-info.py"
  }

  depends_on = [
    aws_ssoadmin_account_assignment.management-mck-admin,
    aws_ssoadmin_account_assignment.audit-mck-admin,
    aws_ssoadmin_account_assignment.log-archive-mck-admin,
    #aws_ssoadmin_account_assignment.evs-bk-workload-operator,
    aws_ssoadmin_account_assignment.rosa-stg-bk-workload-operator
  ]
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







### 必要アカウント

- AWSアカウント
- Redhatアカウント
  - PersonalではなくCorporateアカウント

### Service Quotas

Regionを確認 > ROSAを構築するRegionでQuotaを増加

- [ROSA-required quotas](https://docs.aws.amazon.com/general/latest/gr/rosa.html#limits_rosa)
- [Service Quotas] > [AWS services]
- [Amazon Elastic Compute Cloud (Amazon EC2)]検索 > [Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances]検索
- [Request increase at account level]クリック > [Increase quota value] > 100 > [Request]
- Support確認
- [Amazon Elastic Block Store (Amazon EBS)]検索 > [Storage for General Purpose SSD (gp3) volumes, in TiB]検索
- [Request increase at account level]クリック > [Increase quota value] > 300 > [Request]
- [Service Quotas] > [AWS のサービス]
- [Amazon Elastic Block Store (Amazon EBS)]検索 > [Storage for General Purpose SSD (gp2) volumes, in TiB]検索
- [アカウントレベルでの引き上げをリクエスト]クリック > [クォータ値を引き上げる] > 300 > [リクエスト]
- [Amazon Elastic Block Store (Amazon EBS)]検索 > [Storage for Provisioned IOPS SSD (io1) volumes, in TiB]検索
- [アカウントレベルでの引き上げをリクエスト]クリック > [クォータ値を引き上げる] > 300 > [リクエスト]

```
