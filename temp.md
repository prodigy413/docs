### module

~~~
### iam_group.tf
resource "aws_iam_group" "group" {
  name = var.group_name
}

resource "aws_iam_group_policy_attachment" "group" {
  count = var.attach_policy_to_group ? length(var.group_policy_arn) : 0

  group      = aws_iam_group.group.name
  policy_arn = element(var.group_policy_arn, count.index)
}

output "iam_group_arn" {
  value = aws_iam_group.group.arn
}

output "iam_group_id" {
  value = aws_iam_group.group.id
}




### variables.tf
variable "group_name" {
  description = "IAMグループ名"
  type        = string
}

variable "attach_policy_to_group" {
  description = "グループにポリシーを追加可能/不可設定"
  type        = bool
  default     = true
}

variable "group_policy_arn" {
  description = "グループに追加するIAMポリシーのArn"
  type        = list(string)
  default     = [null]
}




### iam_policy.tf
resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  description = var.policy_description
  policy      = var.policy_json

  tags = merge(
    {
      Name = var.policy_name
    },
    var.terraform_tag
  )
}

output "policy_arn" {
  value = aws_iam_policy.policy.arn
}




### variables.tf
variable "policy_name" {
  description = "IAMポリシー名"
  type        = string
}

variable "policy_description" {
  description = "ポリシー説明"
  type        = string
  default     = null
}

variable "policy_json" {
  description = "JSON形式のポリシー内容"
  type        = string
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}




### iam_role.tf
resource "aws_iam_role" "role" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = var.assume_role_policy_json

  tags = merge(
    {
      Name = var.role_name
    },
    var.terraform_tag
  )
}

resource "aws_iam_role_policy_attachment" "role" {
  count = var.attach_policy_to_role ? length(var.role_policy_arn) : 0

  role       = aws_iam_role.role.name
  policy_arn = element(var.role_policy_arn, count.index)
}




### variables.tf
variable "role_name" {
  description = "IAMロールー名"
  type        = string
}

variable "role_description" {
  description = "ロール説明"
  type        = string
  default     = null
}

variable "assume_role_policy_json" {
  description = "JSON形式のAssumeRoleの内容"
  type        = string
}

variable "role_policy_arn" {
  description = "ロールに追加するIAMポリシーのArn"
  type        = list(string)
  default     = [null]
}

variable "attach_policy_to_role" {
  description = "ロールにポリシーを追加可能/不可設定"
  type        = bool
  default     = true
}

variable "terraform_tag" {
  description = "Terraformコードで管理するサービス用タグ"
  type        = map(string)
  default = {
    Terraform = "managed"
  }
}




~~~

### env

~~~
### data.tf
data "aws_caller_identity" "current" {}




### iam_group.tf
module "g_nbase" {
  source = "../modules/iam_group"

  group_name       = var.g_name_nbase
  group_policy_arn = [module.p_mfaenable.policy_arn]
}

module "g_madmin" {
  source = "../modules/iam_group"

  group_name       = var.g_name_madmin
  group_policy_arn = [module.p_madmin.policy_arn]
}

module "g_mmanagement" {
  source = "../modules/iam_group"

  group_name       = var.g_name_mmanagement
  group_policy_arn = [module.p_mmanagement.policy_arn]
}

module "g_nadmin" {
  source = "../modules/iam_group"

  group_name       = var.g_name_nadmin
  group_policy_arn = [module.p_nadmin.policy_arn]
}

module "g_nadminsub" {
  source = "../modules/iam_group"

  group_name       = var.g_name_nadminsub
  group_policy_arn = [module.p_nadminsub.policy_arn]
}

module "g_ndba" {
  source = "../modules/iam_group"

  group_name       = var.g_name_ndba
  group_policy_arn = [module.p_ndba.policy_arn]
}







### iam_policy.tf
##############################
# Policy_01
##############################
data "aws_iam_policy_document" "p_mfaenable" {
  statement {
    actions = [
      "iam:UpdateLoginProfile",
      "iam:DeactivateMFADevice",
      "iam:UpdateUser",
      "iam:ListMFADevices",
      "iam:CreateLoginProfile",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:GetUser",
      "iam:GetLoginProfile",
      "iam:DeleteLoginProfile",
      "iam:ChangePassword"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }
  statement {
    actions = [
      "iam:DeleteVirtualMFADevice",
      "iam:CreateVirtualMFADevice"
    ]
    resources = ["arn:aws:iam::*:mfa/$${aws:username}"]
  }
  statement {
    actions = [
      "iam:ListUsers",
      "iam:ListVirtualMFADevices"
    ]
    resources = ["*"]
  }
}

module "p_mfaenable" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_mfaenable
  policy_description = var.p_description_mfaenable
  policy_json        = data.aws_iam_policy_document.p_mfaenable.json
}

