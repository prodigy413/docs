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
  --output text)

# アカウントにタグ追加
aws organizations tag-resource \
  --resource-id ${ACCOUNT_ID} \
  --tags Key=AccountType,Value=management Key=ManagedBy,Value=mck Key=Owner,Value=mck
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

# AWS Organizations / IAM Identity Center 設計書

## 1. 文書概要

本書は、提示されたAWS構成コードをもとに、AWS Organizations、Organizational Unit、AWSアカウント、IAM Identity Center、グループ、Permission Set、アカウント割り当ての設計内容を整理したAWS設計書である。

本書はTerraformコードの設計書ではなく、Terraformで表現されているAWS構成をAWSサービス観点で整理したものである。

## 2. 設計対象範囲

本設計書の対象範囲は以下とする。

- AWS Organizations によるマルチアカウント構成
- Organizational Unit によるアカウント分類
- AWSアカウントの役割設計
- IAM Identity Center による認証・認可設計
- Identity Store グループ設計
- Permission Set 設計
- 管理者・運用者向けアカウントアクセス設計
- Workload運用者に対する権限制御方針

以下は本設計書の対象外とする。

- Terraformコード自体の構成、変数、モジュール、実行方式
- VPC、サブネット、ルーティング等のネットワーク詳細設計
- AWS Config、Security Hub、CloudTrail等の個別サービス構成詳細
- 各アカウント内のアプリケーション構成
- IAM Identity Center のユーザー作成・グループメンバー管理

## 3. 全体設計方針

本環境は、AWS Organizations を中心としたマルチアカウント構成とし、アカウントの用途ごとにOUを分離する。

アクセス管理はIAMユーザーではなくIAM Identity Centerを利用し、グループ単位でPermission Setを割り当てる。これにより、ユーザー単位ではなくチーム・役割単位でAWSアカウントへのアクセス権限を管理する。

管理者権限は基盤管理チームに限定し、ワークロード運用者にはPowerUserAccessをベースとしつつ、Organizations、IAM Identity Center、監査・セキュリティ・請求関連サービスの操作を明示的に拒否する。

## 4. AWS Organizations 設計

### 4.1 Organization構成

AWS Organizations のルート配下に、以下のOUを配置する。

```text
Root
├── security
│   ├── log-archive
│   └── audit
├── infrastructure
│   └── infrastructure
└── workload
    ├── common
    │   └── evs
    ├── prod
    │   └── system-prd
    └── non-prod
        └── system-stg
```

### 4.2 OU設計

| OU | 親OU | 用途 |
|---|---|---|
| security | Root | 監査、ログ保管、セキュリティ管理用アカウントを配置するOU |
| infrastructure | Root | ネットワークや共通インフラを管理するアカウントを配置するOU |
| workload | Root | 業務システム、アプリケーション、共通ワークロードを配置する親OU |
| common | workload | 共通ワークロードまたは共通サービス用アカウントを配置するOU |
| prod | workload | 本番環境のワークロード用アカウントを配置するOU |
| non-prod | workload | ステージング、検証、開発等の非本番ワークロード用アカウントを配置するOU |

### 4.3 OU分離の目的

OUを用途別に分離することで、以下を実現する。

- セキュリティ・監査系アカウントとワークロードアカウントの責務分離
- 本番環境と非本番環境の管理境界の明確化
- 将来的なSCP適用範囲の分離
- チームごとの運用責任範囲の明確化
- アカウント追加時の配置ルールの標準化

## 5. AWSアカウント設計

### 5.1 アカウント一覧

| アカウント名 | 所属OU | AccountType | Owner | ManagedBy | 主な用途 |
|---|---|---|---|---|---|
| management | Root | management | mck | mck | AWS OrganizationsおよびIAM Identity Centerの管理 |
| log-archive | security | Security | mck | mck | ログ保管用アカウント |
| audit | security | Security | mck | mck | 監査・セキュリティ管理用アカウント |
| infrastructure | infrastructure | Infrastructure | mck | mck | 共通インフラ、ネットワーク基盤管理用アカウント |
| evs | workload/common | Workload | bk | mck | 共通または個別ワークロード用アカウント |
| system-prd | workload/prod | Workload | bk | mck | 本番ワークロード用アカウント |
| system-stg | workload/non-prod | Workload | bk | mck | 非本番ワークロード用アカウント |

### 5.2 アカウント別役割

#### management アカウント

