~~~
data "aws_iam_policy_document" "p_ssmconsoledisable" {
  statement {
    effect    = "Deny"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:instance/*"]
  }
  statement {
    actions = ["ssm:StartSession"]
    resources = [
      "arn:aws:ec2:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
    ]
    condition {
      test     = "BoolIfExists"
      variable = "ssm:SessionDocumentAccessCheck"
      values   = ["true"]
    }
  }
}

~~~
