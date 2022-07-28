~~~
iam_password_policy.tf

##############################
# 全環境が同じ設定を利用するため、modules配下で定義した設定をそのまま利用する。
# そのため、ここでは別途変数設定をしない。
##############################
module "iam_password_policy" {
  source = "../modules/iam_password_policy"
}








resource "aws_iam_account_password_policy" "password_policy" {
  minimum_password_length        = var.minimum_password_length
  require_uppercase_characters   = var.require_uppercase_characters
  require_lowercase_characters   = var.require_lowercase_characters
  require_numbers                = var.require_numbers
  require_symbols                = var.require_symbols
  max_password_age               = var.max_password_age
  hard_expiry                    = var.hard_expiry
  allow_users_to_change_password = var.allow_users_to_change_password
  password_reuse_prevention      = var.password_reuse_prevention
}







variable "minimum_password_length" {
  description = "パスワードの最小文字数"
  type        = number
  default     = 12
}

variable "require_uppercase_characters" {
  description = "1文字以上のアルファベット大文字が必要"
  type        = bool
  default     = true
}

variable "require_lowercase_characters" {
  description = "1文字以上のアルファベット小文字が必要"
  type        = bool
  default     = true
}

variable "require_numbers" {
  description = "1つ以上の数字が必要"
  type        = bool
  default     = true
}

variable "require_symbols" {
  description = "1つ以上の英数字以外の文字が必要"
  type        = bool
  default     = false
}

variable "max_password_age" {
  description = "パスワードの有効期限"
  type        = number
  default     = 90
}

variable "hard_expiry" {
  description = "パスワードの有効期限が切れたら管理者のリセットが必要"
  type        = bool
  default     = false
}

variable "allow_users_to_change_password" {
  description = "ユーザーにパスワード変更を許可"
  type        = bool
  default     = true
}

variable "password_reuse_prevention" {
  description = "パスワードの再利用を禁止する世代数"
  type        = number
  default     = 3
}

~~~
