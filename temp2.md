~~~
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = var.instance_type

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name             = var.key_name
  monitoring           = true
  iam_instance_profile = var.iam_instance_profile

  capacity_reservation_specification {
    capacity_reservation_preference = "nxxxxxone"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 0
    volume_size           = 0
    volume_type           = "gp3"
    throughput            = 0

    tags = {
      Name = var.ebs_name
    }
  }

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"

  tags = merge(
    {
      Name = var.name
    },
    var.terra_tag
  )
}










variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = null
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = ""
}

variable "ebs_name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = ""
}

variable "terra_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terra = "managed"
  }
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = ""
}













variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = "ap-northeast-1a"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = "subnet-xxxxxxxxxxx"
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "test-ec2"
}

variable "ebs_name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "test-ebs"
}

variable "terra_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terra = "managed"
  }
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = "ami-xxxxxxxxxxx"
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = ["sg-xxxxxxxx"]
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}








module "ec2" {
  source = "../modules"

  name                   = var.name
  ami                    = var.ami
  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  ebs_name               = var.ebs_name
}










# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
resource "aws_efs_file_system" "efs" {

  tags = merge(
    {
      Name = var.name
    },
    var.terra_tag,
    var.backup_tag
  )

  encrypted        = true
  performance_mode = "xxxxxxx"
  throughput_mode  = "xxxxxxx"

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
    region     = "ap-northeast-1"
    kms_key_id = "/aws/elasticfilesystem"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target
resource "aws_efs_mount_target" "az1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id_az1
  security_groups = var.security_group_id_work01
}








variable "name" {
  description = "The name of EFS"
  type        = string
  default     = ""
}

variable "terra_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terra = null
  }
}

variable "backup_tag" {
  description = "Tag for Backup managed resources"
  type        = map(string)
  default = {
    Backup = null
  }
}

variable "subnet_id_az1" {
  description = "The ID of subnet"
  type        = string
  default     = null
}

variable "security_group_id_test" {
  description = "The ID of security group"
  type        = list(string)
  default     = [null]
}









module "ec2" {
  source = "../modules"

  name                   = var.name
  ami                    = var.ami
  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  ebs_name               = var.ebs_name
}





variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = "ap-northeast-1a"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = "subnet-xxxxxxxxxxx"
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "test-ec2"
}

variable "ebs_name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "test-ebs"
}

variable "terra_tag" {
  description = "Tag for Terraform managed resources"
  type        = map(string)
  default = {
    Terra = "managed"
  }
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = "ami-xxxxxxxxxxx"
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = ["sg-xxxxxxxx"]
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

~~~
