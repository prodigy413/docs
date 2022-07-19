### auto_scaling_group.tf

~~~
resource "aws_autoscaling_group" "group" {
  name                = var.auto_scaling_group_name
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
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
    value               = var.auto_scaling_group_name
    propagate_at_launch = false
  }
  tag {
    key                 = "Terraform"
    value               = var.terraform_tag
    propagate_at_launch = false
  }
}
~~~

### launch_template.tf

~~~
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

  #metadata_options {
  #  http_endpoint               = "enabled"
  #  http_tokens                 = "optional"
  #  http_put_response_hop_limit = 1
  #}

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

  credit_specification {
    cpu_credits = "standard"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "none"
  }

  monitoring {
    enabled = true
  }

  update_default_version               = true
  disable_api_termination              = true
  instance_initiated_shutdown_behavior = "stop"

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name = var.ec2_name
      },
      var.autoscaling_tag
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      {
        Name = var.ec2_name
      },
      var.autoscaling_tag
    )
  }

  tags = {
    Name      = var.template_name
    Terraform = var.terraform_tag
  }
}

resource "aws_iam_instance_profile" "template" {
  name = var.iam_instance_profile_name
  role = var.iam_role_name
}
~~~

### variables.tf

~~~
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
  type        = string
  default     = "managed"
}

variable "autoscaling_tag" {
  description = ""
  type        = map(string)
  default = {
    AutoScaling = "managed"
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
  description = "マウントするデバイス名"
  type        = string
}

variable "auto_scaling_group_name" {
  description = "Auto Scalingグローブ名"
  type        = string
}

variable "max_size" {
  description = "起動するインスタンス数の最大値"
  type        = number
}

variable "min_size" {
  description = "起動するインスタンス数の最小値"
  type        = number
}

variable "desired_capacity" {
  description = "起動したいインスタンス数"
  type        = number
}

variable "vpc_zone_identifier" {
  description = "Auto Scalingグローブに指定するサブネットのID"
  type        = list(string)
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
  type        = string
  default     = "managed"
}

variable "autoscaling_tag" {
  description = ""
  type        = map(string)
  default = {
    AutoScaling = "managed"
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
  description = "マウントするデバイス名"
  type        = string
}

variable "auto_scaling_group_name" {
  description = "Auto Scalingグローブ名"
  type        = string
}

variable "max_size" {
  description = "起動するインスタンス数の最大値"
  type        = number
}

variable "min_size" {
  description = "起動するインスタンス数の最小値"
  type        = number
}

variable "desired_capacity" {
  description = "起動したいインスタンス数"
  type        = number
}

variable "vpc_zone_identifier" {
  description = "Auto Scalingグローブに指定するサブネットのID"
  type        = list(string)
}
~~~

~~~
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "obi-test-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

data "aws_ami" "ami" {
  filter {
    name   = "image-id"
    values = [var.image_id]
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
  vpc_security_group_ids    = ["sg-060d48f83c095649d"]
  key_name                  = var.key_name
  iam_instance_profile_name = var.iam_instance_profile_name
  iam_role_name             = var.iam_role_name
  device_name               = data.aws_ami.ami.root_device_name
  auto_scaling_group_name   = var.auto_scaling_group_name
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier = [
    data.terraform_remote_state.vpc.outputs.private_subnets_01_id,
    data.terraform_remote_state.vpc.outputs.private_subnets_02_id,
    data.terraform_remote_state.vpc.outputs.private_subnets_03_id
  ]
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






variable "template_name" {
  description = "起動テンプレート名"
  type        = string
  default     = "obi-launch-template"
}

variable "ec2_name" {
  description = "起動テンプレートで起動するEC2名"
  type        = string
  default     = "obi-test-ec2"
}

variable "ebs_name" {
  description = "EBSストレージ名"
  type        = string
  default     = "obi-ebs-storage"
}

variable "description" {
  description = "起動テンプレート説明"
  type        = string
  default     = "This is template for test."
}

variable "image_id" {
  description = "起動テンプレート用AMIのID"
  type        = string
  default     = "ami-06ce6680729711877"
  #default     = "ami-0b7546e839d7ace12"
}

variable "key_name" {
  description = "起動テンプレート用キー名"
  type        = string
  default     = "test-key"
}

variable "instance_type" {
  description = "起動テンプレート用インスタンスタイプ"
  type        = string
  default     = "t3.micro"
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
  default     = "obi-instance-profile"
}

variable "iam_role_name" {
  description = "起動テンプレート用IAMロール名"
  type        = string
  default     = "ssm-test-01"
}

variable "auto_scaling_group_name" {
  description = "Auto Scalingグローブ名"
  type        = string
  default     = "obi-auto-scaling-group"
}

variable "max_size" {
  description = "起動するインスタンス数の最大値"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "起動するインスタンス数の最小値"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "起動したいインスタンス数"
  type        = number
  default     = 1
}
~~~
