data "aws_route53_zone" "main_domain" {
  name = local.origin_domain
}

data "aws_iam_policy_document" "s3_cloudfront_policy_01" {
  statement {
    sid       = "cftest01"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::great-obi-s3-01/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloud_front_01.iam_arn]
    }
  }
}

data "aws_iam_policy_document" "s3_cloudfront_policy_02" {
  statement {
    sid       = "cftest02"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::great-obi-s3-02/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloud_front_02.iam_arn]
    }
  }
}
