~~~
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
resource "aws_efs_file_system" "efs" {

  tags = merge(
    {
      Name = var.name
    },
    var.terraform_tag,
    var.awsbackup_tag
  )

  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_backup_policy
resource "aws_efs_backup_policy" "efs" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

# https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/efs_replication_configuration
resource "aws_efs_replication_configuration" "efs" {
  source_file_system_id = aws_efs_file_system.efs.id

  destination {
    region     = "ap-northeast-3"
    kms_key_id = "/aws/elasticfilesystem"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target
resource "aws_efs_mount_target" "aza" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id_w1sa
  security_groups = var.security_group_id_work01
}

resource "aws_efs_mount_target" "azc" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id_w1sc
  security_groups = var.security_group_id_work01
}

resource "aws_efs_mount_target" "azd" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id_w1sd
  security_groups = var.security_group_id_work01
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "efs_arn" {
  value = aws_efs_file_system.efs.arn
}

output "name" {
  value = aws_efs_mount_target.aza.id
}













variable "name" {
  description = "The name of EFS"
  type        = string
  default     = ""
}

variable "terraform_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terraform = null
  }
}

variable "awsbackup_tag" {
  description = "Tag for AWSBackup managed resources"
  type        = map(string)
  default = {
    AWSBackup = null
  }
}

variable "subnet_id_w1sa" {
  description = "The ID of subnet"
  type        = string
  default     = null
}

variable "subnet_id_w1sc" {
  description = "The ID of subnet"
  type        = string
  default     = null
}

variable "subnet_id_w1sd" {
  description = "The ID of subnet"
  type        = string
  default     = null
}

variable "security_group_id_work01" {
  description = "The ID of security group"
  type        = list(string)
  default     = [null]
}











~~~
