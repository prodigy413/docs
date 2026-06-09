# AWS Organizations / IAM Identity Center 設計書

本設計書は確定ではなく暫定バージョンであり、各設計はプロジェクトの進行と運用設計に伴って変更可能性が高い。

## 全体設計方針

- 本環境は、AWS Organizations を中心としたマルチアカウント構成とし、アカウントの用途ごとにOUを分離する。
- アクセス管理はIAMユーザーではなくIAM Identity Centerを利用し、グループ単位でPermission Setを割り当てる。これにより、ユーザー単位ではなくチーム・役割単位でAWSアカウントへのアクセス権限を管理する。
- 管理者権限は基盤管理チームに限定し、ワークロード運用者にはPowerUserAccessをベースとしつつ、組織/ユーザー管理・監査・セキュリティ・請求関連サービスの操作を明示的に拒否する。

## AWS Organizations

### Organization構成

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

### OU設計

| OU | 親OU | 用途 |
|---|---|---|
| security | Root | 監査、ログ保管、セキュリティ管理用アカウントを配置するOU |
| infrastructure | Root | ネットワークや共通インフラを管理するアカウントを配置するOU |
| workload | Root | 業務システム、アプリケーション、共通ワークロードを配置する親OU |
| common | workload | 共通ワークロードまたは共通サービス用アカウントを配置するOU |
| prod | workload | 本番環境のワークロード用アカウントを配置するOU |
| non-prod | workload | ステージング、開発等の非本番ワークロード用アカウントを配置するOU |

### OU分離の目的

OUを用途別に分離することで、以下を実現する。

- セキュリティ・監査系アカウントとワークロードアカウントの責務分離
- 本番環境と非本番環境の管理境界の明確化
- 将来的なSCP適用範囲の分離
- チームごとの運用責任範囲の明確化
- アカウント追加時の配置ルールの標準化

## AWSアカウント

### アカウント一覧

| アカウント名 | 所属OU | 使用者 | 管理者 | 主な用途 |
|---|---|---|---|---|
| management | Root | mck | mck | AWS OrganizationsおよびIAM Identity Centerの管理 |
| log-archive | security | mck | mck | ログ保管 |
| audit | security | mck | mck | 監査・セキュリティ管理用 |
| infrastructure | infrastructure | nw/mck | mck | 共通インフラ、ネットワーク基盤管理 |
| evs | workload/common | bk | mck | EVS 共通ワークロード |
| system-prd | workload/prod | bk | mck | EC2/Workspaces 本番ワークロード |
| system-stg | workload/non-prod | bk | mck | EC2 非本番ワークロード |

### 5.2 アカウント別役割

#### management アカウント

- AWS OrganizationsとIAM Identity Centerを管理する中核アカウントである。
- 主な役割は以下とする。
  - Organization全体の管理
  - OUおよびアカウント管理
  - IAM Identity Centerの管理
  - Permission Setの管理
  - アカウント割り当ての管理

このアカウントは組織全体に影響するため、利用者は最小限に限定する。

#### log-archive アカウント

- 組織全体の監査ログや証跡ログを集約・保管するためのアカウントである。
- 想定される用途は以下とする。
  - CloudTrailログの保管
    - 現在CloudTrailログはKyndryl規定により各アカウントに保管
  - AWS Config配信先ログの保管
  - セキュリティ監査用ログの長期保管

#### audit アカウント

- セキュリティ・監査系サービスを集約管理するためのアカウントである。
- 想定される用途は以下とする。
  - AWS Configの集約管理
  - AWS Security Hub CSPMの集約管理
  - GuardDuty等のセキュリティサービス管理
  - 監査・コンプライアンス確認
  - 組織全体のセキュリティ状態の可視化

#### infrastructure アカウント

- 共通インフラストラクチャを管理するためのアカウントである。
- 想定される用途は以下とする。
  - Direct Connect、Transit Gateway等の共通ネットワーク基盤管理
  - 共通インフラリソースの管理
  - ワークロードアカウントとの接続基盤管理

#### evs アカウント

- 共通環境EVSワークロード用アカウントである。
- 想定される用途は以下とする。
  - 共通環境EVSワークロードの実行
  - 該当サービス関連ログ・監視サービス運用<br>
  **※CloudWatchは中央管理が可能なため、要検討**

#### system-prd アカウント

