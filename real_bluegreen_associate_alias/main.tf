locals {
  environment              = "dev"
  origin_domain            = "great-obi.com"
  routing_domain           = "cf.great-obi.com"
  routing_domain_02        = "_cf.great-obi.com"
  blue_domain              = "blue.great-obi.com"
  green_domain             = "green.great-obi.com"
  aws_account_id           = "844065555252"
  product_name             = "greatobi"
  terraform_operation_user = "xxxxxx"
  deletion_protection      = false
}

terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.66.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      environment = local.environment
      app         = local.product_name
    }
  }
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"

  default_tags {
    tags = {
      environment = local.environment
      app         = local.product_name
    }
  }
}
