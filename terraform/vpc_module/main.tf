provider "aws" {
  region = "ap-northeast-1"
}

locals {
  name   = "obi-dev"
  region = "ap-northeast-1"
  tags = {
    Owner       = "user"
    Environment = "staging"
    Name        = "complete"
  }
}

################################################################################
# VPC Module
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw             = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

################################################################################
# Security Group Module
################################################################################
module "security_group_01" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "web-server"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}