AWS OrganizationsとIAM Identity Centerを管理する中核アカウントである。

主な役割は以下とする。

- Organization全体の管理
- OUおよびアカウント管理
- IAM Identity Centerの管理
- Permission Setの管理
- アカウント割り当ての管理

このアカウントは組織全体に影響するため、利用者は最小限に限定する。

#### log-archive アカウント

組織全体の監査ログや証跡ログを集約・保管するためのアカウントである。

想定される用途は以下とする。

- CloudTrailログの保管
- AWS Config配信先ログの保管
- セキュリティ監査用ログの長期保管
- ログ改ざん防止のための分離保管

#### audit アカウント

セキュリティ・監査系サービスを集約管理するためのアカウントである。

想定される用途は以下とする。

- AWS Configの集約管理
- AWS Security Hub CSPMの集約管理
- GuardDuty等のセキュリティサービス管理
- 監査・コンプライアンス確認
- 組織全体のセキュリティ状態の可視化

#### infrastructure アカウント

共通インフラストラクチャを管理するためのアカウントである。

想定される用途は以下とする。

- ネットワーク基盤管理
- Direct Connect、Transit Gateway等の共通ネットワーク管理
- 共通インフラリソースの管理
- ワークロードアカウントとの接続基盤管理

#### evs アカウント

workload/common OUに配置されるワークロードアカウントである。

想定される用途は以下とする。

- 共通ワークロードの実行
- 複数環境で利用する共通サービスの配置
- 本番・非本番に分類しにくい共有用途のシステム配置

#### system-prd アカウント

本番ワークロード用アカウントである。

想定される用途は以下とする。

- 本番アプリケーションの実行
- 本番データを扱うリソースの配置
- 本番環境向けEC2、WorkSpaces等の配置

#### system-stg アカウント

非本番ワークロード用アカウントである。

想定される用途は以下とする。

- ステージング環境の構築
- 検証・テスト用途のリソース配置
- 本番反映前の動作確認

## 6. タグ設計

各アカウントには以下のタグを付与する。

| タグキー | 用途 | 設定例 |
|---|---|---|
| AccountType | アカウント種別を識別する | management / Security / Infrastructure / Workload |
| ManagedBy | 管理主体を識別する | mck |
| Owner | アカウント利用責任者または利用チームを識別する | mck / bk |

### 6.1 タグ設計方針

タグはアカウント管理、責任範囲の明確化、棚卸し、コスト配賦、運用連絡先の識別に利用する。

現時点ではアカウント単位のタグのみ定義されているが、将来的には以下のようなタグ追加も検討する。

| タグキー | 用途例 |
|---|---|
| Environment | prod / stg / dev / common などの環境区分 |
| CostCenter | コスト配賦先 |
| SystemName | システム名 |
| Criticality | 重要度 |
| DataClassification | データ分類 |

## 7. IAM Identity Center 設計

### 7.1 基本方針

AWSアカウントへのアクセスはIAM Identity Centerを利用する。

IAM Identity Centerでは以下の構成要素を利用する。

- Identity Store グループ
- Permission Set
- アカウント割り当て

ユーザーへ直接Permission Setを割り当てるのではなく、グループに対してPermission Setを割り当てる。これにより、メンバー変更時の権限管理を簡素化する。

### 7.2 Identity Store グループ設計

| グループ名 | 説明 | 想定役割 |
|---|---|---|
| mck-admin | MultiCloud Kiban Team Administrators | 組織全体の管理者 |
| mck | MultiCloud Kiban Team | 基盤管理チーム |
| bk | Bunsan Kiban Team | ワークロード運用チーム |
| nw | Network Team | ネットワーク管理チーム |
| inet | Internet Team | インターネット関連管理チーム |
| assist | Assist Team | 運用支援チーム |

現行設計では、アカウント割り当てが設定されている主なグループは以下である。

- mck-admin
- bk
- assist
- nw

mck、inet グループは作成対象であるが、現行設計上はアカウント割り当てが定義されていない。

## 8. Permission Set 設計

### 8.1 Permission Set一覧

| Permission Set | 説明 | セッション時間 | ベース権限 |
|---|---|---:|---|
| org-admin | Organization-wide administrator | 8時間 | AdministratorAccess |
| workload-operator | Workload operator | 8時間 | PowerUserAccess + 明示的Deny |

### 8.2 org-admin

org-adminは、組織全体の管理者向けPermission Setである。