- 本番環境EC2・Workspacesワークロード用アカウントである。
- 想定される用途は以下とする。
  - 本番環境EC2・Workspacesの実行
  - 該当サービス関連ログ・監視サービス運用<br>
  **※CloudWatchは中央管理が可能なため、要検討**

#### system-stg アカウント

- 非本番環境EC2ワークロード用アカウントである。
- 想定される用途は以下とする。
  - 非本番環境EC2の実行
  - 該当サービス関連ログ・監視サービス運用<br>
  **※CloudWatchは中央管理が可能なため、要検討**

## タグ

各アカウントには以下のタグを付与する。

| タグキー | 用途 | 設定例 |
|---|---|---|
| AccountType | アカウント種別 | Management / Security / Infrastructure / Workload |
| ManagedBy | 管理主体 | mck |
| Owner | アカウント利用責任者または利用チーム | mck / bk |
| Environment | 環境区分 | prod / stg / dev / common |

## IAM Identity Center

### 基本方針

- AWSアカウントへのアクセスはIAM Identity Centerを利用する。
- IAM Identity Centerでは以下の構成要素を利用する。
  - Identity Store グループ
  - Permission Set
  - アカウント割り当て

Permission Setはユーザーではなくグループに対して割り当てる。これにより、メンバー変更時の権限管理を簡素化する。

### Identity Store グループ

| グループ名 | 説明 |
|---|---|
| mck-admin | 組織全体の管理者権限を持つMCKメンバー |
| mck | 管理者以外のMCKメンバー |
| bk | 分散基盤チーム |
| nw | AWSネットワークを管理・運用するネットワークチーム |
| inet | Openshiftを利用するインターネットチーム |
| assist | システム移行を担当するAssistチーム<br>**移行完了後、削除予定** |

## Permission Set

### Permission Set一覧

| Permission Set | 説明 | セッション時間 | ベース権限 |
|---|---|---:|---|
| org-admin | 組織全体の管理者権限 | 8時間 | AdministratorAccess |
| workload-operator | Workload利用者権限 | 8時間 | PowerUserAccess + 明示的Deny |

デフォルトのセッション時間が1時間で短くため、8時間に変更

### 8.2 org-admin

- org-adminは、組織全体の管理者向けPermission Setである。
- AWS管理ポリシー AdministratorAccess を付与し、対象アカウントにおいて管理者権限を提供する。

### 8.3 workload-operator

- workload-operatorは、ワークロードおよび一部インフラ運用者向けPermission Setである。
- AWS管理ポリシー PowerUserAccess をベースとするが、Workload以外のサービスに対して明示的Denyを設定する。
- これにより、アプリケーションやワークロード運用に必要な広い権限を提供しつつ、組織全体に影響する管理系操作を制限する。
- 明示的Denyサービス・設定
  - AWS Organizations
  - AWS Account Management
  - AWS Control Tower
  - AWS Control Catalog
  - IAM Identity Center
  - SSO Directory
  - Identity Store
  - CloudTrail
  - AWS Config
  - AWS Audit Manager
  - Security Hub
  - GuardDuty
  - Detective
  - Inspector / Inspector2
  - Macie
  - Security Lake
  - IAM Access Analyzer
  - Firewall Manager
  - AWS Artifact
  - Billing
  - Cost Explorer
  - Budgets
  - Cost and Usage Report
  - Cost Optimization Hub
  - BCM Data Exports
  - Pricing
  - Payments
  - Tax
  - Invoicing
  - Consolidated Billing

## アカウント割り当て

- 全体割当図


### mck-admin（MCK管理者グループ）

- 基盤管理者が全アカウントを管理可能にする
- 組織全体の初期構築・変更・障害対応を可能にする
- 最終的な管理責任を mck-admin に集約する

### bk（分散基盤グループ）

- bkチームが担当ワークロードアカウントを運用できるようにする
- 組織管理・ID管理・監査・請求系の操作は制限する
- 本番・非本番・共通ワークロードに対する運用権限を付与する

### assist（VMWare移行Assitグループ）

- assistチームが担当ワークロードアカウントを運用できるようにする
- 組織管理・ID管理・監査・請求系の操作は制限する
- 本番・非本番・共通ワークロードに対する運用権限を付与する

### nw（ネットワークグループ）

- nwチームがインフラアカウント上のネットワーク関連リソースを運用できるようにする
- 組織管理・ID管理・監査・請求系の操作は制限する
