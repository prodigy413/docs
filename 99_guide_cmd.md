### AWS Organizations 

SCPは自動有効になるが、RCPは有効化必要

- SCP
  - SCP は、Organizations 配下のメンバーアカウントにいる IAMユーザー / IAMロール / そのアカウントの root ユーザー に効きます。
  - SCP が deny している操作は、たとえ IAM ポリシーで allow していても実行できません。SCP 自体は許可を与えず、あくまで上限を決めます。
  - 例1: EC2 を起動できなくする
    - たとえばアカウントに次のような SCP を付けるとします。
      ```
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "DenyRunInstances",
            "Effect": "Deny",
            "Action": "ec2:RunInstances",
            "Resource": "*"
          }
        ]
      }
      ```
    - この場合、そのアカウント内の IAM ロールに AdministratorAccess が付いていても、EC2 インスタンスの新規作成はできません。
    - つまり、人やロールが EC2 起動 API を呼ぶこと自体を止める のが SCP です。
  - この操作を人にさせたくない
- RCP
  - RCP は リソースに対して使える権限の上限 を決めます。
  - AWS 公式では、RCP は組織内リソースに対する最大アクセス許可を一元管理するためのもの、と説明されています。これも許可を与えるものではありません。
  - 感覚的には、SCP が「この人はこの操作をしてはいけない」なら、RCP は「このリソースはそもそもこういう使われ方をしてはいけない」
  - 例1: S3 バケットを組織外から触れなくする
    - たとえば RCP で「この組織の S3 バケットは、組織外の Principal からアクセス不可」といった制約をかけるイメージです。
    - すると、誰かが誤ってバケットポリシーを広く公開しても、RCP 側でその危険なアクセス経路を止める ことができます。
    - このとき止めているのは、「S3 バケットというリソースへのアクセス」
  - 例2: 特定の AWS リソースに対して削除を禁止する
    - たとえば RCP で「組織内の特定条件に合うリソースには削除系アクションを許さない」とすれば、
    - IAM 側で強い権限を持つロールがいても、対象リソースに対する削除操作そのものを防ぐ という考え方です。
  - このリソースを危険な状態にしたくない

### Billing and Cost Management

- 1回コストメニューを開かないとメイン画面からコストが見えない
- Root以外のユーザーにも閲覧できるようにするには「IAM user and role access to Billing information」を有効にする。

### AWS Control Tower

- Version確認：[AWS Control Tower] > [Landing zone settings] > [Current Version]
```
aws controltower list-landing-zones
aws controltower get-landing-zone --landing-zone-identifier <arn>
```
- Controls
  - Frameworks
    - この Frameworks は、ひとことで言うと
    - 「この Control が、どのセキュリティ基準・監査基準の観点で役立つかを示すタグ」

### Access AWS with CLI