AWS管理ポリシー AdministratorAccess を付与し、対象アカウントにおいて管理者権限を提供する。

利用対象は mck-admin グループとする。

### 8.3 workload-operator

workload-operatorは、ワークロードおよび一部インフラ運用者向けPermission Setである。

AWS管理ポリシー PowerUserAccess をベースとするが、組織管理、ID管理、監査・セキュリティ、請求・コスト管理系サービスに対して明示的Denyを設定する。

これにより、アプリケーションやワークロード運用に必要な広い権限を提供しつつ、組織全体に影響する管理系操作を制限する。

## 9. workload-operator 権限制御設計

### 9.1 制御方針

workload-operatorはPowerUserAccessをベースとするため、多くのAWSサービスに対して作成・変更・削除操作が可能である。

ただし、以下の領域はワークロード運用者が操作すべきではないため、明示的Denyで制限する。

- Organization / Account / Control Tower 管理
- IAM Identity Center / Identity Store 管理
- セキュリティ・監査・ガバナンスサービス管理
- 請求・コスト管理

AWS IAMでは明示的DenyがAllowより優先されるため、PowerUserAccessに含まれる許可よりも、Inline PolicyのDenyが優先される。

### 9.2 Organization / Account / Control Tower 管理の拒否

以下の操作を拒否する。

| サービス | 拒否対象 |
|---|---|
| AWS Organizations | organizations:* |
| AWS Account Management | account:* |
| AWS Control Tower | controltower:* |
| AWS Control Catalog | controlcatalog:* |

目的は以下である。

- OU、アカウント、組織設定の変更防止
- Control Tower管理操作の防止
- ワークロード運用者による組織構成変更の防止

### 9.3 IAM Identity Center / Identity Store 管理の拒否

以下の操作を拒否する。

| サービス | 拒否対象 |
|---|---|
| IAM Identity Center | sso:* |
| SSO Directory | sso-directory:* |
| Identity Store | identitystore:* |

目的は以下である。

- ユーザー・グループ・Permission Setの変更防止
- 権限昇格の防止
- アカウント割り当て変更の防止

### 9.4 セキュリティ・監査・ガバナンスサービス管理の拒否

以下の操作を拒否する。

| 分類 | サービス | 拒否対象 |
|---|---|---|
| ログ・監査 | CloudTrail | cloudtrail:* |
| ログ・監査 | AWS Config | config:* |
| ログ・監査 | AWS Audit Manager | auditmanager:* |
| セキュリティ態勢管理 | Security Hub | securityhub:* |
| 脅威検知 | GuardDuty | guardduty:* |
| 調査・検知 | Detective | detective:* |
| 脆弱性管理 | Inspector / Inspector2 | inspector:* / inspector2:* |
| データ保護 | Macie | macie2:* |
| セキュリティログ基盤 | Security Lake | securitylake:* |
| 権限分析 | IAM Access Analyzer | access-analyzer:* |
| Firewall管理 | Firewall Manager | fms:* |
| コンプライアンス文書 | AWS Artifact | artifact:* |

目的は以下である。

- 監査証跡の停止・改ざん防止
- セキュリティサービスの無効化防止
- ガバナンス設定の変更防止
- 監査・セキュリティ管理をauditアカウントおよび管理者に集約すること

### 9.5 請求・コスト管理の拒否

以下の操作を拒否する。

| サービス領域 | 拒否対象 |
|---|---|
| Billing | billing:* |
| Cost Explorer | ce:* |
| Budgets | budgets:* |
| Cost and Usage Report | cur:* / cur-reporting:* |
| Cost Optimization Hub | cost-optimization-hub:* |
| BCM Data Exports | bcm-data-exports:* |
| Pricing | pricing:* |
| Payments | payments:* |
| Tax | tax:* |
| Invoicing | invoicing:* |
| Consolidated Billing | consolidatedbilling:* |

目的は以下である。

- 請求情報の変更防止
- 予算・レポート設定の変更防止
- 支払い・税務・請求関連操作の制限
- コスト管理責任の分離

## 10. アカウント割り当て設計

### 10.1 管理者グループ mck-admin

mck-admin グループには、全アカウントに対して org-admin を割り当てる。

