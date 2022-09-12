~~~
resource "aws_efs_access_point" "efs" {
  for_each = var.enable_access_point ? { for parameter in var.access_point_parameter : parameter.basic.tag_name => parameter } : {}

  file_system_id = aws_efs_file_system.efs.id

  dynamic "posix_user" {
    for_each = try(flatten([each.value.posix_user]), [])

    content {
      gid            = try(posix_user.value.gid, null)
      uid            = try(posix_user.value.uid, null)
      secondary_gids = try(split(",", posix_user.value.secondary_gids), null)
      #secondary_gids = try(tonumber(split(",", posix_user.value.secondary_gids)), null)
      #secondary_gids = try(posix_user.value.secondary_gids, null)
    }
  }

  root_directory {
    path = each.value.basic.root_directory

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
    Name = each.value.basic.tag_name
  }
}










variable "access_point_parameter" {
  description = ""
  type        = any
  default     = []
}









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
}











variable "access_point_parameter_01" {
  description = ""
  type        = any
  default = [
    {
      basic = {
        tag_name       = "test1"
        root_directory = "/test1/sub_test"
      }
    },
    {
      basic = {
        tag_name       = "test2"
        root_directory = "/test2/sub_test"
      }
      posix_user = {
        gid = 1001
        uid = 1001
      }
    },
    {
      basic = {
        tag_name       = "test3"
        root_directory = "/test3/sub_test"
      }
      posix_user = {
        gid            = 1002
        uid            = 1002
        secondary_gids = "1003,1004"
      }
      creation_info = {
        owner_gid   = 1002
        owner_uid   = 1002
        permissions = 755
      }
    }
  ]
}
~~~
