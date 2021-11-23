locals {
  env                 = "dev"
  product             = "greatobi"
  s3_key              = "backup-01"
  datadog_api_key     = "81361cca1bd36b562f809768c63d9f66"
  datadog_external_id = "abf9bef7902d435d94f305fe0d8948ae"
  deletion_protection = false
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
      environment = local.env
      project     = local.product
    }
  }
}
