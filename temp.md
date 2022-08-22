~~~
data "aws_iam_policy_document" "sts_01" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_01" {
  name                  = "backup-role-01"
  assume_role_policy    = data.aws_iam_policy_document.sts_01.json
  force_detach_policies = true
}

resource "aws_iam_role_policy_attachment" "policy_attach_01" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.role_01.name
}

resource "aws_iam_role_policy_attachment" "policy_attach_02" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.role_01.name
}

~~~
