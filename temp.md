~~~
resource "aws_autoscaling_group" "group" {
  name                = "auto-scaling-test-01"
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = 1
  vpc_zone_identifier = var.vpc_zone_identifier

  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = var.ec2_name
    propagate_at_launch = true
  }
}








# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
resource "aws_launch_template" "template" {
  name                   = var.template_name
  description            = var.description
  image_id               = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.template.name
  }

  block_device_mappings {
    device_name = var.device_name

    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      volume_size           = 20
      volume_type           = "gp3"
      throughput            = 125
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "none"
  }

  monitoring {
    enabled = true
  }

  update_default_version               = true
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name = var.ec2_name
      },
      var.terraform_tag
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = var.ebs_name
    }
  }

  tags = merge(
    {
      Name = var.template_name
    },
    var.terraform_tag
  )
}

resource "aws_iam_instance_profile" "template" {
  name = var.iam_instance_profile_name
  role = var.iam_role_name
}










variable "template_name" {
  description = "起動テンプレート名"
  type        = string
}

variable "ec2_name" {
  description = "起動テンプレートで起動するEC2名"
  type        = string
}

variable "ebs_name" {
  description = "EBSストレージ名"
  type        = string
}

variable "description" {
  description = "起動テンプレート説明"
  type        = string
}

variable "image_id" {
  description = "起動テンプレート用AMIのID"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "起動テンプレート用セキュリティグループのID"
  type        = list(string)
}

variable "key_name" {
  description = "起動テンプレート用キー名"
  type        = string
}

variable "instance_type" {
  description = "起動テンプレート用インスタンスタイプ"
  type        = string
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}

variable "iam_instance_profile_name" {
  description = "起動テンプレート用インスタンスプロファイル名"
  type        = string
}

variable "iam_role_name" {
  description = "起動テンプレート用IAMロール名"
  type        = string
}

variable "device_name" {
  description = ""
  type        = string
}

variable "auto_scaling_group_name" {
  description = "Auto Scalingグローブ名"
  type        = string
}

variable "max_size" {
  description = ""
  type        = number
}

variable "min_size" {
  description = ""
  type        = number
}

variable "vpc_zone_identifier" {
  description = "Auto Scalingグローブに指定するサブネットのID"
  type        = list(string)
}












data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*"]
  }
}

data "aws_instances" "ec2" {
  instance_tags        = { Name = var.ec2_name }
  instance_state_names = ["running"]
  depends_on           = [module.this]
}










module "this" {
  source                    = "../modules"
  template_name             = var.template_name
  description               = var.description
  ec2_name                  = var.ec2_name
  ebs_name                  = var.ebs_name
  image_id                  = var.image_id
  instance_type             = var.instance_type
  vpc_security_group_ids    = [aws_security_group.ssh.id]
  key_name                  = var.key_name
  iam_instance_profile_name = var.iam_instance_profile_name
  #iam_role_name             = var.iam_role_name
  iam_role_name           = aws_iam_role.role.name
  device_name             = data.aws_ami.ami.root_device_name
  auto_scaling_group_name = var.auto_scaling_group_name
  max_size                = var.max_size
  min_size                = var.min_size
  vpc_zone_identifier     = [aws_subnet.subnet_01.id, aws_subnet.subnet_02.id]
}

output "ec2_id" {
  value = data.aws_instances.ec2.ids[0]
}

output "ec2_private_ip" {
  value = data.aws_instances.ec2.private_ips[0]
}

output "ec2_private_dns" {
  value = "ip-${data.aws_instances.ec2.private_ips[0]}.ap-northeast-1.compute.internal"
}

















##############################
# S3 bucket
##############################
locals {
  bucket = "obi-bucket-sftp-01"
}

resource "aws_s3_bucket" "bucket" {
  bucket        = local.bucket
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket_policy" "bucket" {
#  bucket = aws_s3_bucket.bucket.id
#  policy = data.aws_iam_policy_document.bucket.json
#}

#data "aws_iam_policy_document" "bucket" {
#  statement {
#    sid       = "AllowListingOfUserFolder"
#    actions   = ["s3:ListBucket"]
#    resources = [aws_s3_bucket.bucket.arn]
#    principals {
#      type        = "AWS"
#      identifiers = ["*"]
#    }
#  }
#  #Also, note that the GetObjectACL and PutObjectACL statements are only required if you are doing Cross Account Access.
#  #That is, your Transfer Family server needs to access a bucket in a different account.
#  statement {
#    sid = "HomeDirObjectAccess"
#    actions = [
#      "s3:PutObject",
#      "s3:GetObject",
#      "s3:DeleteObject",
#      "s3:DeleteObjectVersion",
#      "s3:GetBucketLocation",
#      "s3:GetObjectVersion",
#      "s3:GetObjectACL",
#      "s3:PutObjectACL"
#    ]
#    resources = ["${aws_s3_bucket.bucket.arn}/*"]
#    principals {
#      type        = "AWS"
#      identifiers = ["*"]
#    }
#  }
#}

##############################
# IAM Role for SFTP
##############################
data "aws_iam_policy_document" "sts" {
  statement {
    actions = ["sts:AssumeRole", ]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com", ]
    }
  }
}

#data "aws_iam_policy_document" "sftp" {
#  statement {
#    actions = ["s3:*", ]
#    resources = [
#      "${aws_s3_bucket.bucket.arn}",
#      "${aws_s3_bucket.bucket.arn}/*",
#    ]
#  }
#}

data "aws_iam_policy_document" "sftp" {
  statement {
    sid       = "AllowListingOfUserFolder"
    actions   = ["s3:ListBucket", ]
    resources = [aws_s3_bucket.bucket.arn]
  }
  #Also, note that the GetObjectACL and PutObjectACL statements are only required if you are doing Cross Account Access.
  #That is, your Transfer Family server needs to access a bucket in a different account.
  statement {
    sid = "HomeDirObjectAccess"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_role" "sftp" {
  name               = "obi-sftp-role-01"
  assume_role_policy = data.aws_iam_policy_document.sts.json
}

resource "aws_iam_policy" "sftp" {
  name   = "obi-sftp-policy-01"
  policy = data.aws_iam_policy_document.sftp.json
}

resource "aws_iam_role_policy_attachment" "sftp" {
  role       = aws_iam_role.sftp.name
  policy_arn = aws_iam_policy.sftp.arn
}

##############################
# AWS Transfer SFTP
##############################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_server
resource "aws_transfer_server" "sftp" {
  endpoint_type          = "PUBLIC"
  identity_provider_type = "SERVICE_MANAGED"
  domain                 = "S3"
  protocols              = ["SFTP"]
  force_destroy          = true
  tags                   = { Name = "obi-sftp-01" }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user
resource "aws_transfer_user" "sftp" {
  server_id = aws_transfer_server.sftp.id
  user_name = "testuser"
  role      = aws_iam_role.sftp.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/obi-bucket-sftp-01"
  }
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




~~~