##############################
# Policy_02
##############################
data "aws_iam_policy_document" "p_accesskeyenable" {
  statement {
    actions = [
      "iam:UpdateLoginProfile",
      "iam:DeleteAccessKey",
      "iam:UpdateUser",
      "iam:CreateAccessKey",
      "iam:GetUser",
      "iam:GetLoginProfile",
      "iam:DeleteLoginProfile",
      "iam:ListAccessKeys"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }
  statement {
    actions = [
      "iam:ListUsers"
    ]
    resources = ["*"]
  }
}

module "p_accesskeyenable" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_accesskeyenable
  policy_description = var.p_description_accesskeyenable
  policy_json        = data.aws_iam_policy_document.p_accesskeyenable.json
}

##############################
# Policy_03
##############################
data "aws_iam_policy_document" "p_ssmconnect" {
  statement {
    actions   = ["ssm:*"]
    resources = ["*"]
  }
}

module "p_ssmconnect" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_ssmconnect
  policy_description = var.p_description_ssmconnect
  policy_json        = data.aws_iam_policy_document.p_ssmconnect.json
}

##############################
# Policy_04
##############################
data "aws_iam_policy_document" "p_cloudtrail_cloudwatchlogs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::582318560864:root"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001/logfile/ALB/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001"]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region_virginia}:${data.aws_caller_identity.current.account_id}:trail/CTR-mcid1${var.env_letter}t-management-event"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001/cloudtraillogs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region_virginia}:${data.aws_caller_identity.current.account_id}:trail/CTR-mcid1${var.env_letter}t-management-event"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:trail/CTR-mcid1${var.env_letter}t-management-event"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tflogs001/cloudtraillogs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:trail/CTR-mcid1${var.env_letter}t-management-event"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

module "p_cloudtrail_cloudwatchlogs" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_cloudtrail_cloudwatchlogs
  policy_description = var.p_description_cloudtrail_cloudwatchlogs
  policy_json        = data.aws_iam_policy_document.p_cloudtrail_cloudwatchlogs.json
}

##############################
# Policy_05
##############################
data "aws_iam_policy_document" "p_ssmconsoledisable" {
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

module "p_ssmconsoledisable" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_ssmconsoledisable
  policy_description = var.p_description_ssmconsoledisable
  policy_json        = data.aws_iam_policy_document.p_ssmconsoledisable.json
}

##############################
# Policy_06
##############################
data "aws_iam_policy_document" "p_swidchrollall" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]
  }
}

module "p_swidchrollall" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_swidchrollall
  policy_description = var.p_description_swidchrollall
  policy_json        = data.aws_iam_policy_document.p_swidchrollall.json
}

##############################
# Policy_07
##############################
data "aws_iam_policy_document" "p_madmin" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/IAM_R_USR_${var.env_letter}c_MAdmin*"]
  }
}

module "p_madmin" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_madmin
  policy_description = var.p_description_madmin
  policy_json        = data.aws_iam_policy_document.p_madmin.json
}

##############################
# Policy_08
##############################
data "aws_iam_policy_document" "p_mmanagement" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/IAM_R_USR_${var.env_letter}c_MManagement*"]
  }
}

module "p_mmanagement" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_mmanagement
  policy_description = var.p_description_mmanagement
  policy_json        = data.aws_iam_policy_document.p_mmanagement.json
}

##############################
# Policy_09
##############################
data "aws_iam_policy_document" "p_nadmin" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/IAM_R_USR_${var.env_letter}c_NAdmin_*"]
  }
}

module "p_nadmin" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_nadmin
  policy_description = var.p_description_nadmin
  policy_json        = data.aws_iam_policy_document.p_nadmin.json
}

##############################
# Policy_10
##############################
data "aws_iam_policy_document" "p_nadminsub" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/IAM_R_USR_${var.env_letter}c_NAdminSub*"]
  }
}

