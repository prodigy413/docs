~~~
# Allow ssh
resource "aws_security_group" "allow_ssh" {
  name   = "allow-ssh-${local.environment}"
  vpc_id = aws_vpc.vpc_01.id

  tags = {
    name = "allow-ssh-${local.environment}"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_ssh.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.allow_ssh.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow http
resource "aws_security_group" "allow_http" {
  name        = "allow-http-${local.environment}"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc_01.id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "allow-http-${local.environment}"
  }
}

# Allow https
resource "aws_security_group" "allow_https" {
  name        = "allow-https-${local.environment}"
  description = "Allow https"
  vpc_id      = aws_vpc.vpc_01.id

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "allow-https-${local.environment}"
  }
}

# Allow https
resource "aws_security_group" "allow_db_access" {
  name        = "allow-db-access-${local.environment}"
  description = "Allow db access"
  vpc_id      = aws_vpc.vpc_01.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "allow-db-access-${local.environment}"
  }
}

resource "aws_security_group" "allow_http_02" {
  name        = "allow-specific-security-group"
  description = "Allow specific security group"
  vpc_id      = aws_vpc.vpc_01.id

  ingress {
    description     = "http"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_db_access.id, aws_security_group.allow_https.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "allow-http-${local.environment}"
  }
}






















variable "folders" {
  type    = list(string)
  default = ["test01/", "test02/", "test03/", "test04/test05/"]
}

resource "aws_s3_bucket" "s3_01" {
  bucket        = "great-obi-s3-01"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl_01" {
  bucket = aws_s3_bucket.s3_01.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_01" {
  bucket = aws_s3_bucket.s3_01.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "obi_s3_01_access_block" {
  bucket = aws_s3_bucket.s3_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "folders" {
  count  = length(var.folders)
  bucket = aws_s3_bucket.s3_01.id
  key    = element(var.folders, count.index)
}





















# for, for_each, count
# https://zenn.dev/wim/articles/terraform_loop

locals {
  list = [
    "hoge",
    "fuga"
  ]
}

output "output_list" {
  #value = [for l in local.list : upper(l)]
  #+ output_list = [
  #    + "HOGE",
  #    + "FUGA",
  #  ]

  #value = [for l in local.list : upper(l) if l != "fuga"]
  #+ output_list = [
  #    + "HOGE",
  #  ]

  #value = [for i, l in local.list : "${i}_${l}"]
  #+ output_list = [
  #    + "0_hoge",
  #    + "1_fuga",
  #  ]

  # map result
  value = { for i, l in local.list : i => l }
  #+ output_list = {
  #    + 0 = "hoge"
  #    + 1 = "fuga"
  #  }
}

locals {
  list2 = [
    "hoge",
    "fuga",
    "fuga"
  ]
}

output "output_map" {
  value = { for l in local.list2 : l => l... }
  #+ output_map  = {
  #    + fuga = [
  #        + "fuga",
  #        + "fuga",
  #      ]
  #    + hoge = [
  #        + "hoge",
  #      ]
  #  }
}
















# If all variables exist, k8s_irsa_role_create is true.
locals {
  k8s_irsa_role_create = var.enabled && var.k8s_rbac_create && var.k8s_service_account_create && var.k8s_irsa_role_create
}

####################
# Formatlist
####################
data "aws_iam_policy_document" "this" {
  count = local.k8s_irsa_role_create && var.k8s_irsa_policy_enabled && !var.k8s_assume_role_enabled ? 1 : 0

  statement {
    sid    = "ChangeResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = formatlist(
      "arn:aws:route53:::hostedzone/%s",
      var.policy_allowed_zone_ids
    )
  }
}

####################
# Count
####################
variable "subnet_ids" {
  type = list(string)
}

resource "aws_instance" "server" {
  # Create one instance for each subnet
  count = length(var.subnet_ids)

  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"
  subnet_id     = var.subnet_ids[count.index]

  tags = {
    Name = "Server ${count.index}"
  }
}

####################
# Lookup
####################
# > lookup({a="ay", b="bee"}, "a", "what?")
# ay
# > lookup({a="ay", b="bee"}, "c", "what?")
# what?

####################
# Variable Validation
####################
variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "valid values are dev, stg or prd"
  }
}

####################
# Reference Files
####################
resource "aws_cloudfront_function" "test" {
  name    = "cloudfront-header-01"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("source/headers.js")
}

####################
# cidrsubnet
####################
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
> cidrsubnet("10.0.0.0/16", 8, 2)
"10.0.2.0/24"
> cidrsubnet("10.0.0.0/16", 8, 3)
"10.0.3.0/24"

####################
# dynamic
####################
variable "default_cache_behavior" {
  description = "The default cache behavior for this distribution"
  type        = any
  default     = null
}

module "cdn" {
  default_cache_behavior = {
    target_origin_id           = "something"
    viewer_protocol_policy     = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create_distribution ? 1 : 0

  dynamic "default_cache_behavior" {
    for_each = [var.default_cache_behavior]
    iterator = i

    content {
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]

      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", null)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)

      cache_policy_id            = lookup(i.value, "cache_policy_id", null)
      origin_request_policy_id   = lookup(i.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(i.value, "response_headers_policy_id", null)
      realtime_log_config_arn    = lookup(i.value, "realtime_log_config_arn", null)

      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(i.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", false)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", [])
          headers                 = lookup(i.value, "headers", [])

          cookies {
            forward           = lookup(i.value, "cookies_forward", "none")
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(i.value, "lambda_function_association", [])
        iterator = l

        content {
          event_type   = l.key
          lambda_arn   = l.value.lambda_arn
          include_body = lookup(l.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = lookup(i.value, "function_association", [])
        iterator = f

        content {
          event_type   = f.key
          function_arn = f.value.function_arn
        }
      }
    }
  }
}

####################
# Override
####################
# https://www.terraform.io/language/files/override

####################
# element
####################
# > element(["a", "b", "c"], 1)
# b
# 
# > element(["a", "b", "c"], length(["a", "b", "c"])-1)
# c


~~~
