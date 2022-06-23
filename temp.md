~~~
module "bucket_tokyo" {
  source = "../modules"
  name   = "obi-s3-test-tokyo"
}

module "bucket_osaka" {
  providers = { aws = aws.osaka }
  source    = "../modules"
  name      = "obi-s3-test-osaka"
}

output "tokyo_bucket_id" {
  value = module.bucket_tokyo.bucket_id
}

output "tokyo_bucket_arn" {
  value = module.bucket_tokyo.bucket_arn
}

output "osaka_bucket_id" {
  value = module.bucket_osaka.bucket_id
}

output "osaka_bucket_arn" {
  value = module.bucket_osaka.bucket_arn
}

output "tokyo_bucket_regional_domain" {
  value = module.bucket_tokyo.bucket_regional_domain
}

output "osaka_bucket_regional_domain" {
  value = module.bucket_osaka.bucket_regional_domain
}










provider "aws" {
  alias  = "osaka"
  region = "ap-northeast-3"
}












terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}











module "replication" {
  source                = "../modules"
  replication_rule_name = "test-replication"
  role_name             = "replication_role"
  policy_name           = "replication_policy"
  s3_bucket_tokyo_id    = "obi-s3-test-tokyo"
  s3_bucket_tokyo_arn   = "arn:aws:s3:::obi-s3-test-tokyo"
  s3_bucket_osaka_arn   = "arn:aws:s3:::obi-s3-test-osaka"
}

output "s3_cross_region_replication_id" {
  value = module.replication.s3_cross_region_replication_id
}












##############################
# IAM Policy, Role
##############################
data "aws_iam_policy_document" "sts" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "replication" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [var.s3_bucket_tokyo_arn]
  }
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${var.s3_bucket_tokyo_arn}/*"]
  }
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = ["${var.s3_bucket_osaka_arn}/*"]
  }
}

resource "aws_iam_role" "replication" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.sts.json
}

resource "aws_iam_policy" "replication" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  policy_arn = aws_iam_policy.replication.arn
  role       = aws_iam_role.replication.name
}

##############################
# S3 Cross Region Replication
##############################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = var.s3_bucket_tokyo_id

  rule {
    id     = var.replication_rule_name
    status = "Enabled"

    destination {
      bucket        = var.s3_bucket_osaka_arn
      storage_class = "STANDARD"
    }
  }
}

output "s3_cross_region_replication_id" {
  value = aws_s3_bucket_replication_configuration.replication.id
}












variable "replication_rule_name" {
  type = string
}

variable "role_name" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "s3_bucket_tokyo_id" {
  type = string
}

variable "s3_bucket_tokyo_arn" {
  type = string
}

variable "s3_bucket_osaka_arn" {
  type = string
}

~~~
