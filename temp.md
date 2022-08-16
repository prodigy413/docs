~~~
module "efs" {
  source = "../modules"

  name = var.name

  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.private_subnets_01_id,
    data.terraform_remote_state.vpc.outputs.private_subnets_02_id,
    data.terraform_remote_state.vpc.outputs.private_subnets_03_id
  ]

  enable_access_point = false

  access_point_parameter = [
    {
      tag_name       = "test"
      root_directory = "test"
      posix_user = {
        gid = "1000"
        uid = "1000"
      }
      creation_info = {
        owner_gid   = "1000"
        owner_uid   = "1000"
        permissions = "777"
      }
    },
    {
      tag_name       = "test2"
      root_directory = "test2"
      posix_user = {
        gid = "1001"
        uid = "1001"
      }
      creation_info = {
        owner_gid   = "1001"
        owner_uid   = "1001"
        permissions = "777"
      }
    }
  ]
}

output "efs_arn" {
  value = module.efs.efs_arn
}

#output "test_efs_access_point_arn" {
#  value = module.efs.efs_access_point_arn["test"]
#}
#
#output "test2_efs_access_point_arn" {
#  value = module.efs.efs_access_point_arn["test2"]
#}



















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

  dynamic "posix_user" {
    for_each = try(flatten([each.value.posix_user]), [])

    content {
      gid = try(posix_user.value.gid, null)
      uid = try(posix_user.value.uid, null)
    }
  }

  root_directory {
    path = try("/${each.value.root_directory}", null)

    dynamic "creation_info" {
      for_each = try(flatten([each.value.creation_info]), [])

      content {
        owner_gid   = try(creation_info.value.owner_gid, null)
        owner_uid   = try(creation_info.value.owner_uid, null)
        permissions = try(creation_info.value.permissions, null)
      }
    }
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
  value = tomap({ for k, v in aws_efs_access_point.efs : k => v.arn })
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
  type        = any
  default     = null
}

~~~