- [Configuring IAM Identity Center authentication with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [IAM Identity Center] > [Settings] > [Identity source]tab > Issuer URL
- https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72

```
$ aws configure sso
SSO session name (Recommended): my-sso
SSO start URL [None]: https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72
SSO region [None]: ap-northeast-1
SSO registration scopes [sso:account:access]: sso:account:access
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS1a2FwLW5vcnRoZWFzdC0x&redirect_uri=http%3A%2F%2F127.0.0.1%3A38695%2Foauth%2Fcallback&state=550825fd-72f7-4e97-a547-f6c22564ac52&code_challenge_method=S256&scopes=sso%3Aaccount%3Aaccess&code_challenge=BIcVm1iBpkrJg1Tnmi-QhFg4AzSGWhFz3G5pn8Dreic
There are 2 AWS accounts available to you.
> Audit account, test01@great-obi.net (424388263596)
  Log Archive administrator, test02@great-obi.net (932924000767)
Using the account ID 424388263596
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-424388263596]: audit
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile audit

$ aws configure sso
SSO session name (Recommended): my-sso
There are 2 AWS accounts available to you.
> Log Archive administrator, test02@great-obi.net (932924000767)   
  Audit account, test01@great-obi.net (424388263596)    
Using the account ID 932924000767
The only role available to you is: AWSAdministratorAccess
Using the role name "AWSAdministratorAccess"
Default client Region [None]: ap-northeast-1
CLI default output format (json if not specified) [None]: json
Profile name [AWSAdministratorAccess-932924000767]: logs
To use this profile, specify the profile name using --profile, as shown:

aws sts get-caller-identity --profile logs

$ cat .aws/config 
[profile audit]
sso_session = my-sso
sso_account_id = 424388263596
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json
[sso-session my-sso]
sso_start_url = https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72
sso_region = ap-northeast-1
sso_registration_scopes = sso:account:access
[profile logs]
sso_session = my-sso
sso_account_id = 932924000767
sso_role_name = AWSAdministratorAccess
region = ap-northeast-1
output = json

$ aws sso login --profile audit
Attempting to open your default browser.
If the browser does not open, open the following URL:

https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=6h6Hry2tfWPE5K6D9FS1a2FwLW5vcnRoZWFzdC0x&redirect_uri=http%3A%2F%2F127.0.0.1%3A40743%2Foauth%2Fcallback&state=3421aa14-1270-41bf-b7d0-71c9772f07a1&code_challenge_method=S256&scopes=sso%3Aaccount%3Aaccess&code_challenge=QG99SUhGiHfD5EV4I1J_-fic92envAPkSWnTUk4Lyok
Successfully logged into Start URL: https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72

$ aws s3 ls --profile audit
2026-03-20 20:50:56 aws-controltower-config-access-logs-424388263596-kpk-ykc
2026-03-20 20:51:14 aws-controltower-config-logs-424388263596-kpk-ykc

$ export AWS_PROFILE=audit

$ aws s3 ls
2026-03-20 20:50:56 aws-controltower-config-access-logs-424388263596-kpk-ykc
2026-03-20 20:51:14 aws-controltower-config-logs-424388263596-kpk-ykc

$ ls -l .aws/sso/cache/
total 8
-rw------- 1 aws-org aws-org 3675 Mar 21 22:07 0ad374308c5a4e22f723adf10145eafad7c4031c.json
-rw------- 1 aws-org aws-org 3110 Mar 21 21:57 9e5623eba43e9d2c21bc2e2007ab05a45be31847.json

$ cat .aws/sso/cache/0ad374308c5a4e22f723adf10145eafad7c4031c.json | jq '{expiresAt, registrationExpiresAt, startUrl, region}'
{
  "expiresAt": "2026-03-21T14:07:02Z",
  "registrationExpiresAt": "2026-06-19T12:57:43Z",
  "startUrl": "https://identitycenter.amazonaws.com/ssoins-7758016c1fe6fb72",
  "region": "ap-northeast-1"
}

aws sso login --sso-session my-sso は

その sso-session の SSO access token を新しく取得・更新する
その sso-session を参照する全 profile が、そのログイン済みセッションを使える状態になる

aws sso logout
```

```
aws organizations list-roots

aws organizations list-organizational-units-for-parent  --parent-id r-mbzh

aws organizations list-accounts-for-parent --parent-id r-mbzh

aws organizations list-accounts-for-parent --parent-id ou-mbzh-6zfeddpe

aws organizations list-accounts-for-parent --parent-id ou-mbzh-egwsb4it

aws organizations list-accounts


aws sso-admin list-instances

aws identitystore list-users --identity-store-id d-9567ae5588

aws identitystore describe-user \
  --identity-store-id d-9567ae5588 \
  --user-id d7342ab8-20d1-7012-a579-d51b2ce824de

aws identitystore list-groups --identity-store-id d-9567ae5588

aws identitystore describe-group \
  --identity-store-id d-9567ae5588 \
  --group-id b744daf8-7001-7024-543c-c5e8b0bee5e9

aws identitystore list-group-memberships \
  --identity-store-id d-9567ae5588 \
  --group-id b744daf8-7001-7024-543c-c5e8b0bee5e9

aws sso-admin list-permission-sets-provisioned-to-account \
  --instance-arn arn:aws:sso:::instance/ssoins-7758016c1fe6fb72 \
  --account-id 932924000767

aws sso-admin list-account-assignments \
  --instance-arn arn:aws:sso:::instance/ssoins-7758016c1fe6fb72 \
  --account-id 932924000767 \
  --permission-set-arn arn:aws:sso:::permissionSet/ssoins-7758016c1fe6fb72/ps-7758e92c5c805b6b

aws sso-admin list-account-assignments-for-principal \
  --instance-arn <instance-arn> \
  --principal-type USER \
  --principal-id <user-id>

aws sso-admin list-account-assignments-for-principal \
  --instance-arn <instance-arn> \
  --principal-type GROUP \
  --principal-id <group-id>


aws controltower list-managed-accounts

aws controltower list-baselines

aws controltower list-enabled-baselines

aws controltower list-enabled-controls --target-identifier arn:aws:organizations::140166411949:ou/o-9u795d1hur/ou-mbzh-6zfeddpe

aws controltower list-enabled-controls --target-identifier arn:aws:organizations::140166411949:ou/o-9u795d1hur/ou-mbzh-egwsb4it
```

# Control Tower

## Create OU

- [Organization] > [Create resources]
- Add an OU
  - OU name: `rosa-stg`
  - Parent OU: `Root`
  - [Add]

## Create account

- [Account factory] > [Create account]
- Account details
  - OU name: `rosa-stg`
  - Parent OU: `Root`
  - [Add]

# Organizations

# IAM IDentity Center

# Setup

- リージョンが`アジアパシフィック（東京）`であること

AWS Control Tower > [AWS Control Tower の有効化]クリック

## セットアップ設定を選択

### 管理対象リージョン

- ホームリージョン<br>
  `アジアパシフィック (東京)`固定
- ガバナンスのための追加リージョンを選択 > 以下を選択<br>
  - アジアパシフィック（東京）
  - アジアパシフィック（大阪）
- リージョン拒否コントロール
  - 有効
  - 確認メッセージが表示されたら[確認]クリック

### 自動アカウント登録 

  - [自動アカウント登録をオンにする]チェック

- [次へ]クリック

### 組織単位 (OU) を作成

- 設定を確認後、[組織を作成]クリック
- 作成完了したら、[次へ]クリック

### サービス統合を設定 

- サービス統合のデフォルト OU 
  - 選択された OU
    - Security
- 検出管理の AWS Config
  - [AWS Config の有効化]選択
  - アグリゲーターアカウント > [新規作成]
  - 新規アカウントの作成 (アグリゲーターアカウント)
    - アカウントの作成
    - アカウント名を変更
    - [作成]クリック
  - KMS キーの暗号化
    - [暗号化設定を有効にして、カスタマイズする]チェックしない
  - ログの Amazon S3 バケット設定
    - ログ用の Amazon S3 バケットの保持
      - ログの形式
    - アクセスログ用の Amazon S3 バケットの保持
      - アクセスログの形式
- AWS Cloudtrail 集中型ロギング
  - [AWS Cloudtrail を有効化する]選択
  - CloudTrail 管理者 > [新規作成]
  - 新規アカウントの作成 (CloudTrail 管理者)
    - アカウントの作成
    - アカウント名を変更
    - [作成]クリック
  - KMS キーの暗号化
    - [暗号化設定を有効にして、カスタマイズする]チェックしない
  - ログの Amazon S3 バケット設定
    - ログ用の Amazon S3 バケットの保持
      - ログの形式
    - アクセスログ用の Amazon S3 バケットの保持
      - アクセスログの形式
- AWS IAM アイデンティティセンターのアカウントアクセス
  - [AWS Control Tower は IAM Identity Center を使用して AWS アカウントアクセスを設定します。]選択
- AWS Backup
  - [AWS Backup を有効にする]
  - [AWS Backup を有効にしない]
  - 中央バックアップアカウント > [新規作成]
  - 新規アカウントの作成 (中央バックアップ)
    - アカウントの作成
    - アカウント名を変更
    - [作成]クリック
  - バックアップ管理者アカウント > [新規作成]
  - 新規アカウントの作成 (バックアップ管理者)
    - アカウントの作成
    - アカウント名を変更
    - [作成]クリック
  - バックアップの AWS KMS キー > [KMS キーを作成する]
- [次へ]クリック

### AWS Control Tower を確認して有効にする

- 設定を確認後、[AWS Control Tower の有効]クリック

- 以下まとめること！！
```
Control Towerで管理するOUの削除
[組織単位を登録解除]してから[削除]

Control TowerでOU作成
[組織単位を作成]
OU　を追加
[OU名]
[親OU]
[追加]クリック

Control Tower
[Account Factory] > [アカウントの作成] > []
```