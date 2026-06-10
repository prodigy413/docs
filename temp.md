### アカウント

- management
- audit
- log-archive
- infrastructure
- evs-common

### SCP

- ログアーカイブの削除を許可しない。
- ログアーカイブのS3バケットの暗号化設定の変更を許可しない。
- ログアーカイブのS3バケットのログ記録設定の変更を許可しない。
- ログアーカイブのS3バケットのバケットポリシーの変更を許可しない。
- ログアーカイブのS3バケットのパブリック読み取りアクセス設定を検出する。
- ログアーカイブのS3バケットのパブリック書き込みアクセス設定を検出する。
- ログアーカイブのS3バケットのライフサイクル設定の変更を許可しない。
- CloudTrailの設定変更を許可しない。
- CloudTrailログファイルの整合性検証を有効にする。
- AWS Configアグリゲーション認可の削除を許可しない。
- AWS Configの設定変更を許可しない。
- ルートユーザーのアクセスキーの作成を許可しない。
- ルートユーザーのMFAが有効になっているかを検出する。
- IAMユーザーのMFAが有効になっているかを検出する。
- メンバーアカウントが組織を離れるのを禁止する。
- 強力なパスワードポリシーを設定

| 項目                          |   SCPで可能か | 実装方法                               |
| --------------------------- | --------: | ---------------------------------- |
| ログアーカイブS3バケットの削除禁止          |        可能 | SCP                                |
| ログアーカイブS3バケットの暗号化設定変更禁止     |        可能 | SCP                                |
| ログアーカイブS3バケットのログ記録設定変更禁止    |        可能 | SCP                                |
| ログアーカイブS3バケットのバケットポリシー変更禁止  |        可能 | SCP                                |
| パブリック読み取りアクセス設定の検出          |   SCPでは不可 | AWS Config                         |
| パブリック書き込みアクセス設定の検出          |   SCPでは不可 | AWS Config                         |
| ログアーカイブS3バケットのライフサイクル設定変更禁止 |        可能 | SCP                                |
| CloudTrailの設定変更禁止           |        可能 | SCP                                |
| CloudTrailログファイル整合性検証を有効化   |   SCPでは不可 | `aws_cloudtrail`設定                 |
| AWS Configアグリゲーション認可の削除禁止   |        可能 | SCP                                |
| AWS Configの設定変更禁止           |        可能 | SCP                                |
| ルートユーザーのアクセスキー作成禁止          |        可能 | SCP                                |
| ルートユーザーMFAの検出               |   SCPでは不可 | AWS Config                         |
| IAMユーザーMFAの検出               |   SCPでは不可 | AWS Config                         |
| メンバーアカウントの組織離脱禁止            |        可能 | SCP                                |
| 強力なパスワードポリシー設定              | SCPでは設定不可 | IAM password policy / AWS Config検出 |


### グループ

- mck-admin
- mck
- bk-admin
- bk
- nw
- inet

### 許可セット

- org-admin
- workload-operator

### CloudTrail

- org-audit-trail

### S3

- mbt-cmn-management-logs

### IAM Idendity Centerの制約

- アイデンティソースがIdentity Center ディレクトリの場合、パスワードポリシーや有効期限の設定ができない。

### Audit アカウント

- CloudTrail
- Config
- SecurityHub CSPM
- GuardDuty

### Log Archive アカウント

- 各種ログ保管

### Workload用アカウント

- evs
- rosa-prd
- rosa-stg
- ec2
- workspaces

### 流れ (2026/04)

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - Managementアカウント追加
- アカウント追加
  - アカウントを招待
    ```
    aws organizations invite-account-to-organization \
      --target Id=root@test.com,Type=EMAIL \
      --notes "Please join our AWS Organization."
    ```
  - 許可セットをアカウントへ割当
  - AWSコマンド設定
    - メンバーアカウント追加
- CloudTrail作成
  - AuditアカウントをCloudTrail委任管理者に設定
    ```
    aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com
    aws organizations list-aws-service-access-for-organization
    aws cloudtrail register-organization-delegated-admin --member-account-id 123456789
    aws organizations list-delegated-administrators --service-principal cloudtrail.amazonaws.com
    ```
  - Terraformで以下作成
    - S3バケット
    - 証跡