| グループ | Permission Set | 対象アカウント | 権限レベル |
|---|---|---|---|
| mck-admin | org-admin | management | 管理者 |
| mck-admin | org-admin | audit | 管理者 |
| mck-admin | org-admin | log-archive | 管理者 |
| mck-admin | org-admin | infrastructure | 管理者 |
| mck-admin | org-admin | evs | 管理者 |
| mck-admin | org-admin | system-prd | 管理者 |
| mck-admin | org-admin | system-stg | 管理者 |

設計意図は以下である。

- 基盤管理者が全アカウントを管理可能にする
- 組織全体の初期構築・変更・障害対応を可能にする
- 最終的な管理責任を mck-admin に集約する

### 10.2 ワークロード運用グループ bk

bk グループには、ワークロード系アカウントに対して workload-operator を割り当てる。

| グループ | Permission Set | 対象アカウント | 権限レベル |
|---|---|---|---|
| bk | workload-operator | evs | ワークロード運用者 |
| bk | workload-operator | system-prd | ワークロード運用者 |
| bk | workload-operator | system-stg | ワークロード運用者 |

設計意図は以下である。

- bkチームが担当ワークロードアカウントを運用できるようにする
- 組織管理・ID管理・監査・請求系の操作は制限する
- 本番・非本番・共通ワークロードに対する運用権限を付与する

### 10.3 運用支援グループ assist

assist グループには、infrastructureおよびワークロード系アカウントに対して workload-operator を割り当てる。

| グループ | Permission Set | 対象アカウント | 権限レベル |
|---|---|---|---|
| assist | workload-operator | infrastructure | 運用支援 |
| assist | workload-operator | evs | 運用支援 |
| assist | workload-operator | system-prd | 運用支援 |
| assist | workload-operator | system-stg | 運用支援 |

設計意図は以下である。

- assistチームが対象アカウントの運用支援を行えるようにする
- 管理系・監査系・請求系操作は制限する
- 幅広い支援作業を許可しつつ、組織全体に影響する操作を防止する

### 10.4 ネットワークグループ nw

nw グループには、infrastructureアカウントに対して workload-operator を割り当てる。

| グループ | Permission Set | 対象アカウント | 権限レベル |
|---|---|---|---|
| nw | workload-operator | infrastructure | ネットワーク運用者 |

設計意図は以下である。

- nwチームがインフラアカウント上のネットワーク関連リソースを運用できるようにする
- Organizations、IAM Identity Center、監査・請求系操作は制限する
- ネットワーク運用責任をinfrastructureアカウントに集約する

## 11. 権限マトリクス

| グループ | management | audit | log-archive | infrastructure | evs | system-prd | system-stg |
|---|---|---|---|---|---|---|---|
| mck-admin | org-admin | org-admin | org-admin | org-admin | org-admin | org-admin | org-admin |
| bk | - | - | - | - | workload-operator | workload-operator | workload-operator |
| assist | - | - | - | workload-operator | workload-operator | workload-operator | workload-operator |
| nw | - | - | - | workload-operator | - | - | - |
| mck | - | - | - | - | - | - | - |
| inet | - | - | - | - | - | - | - |

## 12. セキュリティ設計上の考慮事項

### 12.1 管理者権限の集中管理

org-adminはAdministratorAccessを持つため、付与対象をmck-adminに限定する。通常運用ではworkload-operatorを利用し、org-adminの利用は組織管理、初期構築、障害対応などに限定することが望ましい。

### 12.2 明示的Denyによる権限境界

workload-operatorはPowerUserAccessをベースとするが、重要な管理系サービスは明示的Denyで制限している。

この設計により、以下のリスクを低減する。

- Organization構成の変更
- IAM Identity Center設定の変更
- セキュリティサービスの停止
- CloudTrailやConfigの停止
- 請求・コスト管理設定の変更
- 権限昇格につながるID管理操作

### 12.3 audit / log-archive アカウントの保護

auditおよびlog-archiveはセキュリティ・監査上重要なアカウントである。

現行設計では、mck-adminのみが管理者権限を持つ。bk、assist、nwにはこれらのアカウントへの権限は付与されていない。

この分離により、ワークロード運用者による監査証跡やセキュリティ設定への影響を防ぐ。

### 12.4 本番・非本番の分離

system-prdはprod OU、system-stgはnon-prod OUに配置されている。

これにより、将来的に以下のような制御を分離して適用しやすくなる。

- 本番環境向けSCP
- 非本番環境向けSCP
- コスト制限
- リージョン制限
- 本番データ保護ルール
- 変更管理ルール

## 13. 運用設計

