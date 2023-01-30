~~~
data "aws_iam_policy_document" "bucket_02" {
  statement {
    actions   = ["s3:PutObject", ]
    resources = ["${aws_s3_bucket.bucket_02.arn}/*"]
    principals {
      type = "Service"
      identifiers = [
        "logging.s3.amazonaws.com"
      ]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:s3:::*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }
  }
}
~~~
