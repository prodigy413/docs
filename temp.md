```
# Add account to organization
resource "aws_organizations_account" "account" {
  name  = "Audit"
  email = "test@test.com"
}

# create permission set for account
resource "aws_ssoadmin_permission_set" "permission_set" {
  name             = "AdministratorAccess"
  description      = "AdministratorAccess"
  instance_arn     = aws_ssoadmin_instance.sso_instance.arn
  session_duration = "PT1H"
  tags = {
    "Environment" = "Production"
  }
}

aws sso login --sso-session my-sso --use-device-code




{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSSLRequestsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4",
                "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
        {
            "Sid": "AWSBucketPermissionsCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4"
        },
        {
            "Sid": "AWSConfigBucketExistenceCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4"
        },
        {
            "Sid": "AWSBucketDeliveryForOrganizationTrail",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": [
                "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4/organization-id/AWSLogs/accound-id-coludtrail-boss/*",
                "arn:aws:s3:::aws-controltower-cloudtrail-logs-accound-id-ba4-bh4/organization-id/AWSLogs/organization-id/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceOrgID": "organization-id"
                }
            }
        }
    ]
}



```

# IAM Identity Center

- [有効にする]
- AWS リージョン確認 > アジアパシフィック (東京)
- 高度な設定
  - AWS 所有キーを使用する
- [有効にする]

### 設定

- [設定] > [アイデンティティソース]タブ
- [認証]タブ > 標準認証[設定] > [E メールの OTP を送信]チェック > [保存]

### MFA

- [認証]タブ > 多要素認証[設定]
  - MFA のプロンプトをユーザーに表示
    - サインインごと (常時オン)
  - ユーザーはこれらの MFA タイプで認証できます
    - セキュリティキーと組み込みの認証ツール
    - Authenticator アプリケーション
  - 登録された MFA デバイスをユーザーが持っていない場合
    - サインイン時に MFA デバイスを登録するよう要求する
- 発行者 URL
