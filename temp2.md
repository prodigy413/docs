```
aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com
aws organizations list-aws-service-access-for-organization
aws cloudtrail register-organization-delegated-admin --member-account-id 111111111



# Get the organization data
data "aws_organizations_organization" "org" {}



locals {
  root_id = data.aws_organizations_organization.org.roots[0].id

  root_ous = {
    for k, v in var.organizational_units : k => v
    if v.parent_key == null
  }

  child_ous = {
    for k, v in var.organizational_units : k => v
    if v.parent_key != null
  }
}

# root OU
resource "aws_organizations_organizational_unit" "root_ou" {
  for_each = local.root_ous

  name      = each.value.name
  parent_id = local.root_id
}

# child OU
resource "aws_organizations_organizational_unit" "child_ou" {
  for_each = local.child_ous

  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.root_ou[each.value.parent_key].id
}

locals {
  all_ou_ids = merge(
    { for k, v in aws_organizations_organizational_unit.root_ou : k => v.id },
    { for k, v in aws_organizations_organizational_unit.child_ou : k => v.id }
  )
}

resource "aws_organizations_account" "account" {
  for_each = var.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = local.all_ou_ids[each.value.ou_key]
  role_name = each.value.role_name
  tags      = each.value.tags

  close_on_deletion = false
}

resource "terraform_data" "run_script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "python3 get_account_list.py"
  }

  depends_on = [aws_organizations_account.account]
}





# OUs
organizational_units = {
  security = {
    name       = "security"
    parent_key = null
  }

  infrastructure = {
    name       = "infrastructure"
    parent_key = null
  }

  workload = {
    name       = "workload"
    parent_key = null
  }

  production = {
    name       = "production"
    parent_key = "workload"
  }

  staging = {
    name       = "staging"
    parent_key = "workload"
  }

  common = {
    name       = "common"
    parent_key = "workload"
  }
}

accounts = {
  audit = {
    name   = "audit"
    email  = "test05@test.com"
    ou_key = "security"
    tags = {
      "Environment" = "Common"
      "AccountType" = "Security"
      "Owner"       = "Kiban"
    }
  }

  log_archive = {
    name   = "log-archive"
    email  = "test06@test.com"
    ou_key = "security"
    tags = {
      "Environment" = "Common"
      "AccountType" = "Security"
      "Owner"       = "Kiban"
    }
  }

  #infrastructure = {
  #  name   = "infrastructure"
  #  email  = "test07@test.com"
  #  ou_key = "infrastructure"
  #  tags = {
  #    "Environment" = "Common"
  #    "AccountType" = "Infrastructure"
  #    "Owner"       = "Kiban"
  #  }
  #}
}






variable "organizational_units" {
  description = "OU definition"
  type = map(object({
    name       = string
    parent_key = optional(string)
  }))
}

variable "accounts" {
  description = "Account definition"
  type = map(object({
    name      = string
    email     = string
    ou_key    = string
    role_name = optional(string, "OrganizationAccountAccessRole")
    tags      = optional(map(string), {})
  }))

  #validation {
  #  condition = alltrue([
  #    for k, v in var.accounts : contains(keys(var.organizational_units), v.ou_key)
  #  ])
  #  error_message = "accounts[*].ou_key must match a key in organizational_units."
  #}
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

provider "aws" {
  region = "ap-northeast-1"
}










# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

locals {
  root_id = data.aws_organizations_organization.org.roots[0].id
}
/*
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
*/

resource "aws_organizations_organizational_unit" "test" {
  name      = "test"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "test01" {
  name      = "test01"
  parent_id = aws_organizations_organizational_unit.test.id
}

resource "terraform_data" "run_script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
aws organizations move-account \
  --account-id 11111111 \
  --source-parent-id ${data.aws_organizations_organization.org.roots[0].id} \
  --destination-parent-id ${aws_organizations_organizational_unit.test01.id} && \
python3 get_account_list.py
EOT
  }

  #  depends_on = [
  #    aws_organizations_organizational_unit.security,
  #    aws_organizations_organizational_unit.infra,
  #    aws_organizations_organizational_unit.workload,
  #    aws_organizations_organizational_unit.evs,
  #    aws_organizations_organizational_unit.test01,
  #  ]

  depends_on = [aws_organizations_organizational_unit.test01]
}





############################
# IAM Identity Center instance
############################
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
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

  target_id   = "11111" # management account ID
  target_type = "AWS_ACCOUNT"
}

# Audit account
resource "aws_ssoadmin_account_assignment" "audit_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = "22222" # audit account ID
  target_type = "AWS_ACCOUNT"
}

# Log archive account
resource "aws_ssoadmin_account_assignment" "logarchive_kiban_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = aws_identitystore_group.kiban_admin.group_id
  principal_type = "GROUP"

  target_id   = "33333" # log archive account ID
  target_type = "AWS_ACCOUNT"
}
/*
# EVS account
resource "aws_ssoadmin_account_assignment" "evs_bk_workload_operator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_operator.arn

  principal_id   = aws_identitystore_group.bk.group_id
  principal_type = "GROUP"

  target_id   = "444444444444" # EVS account ID
  target_type = "AWS_ACCOUNT"
}
*/






```