- グループ/権限設定
  - アカウントをTerraformにImport
  - グループ作成
  - 許可セットの作成とアカウントへ割当
  - 初期設定用許可セットを削除
- ユーザー追加
  - Terraformで以下設定
    - ユーザーを作成
    - ユーザーをグループに追加

### 流れ (2026/05/09)

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - 全アカウント設定
- アカウント設定
  - 許可セットをアカウントへ割当
  - AWSコマンド設定
    - メンバーアカウント追加
- グループ/権限設定
  - アカウントをTerraformにImport
  - グループ作成
  - 許可セットの作成とアカウントへ割当
  - 初期設定用許可セットを削除
- ユーザー追加
  - Terraformで以下設定
    - ユーザーを作成
    - ユーザーをグループに追加

### SecurityHub CSPM

- AuditアカウントをSecurityHub CSPMの委任管理者にして、Central Configurationでルートに設定ポリシーおｗ運用するのが基本
- SecurityHub CSPMはOrganizationsと統合後、委任管理者アカウントから組織のアカウント/OUをまたいで複数リージョンに設定可能
- 流れ
  - Organizationsの管理アカウントで、AuditアカウントをSecurityHub CSPMの委任管理者に指定
  - Auditアカウント自身でSecurityHub CSPMを有効化
  - 中央設定を有効にし、設定ポリシーを作成して組織ルートに関連付け
  - 設定ポリシーはアカウント、OU、またはルートに関連付けられ、ルートに運用すると既存の全アカウント/OUに効き、以降追加する新規アカウントも継承
  - 必要に応じて、ホームリージョンとそのリンクリージョンを決める
  - 中央設定のポリシーは、ホームリージョンとそのリンクリージョンすべてに有効です。
  - サマリー
    - Organizationsの管理アカウントでAuditアカウントを委任管理者に指定
    - AuditアカウントでSecurityHub CSPMを有効化
    - 中央設定を開始
    - 東京をホームリージョンに設定
    - 大阪をリンクリージョンに含める
    - 推奨ポリシーまたはカスタムポリシーをルートに関連付ける
    - 併せて、各対象アカウント/リージョンでAWS Configの記録対象が要件を満たしていることを確認する<br>（SecurityHub CSPMのコントロール結果生成にはAWS Configが必要）

### AWS Config

- Organizationsの管理アカウントでAuditアカウントを委任管理者に指定
- 各アカウント・各対象リージョンにConfigruation Recorderを作成して開始
  - AWS公式では、組織全体にRecorderを展開する方法としてAWS system Manager Quick Setupの案内があり、複数のOUや複数リージョンにまたがってCustomer-Managed Configuration Recorderを作成可能

# 最終手順 (2026/06/05)

- IAM Identity Centerを有効
  - 作業ユーザーを登録
  - 許可セットの作成とアカウントへ割当
  - AWSコマンド設定
    - 全アカウント設定
- アカウント設定
  - 許可セットをアカウントへ割当
  - AWSコマンド設定
    - メンバーアカウント追加
- グループ/権限設定
  - アカウントをTerraformにImport
  - グループ作成
  - 許可セットの作成とアカウントへ割当
  - 初期設定用許可セットを削除
- ユーザー追加
  - Terraformで以下設定
    - ユーザーを作成
    - ユーザーをグループに追加

## Billing

Root以外のユーザーにも閲覧できるようにする

- Managementアカウントにrootユーザーでログイン
- 右上のアカウント名をクリック > [アカウント]クリック
- 右側画面の[IAM ユーザーおよびロールによる請求情報へのアクセス]セクション > [編集] > [IAM アクセスをアクティブ化]チェック > [更新]

## AWS Account Management

Managementアカウントから各メンバーアカウント情報とメタデータと操作できるようにする

- AWS Organizations > AWS アカウント[サービス]
- [AWS Account Management]サービスをクリック > [信頼されたアクセスを有効にする]クリック
- 入力欄に`有効化`と書いて[信頼されたアクセスを有効にする]クリック

## IAM Identity Center

組織全体のユーザー管理を中央化するため、IAM Identity Centerを有効にする

- [有効にする]
- AWS リージョン確認 > アジアパシフィック (東京)
- 高度な設定
  - AWS 所有キーを使用する
- [有効にする]

### 設定

