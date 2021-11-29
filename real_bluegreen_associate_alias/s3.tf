resource "aws_s3_bucket" "obi_s3_01" {
  bucket = "great-obi-s3-01"
  acl    = "private"

  versioning {
    enabled = false
  }

  policy = data.aws_iam_policy_document.s3_cloudfront_policy_01.json
}

resource "aws_s3_bucket_public_access_block" "obi_s3_01_access_block" {
  bucket = aws_s3_bucket.obi_s3_01.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "obi_s3_02" {
  bucket = "great-obi-s3-02"
  acl    = "private"

  versioning {
    enabled = false
  }

  policy = data.aws_iam_policy_document.s3_cloudfront_policy_02.json
}

resource "aws_s3_bucket_public_access_block" "obi_s3_02_access_block" {
  bucket = aws_s3_bucket.obi_s3_02.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket" "maintain" {
#  bucket = "great-obi-s3-maintain"
#  acl    = "private"
#
#  versioning {
#    enabled = false
#  }
#
#  policy = data.aws_iam_policy_document.s3_cloudfront_policy_02.json
#}
#
#resource "aws_s3_bucket_public_access_block" "obi_s3_02_access_block" {
#  bucket = aws_s3_bucket.obi_s3_02.id
#
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}
#