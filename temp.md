```
resource "aws_organizations_account" "management" {
  email     = "root@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "management"
    Environment = "common"
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
    Environment = "common"
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
    Environment = "common"
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
    Environment = "common"
    ManagedBy   = "mck"
    Owner       = "nk/mck"
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
    Environment = "production"
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
    Environment = "staging"
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
    Environment = "common"
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
    nk        = "Network Kiban Team"
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
    infra-bk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["bk"].group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
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
    # nk
    ############################
    infra-nk = {
      permission_set = aws_ssoadmin_permission_set.this["workload-operator"].arn
      group_id       = aws_identitystore_group.this["nk"].group_id
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
