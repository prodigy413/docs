```
# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

import {
  to = aws_organizations_account.management
  id = "test"
}

import {
  to = aws_organizations_account.infrastructure
  id = "test"
}

import {
  to = aws_organizations_account.audit
  id = "test"
}

import {
  to = aws_organizations_account.evs
  id = "test"
}

import {
  to = aws_organizations_account.system-stg
  id = "test"
}

#import {
#  to = aws_organizations_account.system-prd
#  id = "test"
#}










export AWS_PROFILE=management

terraform init
terraform plan -generate-config-out=account.tf
terraform apply

^.*null.*\r?\n









resource "aws_organizations_account" "management" {
  email     = "root@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "infrastructure" {
  email     = "test04@test.com"
  name      = "infrastructure"
  parent_id = aws_organizations_organizational_unit.root["infra"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    ManagedBy   = "Kiban"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.root["infra"]]
}

resource "aws_organizations_account" "audit" {
  email     = "test05@test.net"
  name      = "audit"
  parent_id = aws_organizations_organizational_unit.root["security"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.root["security"]]
}

resource "aws_organizations_account" "evs" {
  email     = "test06@test.net"
  name      = "evs"
  parent_id = aws_organizations_organizational_unit.workload["common"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  depends_on = [aws_organizations_organizational_unit.workload["common"]]
}

resource "aws_organizations_account" "system-stg" {
  email     = "test07@test.net"
  name      = "system-stg"
  parent_id = aws_organizations_organizational_unit.workload["non-prod"].id
  #parent_id = data.aws_organizations_organization.this.roots[0].id

  depends_on = [aws_organizations_organizational_unit.workload["non-prod"]]
}










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
    organization-admin = {
      name        = "organization-admin"
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
resource "aws_ssoadmin_managed_policy_attachment" "organization-admin-adminaccess" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this["organization-admin"].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "workload-operator-poweruser" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this["workload-operator"].arn
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
  permission_set_arn = aws_ssoadmin_permission_set.this["workload-operator"].arn
  inline_policy      = data.aws_iam_policy_document.workload-operator-inline.json
}

############################
# Account Assignments
############################

locals {
  account_assignments = {
    mgmt-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["organization-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.management.id
    }
    audit-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["organization-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.audit.id
    }
    infra-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["organization-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
    evs-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["organization-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-stg-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.this["organization-admin"].arn
      group_id       = aws_identitystore_group.this["mck-admin"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    evs-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-stg-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    infra-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
    system-stg-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    evs-assist = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["assist"].group_id
      target_id      = aws_organizations_account.evs.id
    }
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











```