module "p_nadminsub" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_nadminsub
  policy_description = var.p_description_nadminsub
  policy_json        = data.aws_iam_policy_document.p_nadminsub.json
}

##############################
# Policy_11
##############################
data "aws_iam_policy_document" "p_ndba" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/IAM_R_USR_${var.env_letter}c_NDBA*"]
  }
}

module "p_ndba" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_ndba
  policy_description = var.p_description_ndba
  policy_json        = data.aws_iam_policy_document.p_ndba.json
}

##############################
# Policy_12
##############################
data "aws_iam_policy_document" "p_vpcflowlog1" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

module "p_vpcflowlog1" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_vpcflowlog1
  policy_description = var.p_description_vpcflowlog1
  policy_json        = data.aws_iam_policy_document.p_vpcflowlog1.json
}

##############################
# Policy_13
##############################
data "aws_iam_policy_document" "p_sftps3access" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tftpsv001"]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
      "s3:GetObjectAcl",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::S3-mcid1${var.env_letter}1tftpsv001/*"]
  }
}

module "p_sftps3access" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_sftps3access
  policy_description = var.p_description_sftps3access
  policy_json        = data.aws_iam_policy_document.p_sftps3access.json
}

##############################
# Policy_14
##############################
data "aws_iam_policy_document" "p_updates3access" {
  statement {
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:GetStorageLensConfigurationTagging",
      "s3:GetObjectAcl",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetObjectVersionAcl",
      "s3:GetBucketPolicyStatus",
      "s3:GetObjectRetention",
      "s3:GetBucketWebsite",
      "s3:GetJobTagging",
      "s3:GetMultiRegionAccessPoint",
      "s3:GetObjectAttributes",
      "s3:GetObjectLegalHold",
      "s3:GetBucketNotification",
      "s3:DescribeMultiRegionAccessPointOperation",
      "s3:GetReplicationConfiguration",
      "s3:ListMultipartUploadParts",
      "s3:GetObject",
      "s3:DescribeJob",
      "s3:GetAnalyticsConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetAccessPointForObjectLambda",
      "s3:GetStorageLensDashboard",
      "s3:GetLifecycleConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetBucketTagging",
      "s3:GetAccessPointPolicyForObjectLambda",
      "s3:GetBucketLogging",
      "s3:ListBucketVersions",
      "s3:ListBucket",
      "s3:GetAccelerateConfiguration",
      "s3:GetObjectVersionAttributes",
      "s3:GetBucketPolicy",
      "s3:GetEncryptionConfiguration",
      "s3:GetObjectVersionTorrent",
      "s3:GetBucketRequestPayment",
      "s3:GetAccessPointPolicyStatus",
      "s3:GetObjectTagging",
      "s3:GetMetricsConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetMultiRegionAccessPointPolicyStatus",
      "s3:ListBucketMultipartUploads",
      "s3:GetMultiRegionAccessPointPolicy",
      "s3:GetAccessPointPolicyStatusForObjectLambda",
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:GetAccessPointConfigurationForObjectLambda",
      "s3:GetObjectTorrent",
      "s3:GetStorageLensConfiguration",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetAccessPointPolicy",
      "s3:GetObjectVersion",
    ]
    resources = ["arn:aws:s3:::al2022-repos-${var.region_tokyo}-9761ab97"]
    condition {
      test     = "IpAddress"
      variable = "aws:VpcSourceIp"
      values   = ["10.22.60.0/24"]
    }
  }
  statement {
    actions = [
      "s3:ListStorageLensConfigurations",
      "s3:ListAccessPointsForObjectLambda",
      "s3:GetAccessPoint",
      "s3:GetAccountPublicAccessBlock",
      "s3:ListAllMyBuckets",
      "s3:ListAccessPoints",
      "s3:ListJobs",
      "s3:ListMultiRegionAccessPoints"
    ]
    resources = ["*"]
    condition {
      test     = "IpAddress"
      variable = "aws:VpcSourceIp"
      values   = ["10.22.60.0/24"]
    }
  }
}

module "p_updates3access" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_updates3access
  policy_description = var.p_description_updates3access
  policy_json        = data.aws_iam_policy_document.p_updates3access.json
}

##############################
# Policy_15
##############################
data "aws_iam_policy_document" "p_work2s3accessdeny" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

module "p_work2s3accessdeny" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_work2s3accessdeny
  policy_description = var.p_description_work2s3accessdeny
  policy_json        = data.aws_iam_policy_document.p_work2s3accessdeny.json
}

##############################
# Policy_16
##############################
data "aws_iam_policy_document" "p_storagefullaccess" {
  statement {
    actions = [
      "s3:*",
      "s3-object-lambda:*"
    ]
    resources = ["*"]
  }
  statement {
    actions   = []
    resources = ["*"]
  }
  statement {
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticfilesystem.amazonaws.com"]
    }
  }
}

module "p_storagefullaccess" {
  source = "../modules/iam_policy"

  policy_name        = var.p_name_storagefullaccess
  policy_description = var.p_description_storagefullaccess
  policy_json        = data.aws_iam_policy_document.p_storagefullaccess.json
}










### iam_role.tf
##############################
# AssumeRole_01
# - module.r_madmin_mynavinw
# - module.r_mmanagement_mynavinw
##############################
data "aws_iam_policy_document" "assumerole_01" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
  statement {
    effect  = "Deny"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = ["0.0.0.0/0"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
}

##############################
# AssumeRole_02
# - module.r_nadmin_devnw
# - module.r_nadminsub_devnw
# - module.r_ndba_devnw
##############################
data "aws_iam_policy_document" "assumerole_02" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
  statement {
    effect  = "Deny"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values = [
        "101.102.203.197/32",
        "113.33.234.133/32",
        "113.33.89.170/32",
        "113.33.89.171/32",
        "114.156.4.136/29",
        "113.36.236.88/29"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
}

##############################
# AssumeRole_03
# - module.r_nadmin_sv1nw
# - module.r_nadminsub_sv1nw
# - module.r_ndba_sv1nw
##############################
data "aws_iam_policy_document" "assumerole_03" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
  statement {
    effect  = "Deny"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "NotIpAddress"
      variable = "aws:VpcSourceIp"
      values   = ["10.22.59.0/26", "10.22.59.64/26", "10.22.59.128/26"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
}

##############################
# AssumeRole_04
# - module.r_nadmin_sv2nw
# - module.r_nadminsub_sv2nw
# - module.r_ndba_sv2nw
##############################
data "aws_iam_policy_document" "assumerole_04" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
  statement {
    effect  = "Deny"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "NotIpAddress"
      variable = "aws:VpcSourceIp"
      values   = ["10.22.60.0/26", "10.22.60.64/26", "10.22.60.128/26"]
    }

    condition {
      test     = "StringLike"
      variable = "sts:RoleSessionName"
      values   = ["$${aws:username}"]
    }
  }
}

#############################
# AssumeRole_05
# - module.r_cloudwatchlogs
##############################
data "aws_iam_policy_document" "assumerole_05" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

#############################
# AssumeRole_06
# - module.r_flowlog1
##############################
data "aws_iam_policy_document" "assumerole_06" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"]
    }
  }
}

#############################
# AssumeRole_07
# - module.r_sftps3access
##############################
data "aws_iam_policy_document" "assumerole_07" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:transfer:${var.region_tokyo}:${data.aws_caller_identity.current.account_id}:user/*"]
    }
  }
}

#############################
# AssumeRole_08
# - module.r_mcid1d1tbstn001
# - module.r_mcid1d1tvssv001
# - module.r_mcid1d1twork001
# - module.r_mcid1d1twork002
##############################
data "aws_iam_policy_document" "assumerole_08" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

##############################
# Role_01
##############################
module "r_madmin_mynavinw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_madmin_mynavinw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_01.json
  role_policy_arn         = ["arn:aws:iam::aws:policy/AdministratorAccess", module.p_ssmconnect.policy_arn]
}

##############################
# Role_02
##############################
module "r_mmanagement_mynavinw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_mmanagement_mynavinw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_01.json
  role_policy_arn         = ["arn:aws:iam::aws:policy/AdministratorAccess", module.p_ssmconnect.policy_arn]
}

##############################
# Role_03
##############################
module "r_nadmin_devnw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadmin_devnw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_02.json
  role_policy_arn         = ["arn:aws:iam::aws:policy/AdministratorAccess", module.p_ssmconnect.policy_arn]
}

##############################
# Role_04
##############################
module "r_nadmin_sv1nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadmin_sv1nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_03.json
  role_policy_arn         = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

##############################
# Role_05
##############################
module "r_nadmin_sv2nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadmin_sv2nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_04.json
  role_policy_arn         = ["arn:aws:iam::aws:policy/AdministratorAccess", module.p_work2s3accessdeny.policy_arn]
}

##############################
# Role_06
##############################
module "r_nadminsub_devnw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadminsub_devnw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_02.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSBudgetsActions_RolePolicyForResourceAdministrationWithSSM",
    "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    module.p_ssmconnect.policy_arn
  ]
}

##############################
# Role_07
##############################
module "r_nadminsub_sv1nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadminsub_sv1nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_03.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSBudgetsActions_RolePolicyForResourceAdministrationWithSSM",
    "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}

##############################
# Role_08
##############################
module "r_nadminsub_sv2nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_nadminsub_sv2nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_04.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSBudgetsActions_RolePolicyForResourceAdministrationWithSSM",
    "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}

##############################
# Role_09
##############################
module "r_ndba_devnw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_ndba_devnw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_02.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    module.p_ssmconnect.policy_arn
  ]
}

##############################
# Role_10
##############################
module "r_ndba_sv1nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_ndba_sv1nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_03.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  ]
}

##############################
# Role_11
##############################
module "r_ndba_sv2nw" {
  source = "../modules/iam_role"

  role_name               = var.r_name_ndba_sv2nw
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_04.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  ]
}

##############################
# Role_12
##############################
module "r_cloudwatchlogs" {
  source = "../modules/iam_role"

  role_name               = var.r_name_cloudwatchlogs
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_05.json
  role_policy_arn         = [module.p_cloudtrail_cloudwatchlogs.policy_arn]
}

##############################
# Role_13
##############################
module "r_flowlog1" {
  source = "../modules/iam_role"

  role_name               = var.r_name_flowlog1
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_06.json
  role_policy_arn         = [module.p_vpcflowlog1.policy_arn]
}

##############################
# Role_14
##############################
module "r_sftps3access" {
  source = "../modules/iam_role"

  role_name               = var.r_name_sftps3access
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_07.json
  role_policy_arn         = [module.p_sftps3access.policy_arn]
}

##############################
# Role_15
##############################
module "r_mcid1d1tbstn001" {
  source = "../modules/iam_role"

  role_name               = var.r_name_mcid1d1tbstn001
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_08.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

##############################
# Role_16
##############################
module "r_mcid1d1tvssv001" {
  source = "../modules/iam_role"

  role_name               = var.r_name_mcid1d1tvssv001
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_08.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

##############################
# Role_17
##############################
module "r_mcid1d1twork001" {
  source = "../modules/iam_role"

  role_name               = var.r_name_mcid1d1twork001
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_08.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

##############################
# Role_18
##############################
module "r_mcid1d1twork002" {
  source = "../modules/iam_role"

  role_name               = var.r_name_mcid1d1twork002
  assume_role_policy_json = data.aws_iam_policy_document.assumerole_08.json
  role_policy_arn = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    module.p_updates3access.policy_arn
  ]
}








### variables.tf
##############################
# Common
##############################
variable "env_letter" {
  description = ""
  type        = string
  default     = "t"
}

variable "region_tokyo" {
  description = ""
  type        = string
  default     = "ap-northeast-1"
}

variable "region_osaka" {
  description = ""
  type        = string
  default     = "ap-northeast-3"
}

variable "region_virginia" {
  description = ""
  type        = string
  default     = "us-east-1"
}

##############################
# IAM Group
##############################

# IAM Group 01
variable "g_name_nbase" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_N_Base"
}

# IAM Group 02
variable "g_name_madmin" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_M_Admin"
}

# IAM Group 03
variable "g_name_mmanagement" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_M_Management"
}

# IAM Group 04
variable "g_name_nadmin" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_N_Admin"
}

# IAM Group 05
variable "g_name_nadminsub" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_N_AdminSub"
}

# IAM Group 06
variable "g_name_ndba" {
  description = "IAMグループ名"
  type        = string
  default     = "IAM_G_dc_N_DBA"
}

##############################
# IAM Policy
##############################

# IAM Policy 01
variable "p_name_mfaenable" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_MFAenable"
}

variable "p_description_mfaenable" {
  description = "ポリシー説明"
  type        = string
  default     = "Policy to enable your own MFA settings."
}

# IAM Policy 02
variable "p_name_accesskeyenable" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_AccessKeyEnable"
}

variable "p_description_accesskeyenable" {
  description = "ポリシー説明"
  type        = string
  default     = "Policy to enable your AccessKey settings."
}

# IAM Policy 03
variable "p_name_ssmconnect" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_SSMConnect"
}

variable "p_description_ssmconnect" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 04
variable "p_name_cloudtrail_cloudwatchlogs" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dt_CloudTrail_cloudwatchlogs"
}

variable "p_description_cloudtrail_cloudwatchlogs" {
  description = "ポリシー説明"
  type        = string
  default     = "Policy for working with CloudWadch logs from CloudTrail(Tokyo)."
}

# IAM Policy 05
variable "p_name_ssmconsoledisable" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_SSMConsoleDisable"
}

variable "p_description_ssmconsoledisable" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 06
variable "p_name_swidchrollall" {
  description = "IAMポリシー名"
  type        = string
  default     = "Temp_IAM_P_dc_SwidchRollAll"
}

variable "p_description_swidchrollall" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 07
variable "p_name_madmin" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_MAdmin"
}

variable "p_description_madmin" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 08
variable "p_name_mmanagement" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_MManagement"
}

variable "p_description_mmanagement" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 09
variable "p_name_nadmin" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_NAdmin"
}

variable "p_description_nadmin" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 10
variable "p_name_nadminsub" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_NAdminSub"
}

variable "p_description_nadminsub" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 11
variable "p_name_ndba" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_NDBA"
}

variable "p_description_ndba" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 12
variable "p_name_vpcflowlog1" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_VPCFlowLog1"
}

variable "p_description_vpcflowlog1" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 13
variable "p_name_sftps3access" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dt_SFTPs3Access"
}

variable "p_description_sftps3access" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 14
variable "p_name_updates3access" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_UpdateS3Access"
}

variable "p_description_updates3access" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 15
variable "p_name_work2s3accessdeny" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_Work2S3AccessDeny"
}

variable "p_description_work2s3accessdeny" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

# IAM Policy 16
variable "p_name_storagefullaccess" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_P_dc_StorageFullAccess"
}

variable "p_description_storagefullaccess" {
  description = "ポリシー説明"
  type        = string
  default     = ""
}

##############################
# IAM Role
##############################

# IAM Role 01
variable "r_name_madmin_mynavinw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_MAdmin_MynaviNW"
}

# IAM Role 02
variable "r_name_mmanagement_mynavinw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_MManagement_MynaviNW"
}

# IAM Role 03
variable "r_name_nadmin_devnw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdmin_DevNW"
}

# IAM Role 04
variable "r_name_nadmin_sv1nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdmin_SV1NW"
}

# IAM Role 05
variable "r_name_nadmin_sv2nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdmin_SV2NW"
}

# IAM Role 06
variable "r_name_nadminsub_devnw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdminSub_DevNW"
}

# IAM Role 07
variable "r_name_nadminsub_sv1nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdminSub_SV1NW"
}

# IAM Role 08
variable "r_name_nadminsub_sv2nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NAdminSub_SV2NW"
}

# IAM Role 09
variable "r_name_ndba_devnw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NDBA_DevNW"
}

# IAM Role 10
variable "r_name_ndba_sv1nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NDBA_SV1NW"
}

# IAM Role 11
variable "r_name_ndba_sv2nw" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_USR_tc_NDBA_SV2NW"
}

# IAM Role 12
variable "r_name_cloudwatchlogs" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_CTR_dt_CloudWatchLogs"
}

# IAM Role 13
variable "r_name_flowlog1" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_VPC_dc_FlowLog1"
}

# IAM Role 14
variable "r_name_sftps3access" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_TRF_dt_SFTPs3Access"
}

# IAM Role 15
variable "r_name_mcid1d1tbstn001" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_EC2_dt_mcid1d1tbstn001"
}

# IAM Role 16
variable "r_name_mcid1d1tvssv001" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_EC2_dt_mcid1d1tvssv001"
}

# IAM Role 17
variable "r_name_mcid1d1twork001" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_EC2_dt_mcid1d1twork001"
}

# IAM Role 18
variable "r_name_mcid1d1twork002" {
  description = "IAMポリシー名"
  type        = string
  default     = "IAM_R_EC2_dt_mcid1d1twork002"
}



~~~
