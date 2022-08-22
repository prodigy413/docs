~~~
##############################
# AWS Transfer SFTP
##############################
resource "aws_transfer_server" "sftp" {
  endpoint_type          = "VPC"
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  domain                 = "S3"
  logging_role           = var.logging_role_arn
  security_policy_name   = "TransferSecurityPolicy-2022-03"
  #force_destroy          = true

  endpoint_details {
    vpc_id                 = var.vpc_id
    address_allocation_ids = var.address_allocation_ids
    subnet_ids             = var.subnet_ids
    security_group_ids     = var.security_group_ids
  }
  #endpoint_details {
  #  count = length(var.address_allocation_ids)
  #
  #  vpc_id                 = var.vpc_id
  #  address_allocation_ids = element(var.address_allocation_ids, count.index)
  #  subnet_ids             = element(var.subnet_ids, count.index)
  #  security_group_ids     = var.security_group_ids
  #}

  tags = merge(
    {
      Name = var.name
    },
    var.terraform_tag
  )
}

#aws:transfer:customHostname	sftp2.great-obi.com
#Terraform	managed
#aws:transfer:route53HostedZoneId	/hostedzone/Z03417961RH2K32QYZWNG
#Name	obi-test-sftp-01

##############################
# AWS Transfer User
##############################
resource "aws_transfer_user" "sftp" {
  for_each = var.enable_add_users ? { for user in var.users : user.username => user } : {}

  server_id           = aws_transfer_server.sftp.id
  user_name           = each.value.username
  role                = each.value.user_role_arn
  home_directory_type = each.value.home_directory_type
  home_directory      = each.value.home_directory_type == "PATH" ? "/${var.s3_bucket_id}/${each.value.home_directory}" : null

  dynamic "home_directory_mappings" {
    for_each = each.value.home_directory_type == "LOGICAL" ? [{ target = each.value.home_directory }] : []
    content {
      entry  = "/"
      target = "/${var.s3_bucket_id}/${home_directory_mappings.value.target}"
    }
  }

  tags = merge(
    {
      Name = each.value.username
    },
    var.terraform_tag
  )
}

##############################
# AWS Transfer Key Configuration
##############################
resource "aws_transfer_ssh_key" "sftp" {
  for_each = var.enable_add_users ? { for user in var.users : user.username => user } : {}

  server_id = aws_transfer_server.sftp.id
  user_name = each.value.username
  body      = each.value.public_key

  depends_on = [aws_transfer_user.sftp]
}

output "transfer_server_id" {
  value = aws_transfer_server.sftp.id
}

output "transfer_server_arn" {
  value = aws_transfer_server.sftp.arn
}

output "transfer_server_endpoint" {
  value = aws_transfer_server.sftp.endpoint
}













variable "name" {
  description = "Transfer Server名"
  type        = string
}

variable "vpc_id" {
  description = "使用するVPCのID"
  type        = string
}

variable "address_allocation_ids" {
  description = "Transfer Server用EIPのID"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Transfer Server用SubnetのID"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Transfer Server用セキュリティグループのID"
  type        = list(string)
}

variable "logging_role_arn" {
  description = "Transfer Serverログ用ロールのArn"
  type        = string
}

variable "enable_add_users" {
  description = "SFTPユーザー追加設定を有効/無効"
  type        = bool
  default     = true
}

variable "users" {
  description = "SFTPユーザーのユーザー名とユーザー用ロールのArn)"
  type = list(object({
    username            = string
    user_role_arn       = string
    public_key          = string
    home_directory_type = string
    home_directory      = string
  }))
  validation {
    condition     = alltrue([for k in var.users : contains(["LOGICAL", "PATH"], k.home_directory_type)])
    error_message = "Valid value is:\nLOGICAL\nPATH"
  }
  default = []
}

variable "s3_bucket_id" {
  description = "Transfer Server用S3バケットのID"
  type        = string
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}













##############################
# AWS Transfer SFTP
##############################
module "sftp_01" {
  source = "../modules"

  name                   = "obi-test-sftp-01"
  vpc_id                 = "vpc-07d744a2c69dadf0d"
  address_allocation_ids = [aws_eip.sftp_01.id, aws_eip.sftp_02.id, aws_eip.sftp_03.id]
  subnet_ids             = ["subnet-088a14628df03d390", "subnet-03cb6cf19abc35e07", "subnet-03ceef73874322702"]
  security_group_ids     = [aws_security_group.sftp.id]
  logging_role_arn       = aws_iam_role.sftp_logs.arn
  s3_bucket_id           = aws_s3_bucket.bucket.id
  #enable_add_users       = false

  users = [
    #{
    #  username              = "obi"
    #  user_role_arn         = aws_iam_role.sftp.arn
    #  public_key            = ""
    #  home_directory_type   = "LOGICAL"
    #  home_directory = "test/obi"
    #},
    #{
    #  username              = "anakin"
    #  user_role_arn         = aws_iam_role.sftp.arn
    #  public_key            = ""
    #  home_directory_type   = "LOGICAL"
    #  home_directory = "test/anakin"
    #},
    {
      username            = "yoda"
      user_role_arn       = aws_iam_role.sftp.arn
      public_key          = file("yoda_key.pub")
      home_directory_type = "LOGICAL"
      home_directory      = "test/yoda"
    },
    {
      username            = "luke"
      user_role_arn       = aws_iam_role.sftp.arn
      public_key          = file("luke_key.pub")
      home_directory_type = "PATH"
      home_directory      = "test"
    }
  ]
}

##############################
# Cloudwatch logs
##############################
resource "aws_cloudwatch_log_group" "sftp" {
  name              = "/aws/transfer/${module.sftp_01.transfer_server_id}"
  retention_in_days = 1

  depends_on = [module.sftp_01]
}

output "transfer_server_id" {
  value = module.sftp_01.transfer_server_id
}

output "transfer_server_arn" {
  value = module.sftp_01.transfer_server_arn
}

output "transfer_server_endpoint" {
  value = module.sftp_01.transfer_server_endpoint
}

~~~