- [設定] > [アイデンティティソース]タブ > [アイデンティティソース]が`Identity Center ディレクトリ`であることを確認
- [認証]タブ > 標準認証[設定] > [EメールのOTPを送信]チェック > [保存]

### MFA

- [認証]タブ > 多要素認証[設定]
  - MFA のプロンプトをユーザーに表示
    - サインインごと (常時オン)
  - ユーザーはこれらの MFA タイプで認証できます
    - セキュリティキーと組み込みの認証ツール
    - Authenticator アプリケーション
  - 登録された MFA デバイスをユーザーが持っていない場合
    - サインイン時にMFAデバイスを登録するよう要求する

### AWS access portal URL 確認

- [設定] > [アイデンティティソース]タブ
  - デュアルスタック: ユーザーがAWSコンソールへログイン時に利用するURL
  - 発行者URL: CLI設定時に利用するURL

## Group / Permission Set / Account Assignment

### CLI設定（IAMユーザー）

CLIからManagementアカウントにログイン
```
$ aws login
No AWS region has been configured. The AWS region is the geographic location of your AWS resources.

If you have used AWS before and already have resources in your account, specify which region they were created in. If you have not created resources in your account before, you can pick the region closest to you: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions.html.

You are able to change the region in the CLI at any time with the command "aws configure set region NEW_REGION".
AWS Region [us-east-1]: ap-northeast-1

Attempting to open your default browser. If the browser does not open, open the following URL.
If you are unable to open the URL on this device, run this command again with the '--remote' option.

https://ap-northeast-1.signin.aws.amazon.com/v1/authorize?response_type=code&client_id=xxxxxxxxxxxx

Opening in existing browser session.

Updated profile default to use arn:aws:iam::123456789101:user/xxxx credentials.
```

- [ルートまたは IAM ユーザーで続行]クリック
- Admin権限を持つユーザーでログイン
- 以下画面が表示されたらCLIログインに成功

- 正しいユーザー/アカウント情報が表示されることを確認
```
aws sts get-caller-identity
```

### Managementアカウント名 + タグ設定

Managementアカウント設定はTerraformコードで変更できないため、awsコマンドを利用

```
# アカウント名設定
aws account put-account-name \
  --account-name "management"

# アカウントIDを変数に保存
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text) ; \
  echo $ACCOUNT_ID

# アカウントにタグ追加
aws organizations tag-resource \
  --resource-id ${ACCOUNT_ID} \
  --tags Key=AccountType,Value=management \
    Key=Environment,Value=common \
    Key=ManagedBy,Value=mck \
    Key=Owner,Value=mck
```

### アカウント情報 Import

```
# 作業用ディレクトリに移動
cd ./import ; pwd

# 初期化
terraform init

# コードチェック
terraform validate

# 差分チェック / アカウント設定ダウンロード
terraform plan -generate-config-out=account.tf

# account.tfから不要な行を削除

# Stateファイル作成
## importが「７」であること
## add / change / destroyは「0」であること
terraform apply

# ファイル確認（account.tf / terraform.tfstate）
ls -l
```

### メンバーアカウント名 + タグ設定

`account.tf`に各メンバーアカウント名設定 + タグ追加後、適用

```
# コードチェック
terraform validate

# 差分チェック
terraform plan

# 適用
terraform apply
```

### Group / Permission Set / Account Assignment 設定

```
# Stateファイルコピー
cp terraform.tfstate account.tf ../org/

# 作業用ディレクトリに移動
cd ../org/

# ファイル確認（account.tf / terraform.tfstate）
ls -l

# account.tfにOU設定追加

# 初期化
terraform init

# コードチェック
terraform validate

# 差分チェック
terraform plan

# 適用
terraform apply
```

## ユーザー追加

各グループにユーザーを追加する

```
# 作業用ディレクトリに移動


```

# CLI設定

```
aws organizations list-accounts \
--query 'sort_by(Accounts, &Name)[*].[Name, Id]' \
--output text --profile management \
| tr '\t' ','

while read -r profile; do
  AWS_ID=$(aws sts get-caller-identity --profile "$profile" --query 'Account' --output text)
  echo "${profile},${AWS_ID}"
done << 'EOF'
audit
evs
infrastructure
log-archive
management
system-prd
system-stg
EOF
```
