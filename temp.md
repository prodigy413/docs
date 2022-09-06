~~~
data "aws_iam_policy_document" "bucket_policy_01" {
  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_01.id}"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:ap-northeast-1:${data.aws_caller_identity.current.account_id}:trail/CTR*"]
    }
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_01.id}/cloudtraillogs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:ap-northeast-1:${data.aws_caller_identity.current.account_id}:trail/CTR*"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy_01" {
  bucket = aws_s3_bucket.bucket_01.id
  policy = data.aws_iam_policy_document.bucket_policy_01.json
}
~~~