### 13.1 アカウント追加時の基本方針

新規アカウントを追加する場合は、用途に応じて以下のOUに配置する。

| 用途 | 配置先OU |
|---|---|
| 監査・ログ・セキュリティ管理 | security |
| ネットワーク・共通インフラ | infrastructure |
| 本番ワークロード | workload/prod |
| 非本番ワークロード | workload/non-prod |
| 共通ワークロード | workload/common |

### 13.2 権限追加時の基本方針

権限追加はユーザー単位ではなくグループ単位で実施する。

新しいチームや役割が必要な場合は、以下の順序で設計する。

1. チームまたは役割に対応するIdentity Storeグループを作成する。
2. 必要な操作範囲を整理する。
3. 既存Permission Setで対応できるか確認する。
4. 対応できない場合のみ新規Permission Setを設計する。
5. 対象アカウントにグループ単位で割り当てる。

### 13.3 Permission Set変更時の注意点

Permission Setを変更する場合は、影響範囲を事前に確認する。

特にworkload-operatorは複数グループ・複数アカウントで利用されるため、Deny対象の追加や削除は以下を確認したうえで実施する。

- 対象グループ
- 対象アカウント
- 既存運用への影響
- セキュリティ上の影響
- 本番環境への影響

## 14. 現行設計から見た改善候補

### 14.1 mck / inet グループの利用方針明確化

mckおよびinetグループは作成されているが、現行設計ではアカウント割り当てがない。

以下のいずれかを明確化することが望ましい。

- 将来利用予定として作成している
- 現時点では不要なため削除する
- 具体的な対象アカウントとPermission Setを追加する

### 14.2 workload-operatorの権限粒度見直し

workload-operatorはPowerUserAccessをベースとしているため、ワークロード運用者としては広めの権限である。

より厳密に制御する場合は、以下のようにPermission Setを分けることを検討する。

| Permission Set案 | 用途 |
|---|---|
| workload-admin | ワークロード管理者向け |
| workload-operator | 通常運用者向け |
| workload-readonly | 参照専用 |
| infra-network-operator | ネットワーク運用者向け |
| support-operator | 運用支援者向け |

### 14.3 本番環境向け権限制御の強化

system-prdに対しては、本番環境向けの追加制御を検討する。

例として以下がある。

- MFA必須化
- 変更作業時のみ一時的に強い権限を付与する運用
- 本番リソース削除操作の制限
- 特定リージョン以外の利用制限
- CloudTrail、Config、GuardDuty等の停止禁止をSCPで実施

### 14.4 SCP設計の追加

本コードではSCPは定義されていない。

Organizations全体のガードレールとして、以下のSCP追加を検討する。

| SCP候補 | 目的 |
|---|---|
| Organizations離脱禁止 | メンバーアカウントの組織離脱防止 |
| CloudTrail停止・削除禁止 | 監査ログ保護 |
| AWS Config停止・削除禁止 | 構成履歴保護 |
| Security Hub停止禁止 | セキュリティ監視維持 |
| GuardDuty停止禁止 | 脅威検知維持 |
| ルートユーザー操作制限 | 高権限操作リスク低減 |
| 利用リージョン制限 | 意図しないリージョン利用防止 |

### 14.5 Break Glass運用の定義

管理者権限を持つmck-adminに加えて、緊急時用のBreak Glass運用を定義することが望ましい。

検討事項は以下である。

- 緊急用アカウントまたはユーザーの管理方法
- MFA必須化
- 利用申請・承認フロー
- 利用後のログ確認
- 通常時は利用しない運用ルール

## 15. 設計まとめ

本設計では、AWS Organizationsを利用して用途別にアカウントを分離し、IAM Identity Centerによりグループベースのアクセス制御を実現している。

主要な設計ポイントは以下である。

- security、infrastructure、workload による責務分離
- workload配下で common / prod / non-prod を分離
- managementアカウントで組織およびID管理を実施
- log-archive / audit をワークロードから分離
- mck-adminには全アカウントの管理者権限を付与
- bk、assist、nwには必要な対象アカウントのみworkload-operator権限を付与
- workload-operatorはPowerUserAccessをベースにしつつ、組織管理、ID管理、監査・セキュリティ、請求系操作を明示的に拒否

この構成により、基盤管理者、ワークロード運用者、ネットワーク運用者、運用支援者の責務を分離しながら、マルチアカウント環境を統制しやすい構成としている。
