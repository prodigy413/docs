~~~
module "efs" {
  source = "../modules"

  name = var.name

  subnet_ids = [
    #data.terraform_remote_state.vpc.outputs.private_subnets_01_id,
    #data.terraform_remote_state.vpc.outputs.private_subnets_02_id,
    #data.terraform_remote_state.vpc.outputs.private_subnets_03_id
    data.terraform_remote_state.vpc.outputs.public_subnets_01_id,
    data.terraform_remote_state.vpc.outputs.public_subnets_02_id,
    data.terraform_remote_state.vpc.outputs.public_subnets_03_id
  ]

  #enable_access_point = false

  access_point_parameter = var.access_point_parameter_01
  #access_point_parameter = [
  #  {
  #    tag_name       = "test"
  #    root_directory = "test/sub_test"
  #    posix_user = {
  #      gid = 1000
  #      uid = 1000
  #    }
  #    creation_info = {
  #      owner_gid   = 1000
  #      owner_uid   = 1000
  #      permissions = 777
  #    }
  #  },
  #  {
  #    tag_name       = "test2"
  #    root_directory = "test2/sub_test"
  #    posix_user = {
  #      gid = 1001
  #      uid = 1001
  #    }
  #    creation_info = {
  #      owner_gid   = 1001
  #      owner_uid   = 1001
  #      permissions = 777
  #    }
  #  }
  #]
}

output "efs_arn" {
  value = module.efs.efs_arn
}

output "test_efs_access_point_arn" {
  value = module.efs.efs_access_point_arn[var.access_point_parameter_01[0].tag_name]
}

output "test_efs_access_point_id" {
  value = module.efs.efs_access_point_id[var.access_point_parameter_01[0].tag_name]
}

output "test2_efs_access_point_arn" {
  value = module.efs.efs_access_point_arn[var.access_point_parameter_01[1].tag_name]
}

output "test2_efs_access_point_id" {
  value = module.efs.efs_access_point_id[var.access_point_parameter_01[1].tag_name]
}












variable "name" {
  description = "The name of EFS"
  type        = string
  default     = "obi-test-efs-01"
}

variable "access_point_parameter_01" {
  type = any
  default = [
    {
      tag_name       = "test"
      root_directory = "test/sub_test"
    },
    {
      tag_name       = "test2"
      root_directory = "test2/sub_test"
    }
  ]
}














# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
resource "aws_efs_file_system" "efs" {

  tags = merge(
    {
      Name = var.name
    },
    var.terraform_tag,
    var.awsbackup_tag
  )

  #encrypted        = true
  #performance_mode = "generalPurpose"
  #throughput_mode  = "bursting"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_backup_policy
resource "aws_efs_backup_policy" "efs" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

# https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/efs_replication_configuration
#resource "aws_efs_replication_configuration" "efs" {
#  source_file_system_id = aws_efs_file_system.efs.id
#
#  destination {
#    region     = "ap-northeast-3"
#    kms_key_id = "/aws/elasticfilesystem"
#  }
#}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target
resource "aws_efs_mount_target" "efs" {
  count = length(var.subnet_ids)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = element(var.subnet_ids, count.index)
  #security_groups = var.security_group_id_work01
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point
resource "aws_efs_access_point" "efs" {
  for_each = var.enable_access_point ? { for parameter in var.access_point_parameter : parameter.tag_name => parameter } : {}

  file_system_id = aws_efs_file_system.efs.id

  root_directory {
    path = try("/${each.value.root_directory}", null)
  }

  tags = {
    Name = each.value.tag_name
  }
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "efs_arn" {
  value = aws_efs_file_system.efs.arn
}

#output "efs_access_point_arn" {
#  value = aws_efs_access_point.efs[*].id
#}

#output "efs_access_point_arn" {
#  value = [for value in aws_efs_access_point.efs : value.arn]
#}

output "efs_access_point_arn" {
  value = var.enable_access_point ? tomap({ for k, v in aws_efs_access_point.efs : k => v.arn }) : null
}

output "efs_access_point_id" {
  value = var.enable_access_point ? tomap({ for k, v in aws_efs_access_point.efs : k => v.id }) : null
}














variable "name" {
  description = "The name of EFS"
  type        = string
}

variable "terraform_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}

variable "awsbackup_tag" {
  description = "Tag for AWSBackup managed resources"
  type        = map(string)
  default = {
    AWSBackup = "managed"
  }
}

variable "subnet_ids" {
  description = "The ID of subnet"
  type        = list(string)
}

variable "enable_access_point" {
  description = ""
  type        = bool
  default     = true
}

variable "access_point_parameter" {
  description = ""
  type = list(object({
    tag_name       = string
    root_directory = string
  }))
  default = []
}

~~~
