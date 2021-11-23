# datadog integration role
data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        "${local.datadog_external_id}"
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "ec2:Describe*",
      "support:*",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}

resource "aws_iam_role" "datadog_aws_integration" {
  name               = "DatadogAWSIntegrationRole"
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}

# firehose
data "aws_iam_policy_document" "policy_01" {
  statement {
    sid     = "obiAssumeRoleFirehose01"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "policy_02" {
  statement {
    sid    = "obiPolicyFirehose01"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.product}-${local.env}-backup-01",
      "arn:aws:s3:::${local.product}-${local.env}-backup-01/*"
    ]
  }
}

resource "aws_iam_role" "firehose_role_01" {
  name               = "${local.product}-${local.env}-firehose-01"
  assume_role_policy = data.aws_iam_policy_document.policy_01.json

  tags = {
    Name = "${local.product}-${local.env}-firehose-01"
  }
}

resource "aws_iam_policy" "firehose_policy_01" {
  name   = "${local.product}-${local.env}-firehose-01"
  policy = data.aws_iam_policy_document.policy_02.json

  tags = {
    Name = "${local.product}-${local.env}-firehose-01"
  }
}

resource "aws_iam_role_policy_attachment" "attach_01" {
  role       = aws_iam_role.firehose_role_01.name
  policy_arn = aws_iam_policy.firehose_policy_01.arn
}

# cloudwatch metric streams
data "aws_iam_policy_document" "policy_03" {
  statement {
    sid     = "obiAssumeRoleStream01"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["streams.metrics.cloudwatch.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "policy_04" {
  statement {
    sid    = "obiPolicyStream01"
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [
      "arn:aws:firehose:*:${data.aws_caller_identity.identity_01.account_id}:deliverystream/${local.product}-${local.env}-kinesis-01"
    ]
  }
}

resource "aws_iam_role" "stream_role_01" {
  name               = "${local.product}-${local.env}-stream-01"
  assume_role_policy = data.aws_iam_policy_document.policy_03.json

  tags = {
    Name = "${local.product}-${local.env}-stream-01"
  }
}

resource "aws_iam_policy" "stream_policy_01" {
  name   = "${local.product}-${local.env}-stream-01"
  policy = data.aws_iam_policy_document.policy_04.json

  tags = {
    Name = "${local.product}-${local.env}-stream-01"
  }
}

resource "aws_iam_role_policy_attachment" "attach_02" {
  role       = aws_iam_role.stream_role_01.name
  policy_arn = aws_iam_policy.stream_policy_01.arn
}
