data "aws_iam_policy_document" "s3_01" {
  statement {
    sid       = "obiS3Policy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.product}-${local.env}-${local.s3_key}/*"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket" "s3_01" {
  bucket        = "${local.product}-${local.env}-${local.s3_key}"
  acl           = "private"
  force_destroy = local.deletion_protection
  versioning {
    enabled = true
  }
  policy = data.aws_iam_policy_document.s3_01.json

  tags = {
    Name = "${local.product}-${local.env}-${local.s3_key}"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block_01" {
  bucket = aws_s3_bucket.s3_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
