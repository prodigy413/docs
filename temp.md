~~~
##############################
# Backup_01
##############################
/*
module "backup_01" {
  source = "../modules"

  backup_vault_name            = "obi-test-vault"
  backup_plan_name             = "obi-test-plan"
  backup_rule_name             = "obi-test-rule"
  backup_schedule              = "cron(15 12 * * ? *)"
  #backup_schedule              = "cron(0 16 * * ? *)"
  start_window                 = 60
  completion_window            = 300
  delete_after             = 7
  #copy_action_delete_after = 7
  backup_selection_name     = "obi-test-resource-assignment"
  backup_selection_role_arn = aws_iam_role.role_01.arn
  target_resource_arn          = ["arn:aws:rds:*:*:db:*"]
  #target_resource_arn          = ["arn:aws:elasticfilesystem:*:*:file-system/*"]
  #destination_vault_arn        = module.backup_02.valut_arn
  #enable_copy_action           = true
  #selection_tag = [{
  #      type       = "STRINGEQUALS"
  #  key = "AWSBackup"
  #  value = "managed"
  #}]
}

output "backup_01_valut_id" {
  value = module.backup_01.valut_id
}

output "backup_01_valut_arn" {
  value = module.backup_01.valut_arn
}
*/

##############################
# Backup_02
##############################
module "backup_02" {
  source = "../modules"

  backup_vault_name         = "obi-test-vault-efs"
  backup_plan_name          = "obi-test-plan-efs"
  backup_rule_name          = "obi-test-rule-efs"
  backup_schedule           = "cron(25 10 * * ? *)"
  start_window              = 60
  completion_window         = 120
  delete_after              = 7
  backup_selection_name     = "obi-test-resource-assignment"
  backup_selection_role_arn = aws_iam_role.role_01.arn
  target_resource_arn       = ["arn:aws:elasticfilesystem:*:*:file-system/*"]
  selection_tag = [{
    key   = "AWSBackup"
    value = "managed"
  }]
}

output "backup_02_valut_id" {
  value = module.backup_02.valut_id
}

output "backup_02_valut_arn" {
  value = module.backup_02.valut_arn
}

##############################
# Backup_02
##############################
/*
module "backup_02" {
  source = "../modules"

  providers = {
    aws = aws.osaka
  }

  backup_vault_name          = "obi-test-vault-02"
  enable_backup_plan         = false
  enable_backup_selection = false
}

output "backup_02_valut_id" {
  value = module.backup_02.valut_id
}

output "backup_02_valut_arn" {
  value = module.backup_02.valut_arn
}
*/











data "aws_iam_policy_document" "sts_01" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_01" {
  name                  = "backup-role-01"
  assume_role_policy    = data.aws_iam_policy_document.sts_01.json
}

resource "aws_iam_role_policy_attachment" "policy_attach_01" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.role_01.name
}

resource "aws_iam_role_policy_attachment" "policy_attach_02" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.role_01.name
}



















##############################
# Vault
##############################
resource "aws_backup_vault" "backup" {
  name = var.backup_vault_name

  tags = merge(
    {
      Name = var.backup_vault_name
    },
    var.terraform_tag
  )
}

##############################
# Backup Plan
##############################

# Backup Plan Only
resource "aws_backup_plan" "backup_only" {
  count = var.enable_backup_plan && !var.enable_copy_action ? 1 : 0

  name = var.backup_plan_name

  rule {
    rule_name           = var.backup_rule_name
    target_vault_name   = aws_backup_vault.backup.name
    schedule            = var.backup_schedule
    start_window        = var.start_window
    completion_window   = var.completion_window
    recovery_point_tags = var.recovery_point_tags

    lifecycle {
      delete_after = var.delete_after
    }
  }

  tags = merge(
    {
      Name = var.backup_plan_name
    },
    var.terraform_tag
  )
}

# Backup Plan + Copy Action
resource "aws_backup_plan" "backup_with_copy_action" {
  count = var.enable_backup_plan && var.enable_copy_action ? 1 : 0

  name = var.backup_plan_name

  rule {
    rule_name         = var.backup_rule_name
    target_vault_name = aws_backup_vault.backup.name
    schedule          = var.backup_schedule
    start_window      = var.start_window
    completion_window = var.completion_window

    copy_action {
      destination_vault_arn = var.destination_vault_arn

      lifecycle {
        delete_after = var.copy_action_delete_after
      }
    }

    lifecycle {
      delete_after = var.delete_after
    }
  }

  tags = merge(
    {
      Name = var.backup_plan_name
    },
    var.terraform_tag
  )
}

##############################
# Backup Selection
##############################
data "aws_caller_identity" "current" {}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection
resource "aws_backup_selection" "backup" {
  count = var.enable_backup_selection ? 1 : 0

  iam_role_arn = var.backup_selection_role_arn
  name         = var.backup_selection_name
  plan_id      = var.enable_copy_action ? aws_backup_plan.backup_with_copy_action[0].id : aws_backup_plan.backup_only[0].id
  resources    = var.target_resource_arn

  dynamic "selection_tag" {
    for_each = length(var.selection_tag) != 0 ? var.selection_tag : []
    content {
      type  = "STRINGEQUALS"
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }
}

##############################
# Output
##############################
output "valut_id" {
  value = aws_backup_vault.backup.id
}

output "valut_arn" {
  value = aws_backup_vault.backup.arn
}


















variable "backup_vault_name" {
  description = "Backup Vault名"
  type        = string
}

variable "enable_backup_plan" {
  description = "Backup Plan設定を有効/無効"
  type        = bool
  default     = true
}

variable "enable_copy_action" {
  description = "Copy Action設定を有効/無効"
  type        = bool
  default     = false
}

variable "backup_plan_name" {
  description = "Backup Plan名"
  type        = string
  default     = null
}

variable "backup_rule_name" {
  description = "Backup Rule名"
  type        = string
  default     = null
}

variable "backup_schedule" {
  description = "バックアップスケジュール設定(Cron形式)"
  type        = string
  default     = null
}

variable "start_window" {
  description = "スケジュール時刻から指定時間以内にバックアップ開始"
  type        = number
  default     = null
}

variable "completion_window" {
  description = "スケジュール時刻から指定時間以内にバックアップ完了"
  type        = number
  default     = null
}

variable "delete_after" {
  description = "バックアップの保持期間"
  type        = number
  default     = null
}

variable "copy_action_delete_after" {
  description = "Copy Action用バックアップの保持期間"
  type        = number
  default     = null
}

variable "enable_backup_selection" {
  description = "Backup Selection設定を有効/無効"
  type        = bool
  default     = true
}

variable "backup_selection_name" {
  description = "Backup Selection名"
  type        = string
  default     = null
}

variable "backup_selection_role_arn" {
  description = "Backup Selection用ロールのArn"
  type        = string
  default     = null
}

variable "target_resource_arn" {
  description = "バックアップターゲットのArn"
  type        = list(string)
  default     = null
}

variable "destination_vault_arn" {
  description = "Copy Action用ターゲットValutのArn"
  type        = string
  default     = null
}

variable "recovery_point_tags" {
  description = "Recovery Point用タグ"
  type        = map(string)
  default = {
    BackupPlan = "managed"
  }
}

variable "selection_tag" {
  description = "バックアップ対象用タグ"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}

~~~
