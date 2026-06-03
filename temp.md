```
# AWS Config / Security Hub CSPM 中央管理設計書

## 1. 目的

本設計書は、AWS Organizations を利用したマルチアカウント環境において、AWS Config および AWS Security Hub CSPM を中央管理するための基本設計を定義する。

本設計では、以下を実現する。

- 全 AWS アカウントで AWS Config を有効化する
- 各アカウントの AWS Config 設定履歴を中央 S3 バケットへ集約する
- audit アカウントを AWS Config の委任管理アカウントとして設定する
- audit アカウントに AWS Config Aggregator を構成し、組織全体のリソース設定情報を集約する
- audit アカウントを Security Hub CSPM の委任管理アカウントとして設定する
- Security Hub CSPM の Central Configuration を利用して、組織全体へセキュリティ基準を適用する

---

## 2. 設計方針

本環境では、AWS Config と Security Hub CSPM を以下の方針で設計する。

| 方針 | 内容 |
|---|---|
| 監査機能の中央管理 | audit アカウントを中心に Config / Security Hub CSPM を管理する |
| 設定履歴の集約 | 各アカウントの AWS Config 設定履歴を中央 S3 バケットへ保存する |
| 組織単位の可視化 | AWS Config Aggregator により、全アカウント・全リージョンの設定情報を集約する |
| セキュリティ基準の統一 | Security Hub CSPM Central Configuration により、組織全体に共通のセキュリティ基準を適用する |
| 管理アカウントの役割限定 | management アカウントは trusted access と委任管理者設定に限定する |
| 監査ログの保護 | Config ログ保存用 S3 バケットでは暗号化、バージョニング、ライフサイクル、SSL 強制を行う |

---

## 3. 全体構成

本設計では、management アカウント、audit アカウント、各メンバーアカウントが以下の役割を持つ。

```text
AWS Organizations
├── management account
│   ├── AWS Config trusted access 有効化
│   ├── AWS Config Multi-Account Setup trusted access 有効化
│   ├── audit アカウントを AWS Config 委任管理者に登録
│   ├── Security Hub trusted access 有効化
│   └── audit アカウントを Security Hub 委任管理者に登録
│
├── audit account
│   ├── AWS Config ログ保存用 S3 バケット
│   ├── AWS Config Recorder
│   ├── AWS Config Delivery Channel
│   ├── AWS Config Organization Aggregator
│   ├── Security Hub CSPM
│   ├── Security Hub Finding Aggregator
│   ├── Security Hub Central Configuration
│   └── Security Hub Configuration Policy
│
└── member accounts
    ├── management
    ├── infrastructure
    ├── audit
    ├── evs
    └── system-stg
        └── AWS Config Recorder / Delivery Channel
```

---

## 4. AWS Config 設計

### 4.1 基本方針

AWS Config は、各 AWS アカウントおよび各リージョンのリソース設定状態を記録するために利用する。

本設計では、各アカウントに AWS Config Recorder と Delivery Channel を構成し、設定履歴を audit アカウントの S3 バケットに保存する。

また、audit アカウントに AWS Config Aggregator を構成し、組織全体の Config 情報を集約する。

---

### 4.2 AWS Config 有効化対象アカウント

本設計では、以下のアカウントで AWS Config を有効化する。

| アカウント | 用途 | AWS Config |
|---|---|---|
| management | 組織管理 | 有効化 |
| infrastructure | 共通基盤・ネットワーク | 有効化 |
| audit | 監査・セキュリティ管理 | 有効化 |
| evs | 共通ワークロード | 有効化 |
| system-stg | ステージングワークロード | 有効化 |

必要に応じて、system-prd などの本番アカウントにも同様の構成を追加する。

---

### 4.3 AWS Config Recorder 設計

各アカウントでは、AWS Config Configuration Recorder を作成する。

| 項目 | 設計値 |
|---|---|
| Recorder 名 | default |
| 記録対象 | サポートされる全リソース |
| グローバルリソース | 記録対象に含める |
| IAM ロール | AWS Config Service-linked Role |
| ロール名 | AWSServiceRoleForConfig |

AWS Config Recorder では、`all_supported = true` とし、AWS Config がサポートするリソースを記録対象とする。

また、`include_global_resource_types = true` とし、IAM などのグローバルリソースも記録対象に含める。

---

### 4.4 AWS Config Service-linked Role 設計

各アカウントでは、AWS Config 用の Service-linked Role を利用する。

| 項目 | 内容 |
|---|---|
| サービス名 | config.amazonaws.com |
| ロール名 | AWSServiceRoleForConfig |
| ロール ARN | arn:aws:iam::<account-id>:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig |
| 付与ポリシー | AWSConfigServiceRolePolicy |

AWS Config の Service-linked Role は、AWS Config がリソース設定情報を取得するために利用する。

---

### 4.5 AWS Config Delivery Channel 設計

AWS Config Delivery Channel は、Config の設定履歴およびスナップショットを S3 バケットへ配信するために利用する。

| 項目 | 設計値 |
|---|---|
| Delivery Channel 名 | default |
| 配信先 S3 バケット | Config ログ保存用 S3 バケット |
| S3 キープレフィックス | AWS Organizations の Organization ID |
| 最終保存パス | s3://<bucket>/<organization-id>/AWSLogs/<account-id>/Config/<region>/... |

S3 キープレフィックスに Organization ID を利用することで、組織単位のログ保存構造を明確にする。

---

## 5. AWS Config 組織連携設計

### 5.1 Trusted Access 設計

management アカウントでは、AWS Organizations と AWS Config の連携を有効化する。

有効化するサービスプリンシパルは以下とする。

| サービスプリンシパル | 用途 |
|---|---|
| config.amazonaws.com | AWS Config の Organizations 連携 |
| config-multiaccountsetup.amazonaws.com | AWS Config Multi-Account Setup の Organizations 連携 |

Trusted Access を有効化することで、AWS Config が AWS Organizations 配下のアカウント情報を利用できるようにする。

---

### 5.2 委任管理者設計

AWS Config の委任管理アカウントとして、audit アカウントを登録する。

| 項目 | 設計値 |
|---|---|
| 委任管理アカウント | audit |
| 対象サービス | AWS Config |
| サービスプリンシパル | config.amazonaws.com |
| 追加サービスプリンシパル | config-multiaccountsetup.amazonaws.com |

management アカウントは Organizations の管理操作を行い、Config の実運用管理は audit アカウントで行う。

---

## 6. AWS Config ログ保存用 S3 バケット設計

### 6.1 基本方針

AWS Config の設定履歴は、audit アカウントの S3 バケットに集約して保存する。

ログ保存用 S3 バケットでは、以下を有効化する。

- バージョニング
- ライフサイクル管理
- SSL 通信の強制
- AWS Config サービスからの書き込み許可
- AWS Organizations ID による書き込み元制限

---

### 6.2 S3 バケット設計

| 項目 | 設計値 |
|---|---|
| 配置アカウント | audit |
| 用途 | AWS Config ログ保存 |
| バージョニング | 有効 |
| ライフサイクル | 有効 |
| SSL 通信 | 強制 |
| 書き込み元 | AWS Config サービス |
| 書き込み条件 | SourceOrgID が自組織 ID と一致すること |

---

### 6.3 バージョニング設計

Config ログ保存用 S3 バケットでは、バージョニングを有効化する。

| 項目 | 設計値 |
|---|---|
| バージョニング | Enabled |

バージョニングを有効化することで、誤削除や上書きに対する保護を強化する。

---

### 6.4 ライフサイクル設計

Config ログ保存用 S3 バケットでは、保存期間とコスト最適化を目的としてライフサイクルルールを設定する。

| 経過日数 | アクション |
|---|---|
| 90日後 | STANDARD_IA へ移行 |
| 365日後 | GLACIER へ移行 |
| 2555日後 | オブジェクトを削除 |
| 非現行バージョン 365日後 | 非現行バージョンを削除 |

2555日は約7年に相当するため、長期監査要件を想定した保存期間として扱う。

---

### 6.5 S3 バケットポリシー設計

Config ログ保存用 S3 バケットには、以下のポリシーを設定する。

| Sid | Effect | 内容 |
|---|---|---|
| AllowSSLRequestsOnly | Deny | SSL ではない S3 アクセスを拒否する |
| AWSConfigBucketPermissionsCheck | Allow | AWS Config に GetBucketAcl を許可する |
| AWSConfigBucketExistenceCheck | Allow | AWS Config に ListBucket を許可する |
| AWSConfigBucketDelivery | Allow | AWS Config に PutObject を許可する |

---

### 6.6 SSL 強制

S3 バケットでは、`aws:SecureTransport = false` のアクセスを拒否する。

これにより、HTTP による非暗号化通信を禁止し、HTTPS 通信のみを許可する。

---

### 6.7 AWS Config 書き込み許可

AWS Config サービスに対して、以下の操作を許可する。

| アクション | 目的 |
|---|---|
| s3:GetBucketAcl | バケット ACL 確認 |
| s3:ListBucket | バケット存在確認 |
| s3:PutObject | Config ログ配信 |

---

### 6.8 書き込み先パス

AWS Config のログは、以下のパスに保存する。

```text
s3://<config-bucket>/<organization-id>/AWSLogs/<account-id>/Config/<region>/...
```

この構造により、Organization ID、アカウント ID、リージョン単位で Config ログを識別できる。

---

## 7. AWS Config Aggregator 設計

### 7.1 基本方針

audit アカウントに AWS Config Configuration Aggregator を作成し、組織全体の AWS Config 情報を集約する。

これにより、複数アカウント・複数リージョンのリソース設定状態を audit アカウントから確認できるようにする。

---

### 7.2 Aggregator 設計

| 項目 | 設計値 |
|---|---|
| 配置アカウント | audit |
| Aggregator 名 | organization-config-aggregator |
| 集約対象 | AWS Organizations 配下の全アカウント |
| 対象リージョン | 全リージョン |
| all_regions | true |
| 利用ロール | aws-config-organization-aggregator-role |

---

### 7.3 Aggregator 用 IAM ロール設計

AWS Config Aggregator が Organizations 配下の情報を取得するため、audit アカウントに IAM ロールを作成する。

| 項目 | 設計値 |
|---|---|
| ロール名 | aws-config-organization-aggregator-role |
| 信頼先 | config.amazonaws.com |
| 付与ポリシー | AWSConfigRoleForOrganizations |
| 用途 | AWS Config Organization Aggregator 用 |

---

## 8. Security Hub CSPM 設計

### 8.1 基本方針

Security Hub CSPM は、AWS Organizations 全体のセキュリティ検出結果を中央管理するために利用する。

本設計では、audit アカウントを Security Hub の委任管理アカウントとして設定し、Central Configuration により組織全体へ共通の Security Hub CSPM 設定を適用する。

---

### 8.2 Security Hub 有効化設計

audit アカウントで Security Hub を有効化する。

| 項目 | 設計値 |
|---|---|
| 配置アカウント | audit |
| Security Hub | 有効 |
| デフォルトスタンダード | 無効 |
| enable_default_standards | false |

デフォルトスタンダードは自動有効化せず、Central Configuration の Configuration Policy で有効化する基準を明示的に管理する。

---

### 8.3 Security Hub Trusted Access 設計

management アカウントでは、AWS Organizations と Security Hub の連携を有効化する。

| 項目 | 設計値 |
|---|---|
| サービスプリンシパル | securityhub.amazonaws.com |
| 実行アカウント | management |
| 目的 | Security Hub の Organizations 連携 |

---

### 8.4 Security Hub 委任管理者設計

Security Hub の委任管理アカウントとして audit アカウントを登録する。

| 項目 | 設計値 |
|---|---|
| 委任管理アカウント | audit |
| 対象サービス | Security Hub |
| 登録元 | management |
| 管理方式 | Organizations 連携 |

---

### 8.5 Finding Aggregator 設計

Security Hub Finding Aggregator は、Security Hub の検出結果を集約するために利用する。

| 項目 | 設計値 |
|---|---|
| 配置アカウント | audit |
| linking_mode | NO_REGIONS |
| 指定リージョン | なし |

本設計では、`NO_REGIONS` を指定しているため、Security Hub の Finding Aggregator では追加リージョンをリンクしない。

複数リージョンの Finding を集約したい場合は、`SPECIFIED_REGIONS` を利用し、集約対象リージョンを明示する必要がある。

---

### 8.6 Central Configuration 設計

Security Hub CSPM では、Central Configuration を有効化する。

| 項目 | 設計値 |
|---|---|
| 配置アカウント | audit |
| configuration_type | CENTRAL |
| auto_enable | false |
| auto_enable_standards | NONE |

Central Configuration を利用することで、委任管理アカウントから組織全体の Security Hub CSPM 設定を一元管理できる。

---

### 8.7 Configuration Policy 設計

Security Hub CSPM の Configuration Policy として、組織共通のベースラインポリシーを作成する。

| 項目 | 設計値 |
|---|---|
| ポリシー名 | org-securityhub-baseline |
| 説明 | Organization-wide Security Hub CSPM baseline policy |
| service_enabled | true |

---

### 8.8 有効化するセキュリティ標準

Configuration Policy では、以下の Security Hub 標準を有効化する。

| 標準 | バージョン |
|---|---|
| AWS Foundational Security Best Practices | 1.0.0 |
| CIS AWS Foundations Benchmark | 5.0.0 |

必要に応じて、利用環境や準拠要件に合わせて有効化する標準を追加・変更する。

---

### 8.9 無効化するコントロール

本設計では、無効化する Security Hub コントロールは初期状態では指定しない。

ただし、環境要件に合わないコントロールがある場合は、例外として無効化対象に追加する。

例:

```text
EC2.10
S3.5
```

無効化する場合は、必ず理由、対象アカウント、対象 OU、承認者、見直し期限を記録する。

---

### 8.10 Configuration Policy Association 設計

作成した Security Hub CSPM Configuration Policy は、AWS Organizations の Root に関連付ける。

| 項目 | 設計値 |
|---|---|
| 関連付け先 | AWS Organizations Root |
| 適用範囲 | 組織配下の全アカウント |
| Policy | org-securityhub-baseline |

Root に関連付けることで、組織全体に共通の Security Hub CSPM 設定を適用する。

---

## 9. アカウント別役割

| アカウント | 役割 |
|---|---|
| management | Organizations trusted access 有効化、委任管理者登録 |
| audit | Config ログ保存、Config Aggregator、Security Hub CSPM 中央管理 |
| infrastructure | AWS Config 記録対象 |
| evs | AWS Config 記録対象 |
| system-stg | AWS Config 記録対象 |

---

## 10. データフロー

### 10.1 AWS Config ログ保存フロー

```text
各AWSアカウント
  └── AWS Config Recorder
        └── Delivery Channel
              └── audit アカウントの S3 バケット
                    └── <organization-id>/AWSLogs/<account-id>/Config/<region>/...
```

---

### 10.2 AWS Config Aggregator フロー

```text
各AWSアカウント / 各リージョン
  └── AWS Config
        └── audit アカウントの AWS Config Aggregator
              └── 組織全体のリソース設定状態を集約表示
```

---

### 10.3 Security Hub CSPM 管理フロー

```text
management アカウント
  └── audit アカウントを Security Hub 委任管理者に登録

audit アカウント
  └── Security Hub Central Configuration
        └── Configuration Policy
              └── AWS Organizations Root に関連付け
                    └── 組織配下アカウントへ適用
```

---

## 11. 運用設計

### 11.1 AWS Config 運用

AWS Config では、以下を定期的に確認する。

| 確認項目 | 内容 |
|---|---|
| Recorder 状態 | 各アカウントで AWS Config Recorder が有効か |
| Delivery Channel | S3 バケットへ正常に配信されているか |
| S3 保存状況 | Config ログが想定パスに保存されているか |
| Aggregator 状態 | 全アカウント・全リージョンの情報が集約されているか |
| IAM ロール | Config 用 Service-linked Role が存在するか |

---

### 11.2 Security Hub CSPM 運用

Security Hub CSPM では、以下を定期的に確認する。

| 確認項目 | 内容 |
|---|---|
| Security Hub 有効化状態 | audit アカウントで Security Hub が有効か |
| 委任管理者 | audit アカウントが委任管理者として登録されているか |
| Central Configuration | CENTRAL モードで構成されているか |
| Configuration Policy | ベースラインポリシーが存在するか |
| Policy Association | Organization Root に関連付けられているか |
| Findings | 重大度の高い Finding が発生していないか |

---

### 11.3 S3 バケット運用

Config ログ保存用 S3 バケットでは、以下を確認する。

| 確認項目 | 内容 |
|---|---|
| バージョニング | 有効化されているか |
| ライフサイクル | 想定通り STANDARD_IA / GLACIER へ移行されているか |
| SSL 強制 | 非 SSL アクセスが拒否されているか |
| バケットポリシー | AWS Config のみが必要な操作を実行できるか |
| 保存期間 | 監査要件に合致しているか |

---

## 12. セキュリティ設計上の注意点

### 12.1 management アカウントの利用制限

management アカウントでは、以下の操作に限定する。

- AWS Organizations の trusted access 有効化
- 委任管理アカウントの登録
- 組織全体の管理設定
- 請求・契約関連管理

Config や Security Hub の日常運用は audit アカウントで実施する。

---

### 12.2 audit アカウントの保護

audit アカウントは、組織全体の監査・セキュリティ情報を管理する重要アカウントである。

そのため、以下の制御を推奨する。

- 管理者を最小限に限定する
- MFA を必須化する
- CloudTrail / Config / Security Hub / GuardDuty の停止を SCP で禁止する
- Config ログ保存用 S3 バケットの削除・ポリシー変更を制限する
- Security Hub Configuration Policy の変更権限を限定する

---

### 12.3 Config ログ保存用 S3 バケットの保護

Config ログ保存用 S3 バケットでは、以下を推奨する。

- バケット削除禁止
- バケットポリシー変更禁止
- バージョニング無効化禁止
- ライフサイクル変更制限
- パブリックアクセス禁止
- 非 SSL アクセス禁止

これらは IAM ポリシーだけではなく、SCP や S3 Bucket Policy も併用して保護する。

---

### 12.4 Security Hub CSPM の例外管理

Security Hub の一部コントロールを無効化する場合は、以下を記録する。

| 項目 | 内容 |
|---|---|
| 無効化コントロール | 例: EC2.10 |
| 無効化理由 | 環境要件、設計上の例外など |
| 対象範囲 | OU、アカウント、リージョン |
| 承認者 | セキュリティ責任者 |
| 見直し期限 | 例外の再評価日 |

例外設定は恒久的な無効化ではなく、定期的に見直す前提とする。

---

## 13. 設計上の改善ポイント

### 13.1 system-stg の provider 指定

添付構成では、`config-recorder-system-stg` の provider が `aws.evs` になっている。

設計上、system-stg アカウントに AWS Config を構成する場合は、system-stg 用 provider を利用する必要がある。

推奨:

```text
system-stg アカウント用の provider を定義し、system-stg に対して Config Recorder を構成する。
```

---

### 13.2 log-archive アカウントの位置付け

コメント上は `log-archive account` と記載されているが、実際の構成では Config ログ保存用 S3 バケットが audit アカウントに配置されている。

設計としては、以下のどちらかに統一する必要がある。

| 案 | 内容 |
|---|---|
| 案1 | audit アカウントに Config ログ保存用 S3 バケットを配置する |
| 案2 | log-archive アカウントを別途用意し、Config ログ保存専用にする |

セキュリティ分離を重視する場合は、audit アカウントと log-archive アカウントを分離することを推奨する。

---

### 13.3 Security Hub Finding Aggregator の linking_mode

本設計では、Finding Aggregator の `linking_mode` が `NO_REGIONS` になっている。

この設定では追加リージョンをリンクしないため、複数リージョンの Finding 集約を目的とする場合は、`SPECIFIED_REGIONS` を利用する。

設計判断として、以下を明確にする必要がある。

| 設定 | 用途 |
|---|---|
| NO_REGIONS | ホームリージョンのみで管理する |
| SPECIFIED_REGIONS | 指定した複数リージョンの Finding を集約する |
| ALL_REGIONS | 対応する全リージョンを集約対象にする |

---

### 13.4 Security Hub 標準のバージョン管理

Security Hub の標準 ARN にはバージョンが含まれる。

そのため、以下を運用で確認する。

- 利用中の標準バージョン
- 新バージョンの提供有無
- 既存 Finding への影響
- コントロール追加・削除の影響

---

## 14. 最終構成サマリー

### 14.1 AWS Config

```text
management account
- AWS Config trusted access 有効化
- audit アカウントを Config 委任管理者に登録

audit account
- Config ログ保存用 S3 バケット
- Config Recorder
- Config Delivery Channel
- Config Organization Aggregator

member accounts
- Config Recorder
- Config Delivery Channel
- audit アカウントの S3 バケットへ Config ログを配信
```

---

### 14.2 Security Hub CSPM

```text
management account
- Security Hub trusted access 有効化
- audit アカウントを Security Hub 委任管理者に登録

audit account
- Security Hub 有効化
- Finding Aggregator 構成
- Central Configuration 有効化
- Configuration Policy 作成
- Organization Root へ Policy Association

member accounts
- Security Hub CSPM Configuration Policy の適用対象
```

---

### 14.3 中央管理方針

```text
Config / Security Hub CSPM の日常運用:
- audit アカウントで実施

Organizations 連携・委任管理者登録:
- management アカウントで実施

Config ログ保存:
- audit または log-archive アカウントの S3 バケットに集約

セキュリティ基準:
- Security Hub CSPM Central Configuration で組織全体に適用
```

# Claude

# AWS Config / Security Hub 組織集約 設計書

**対象**: AWS Config（組織アグリゲータ） / AWS Security Hub（中央設定）
**作成**: MultiCloud Kiban Team
**Version**: 1.0

---

## 目次

- [1. 概要](#1-概要)
  - [1.1 本書の目的](#11-本書の目的)
  - [1.2 設計方針](#12-設計方針)
  - [1.3 アカウント役割](#13-アカウント役割)
- [2. AWS Config 設計](#2-aws-config-設計)
  - [2.1 全体構成](#21-全体構成)
  - [2.2 組織レベルの有効化（management アカウント）](#22-組織レベルの有効化management-アカウント)
  - [2.3 委任管理者（audit アカウント）](#23-委任管理者audit-アカウント)
  - [2.4 ログ集約バケット（audit アカウント）](#24-ログ集約バケットaudit-アカウント)
  - [2.5 Configuration Recorder / Delivery Channel（各アカウント）](#25-configuration-recorder--delivery-channel各アカウント)
  - [2.6 組織アグリゲータ（audit アカウント）](#26-組織アグリゲータaudit-アカウント)
- [3. Security Hub 設計](#3-security-hub-設計)
  - [3.1 全体構成](#31-全体構成)
  - [3.2 有効化と委任管理者](#32-有効化と委任管理者)
  - [3.3 Finding Aggregator](#33-finding-aggregator)
  - [3.4 中央設定（Central Configuration）](#34-中央設定central-configuration)
  - [3.5 構成ポリシー（CSPM ベースライン）](#35-構成ポリシーcspm-ベースライン)
- [4. データフロー](#4-データフロー)
- [5. 留意事項](#5-留意事項)

---

## 1. 概要

### 1.1 本書の目的

本書は、AWS Organizations 配下の複数アカウントに対し、構成情報（AWS Config）とセキュリティ検出結果（Security Hub）を組織全体で集約・統制する仕組みの設計内容を定義する。集約先は audit アカウントとし、各サービスとも委任管理者方式で運用する。

### 1.2 設計方針

- **集約先の集中**: Config の構成情報および Security Hub の検出結果を audit アカウントに集約する。
- **委任管理者方式**: management アカウントから audit アカウントへ各サービスの委任管理者権限を付与し、日常の管理操作は audit アカウントで行う。
- **組織全体の自動展開**: 信頼されたアクセス（trusted access）を有効化し、組織単位で Config・Security Hub を展開する。
- **ログの安全な保管**: 集約用 S3 バケットでバージョニング・ライフサイクル・SSL 強制・送信元組織制限を適用する。

### 1.3 アカウント役割

| アカウント | 役割 |
| --- | --- |
| management | 組織管理。信頼されたアクセスの有効化、委任管理者の登録を行う。 |
| audit | 委任管理者。ログ集約 S3 バケット、Config 組織アグリゲータ、Security Hub 中央設定を保持する。 |
| 各メンバーアカウント | Config Recorder / Delivery Channel を稼働させ、構成情報を集約バケットへ配信する。 |

> ※ コード上のコメントには「log-archive account」「Control Tower-style」という表現があるが、実装上ログを集約するアカウントは audit アカウント（`provider = aws.audit`）である。本書は実装に従い audit アカウントとして記述する。

---

## 2. AWS Config 設計

### 2.1 全体構成

各アカウントで Config Recorder を稼働させ、すべての対応リソース（グローバルリソースを含む）を記録する。記録結果は audit アカウントの S3 バケットへ集約し、audit アカウントの組織アグリゲータで全リージョン・全アカウントの構成情報を一元的に参照できるようにする。

### 2.2 組織レベルの有効化（management アカウント）

management アカウントで、Organizations に対する Config の信頼されたアクセスを有効化する。

| 項目 | 内容 |
| --- | --- |
| 信頼されたアクセス | `config.amazonaws.com` |
| 信頼されたアクセス（マルチアカウント設定） | `config-multiaccountsetup.amazonaws.com` |

### 2.3 委任管理者（audit アカウント）

management アカウントから audit アカウントを各サービスプリンシパルの委任管理者として登録する。これにより Config の組織管理を audit アカウントへ委譲する。

| サービスプリンシパル | 委任先 |
| --- | --- |
| `config.amazonaws.com` | audit アカウント |
| `config-multiaccountsetup.amazonaws.com` | audit アカウント |

### 2.4 ログ集約バケット（audit アカウント）

audit アカウントに Config ログ集約用の S3 バケットを作成する。

**バケット設定**

| 項目 | 設定 |
| --- | --- |
| バージョニング | 有効 |
| 強制削除（force_destroy） | 有効 |

**ライフサイクルルール（`config-log-lifecycle`）**

| 経過日数 | アクション |
| --- | --- |
| 90 日 | STANDARD_IA へ移行 |
| 365 日 | GLACIER へ移行 |
| 2555 日（約 7 年） | 失効（削除） |
| 非現行バージョン 365 日 | 失効（削除） |

**バケットポリシー**

| Sid | 効果 | 内容 |
| --- | --- | --- |
| AllowSSLRequestsOnly | Deny | `aws:SecureTransport=false`（非SSL通信）をすべて拒否。 |
| AWSConfigBucketPermissionsCheck | Allow | `config.amazonaws.com` による `s3:GetBucketAcl` を許可。 |
| AWSConfigBucketExistenceCheck | Allow | `config.amazonaws.com` による `s3:ListBucket` を許可。 |
| AWSConfigBucketDelivery | Allow | `config.amazonaws.com` による `s3:PutObject` を許可。条件として `aws:SourceOrgID` が自組織IDに一致することを要求。配信先は `<bucket>/<organizationID>/AWSLogs/*/*`。 |

### 2.5 Configuration Recorder / Delivery Channel（各アカウント）

共通モジュール（`./modules/config-recorder`）を用い、各アカウントで Recorder と Delivery Channel を構成する。Config サービスにリンクされたロール（`AWSServiceRoleForConfig`）を利用する。

**Recorder 設定**

| 項目 | 設定 |
| --- | --- |
| 記録対象（all_supported） | すべての対応リソース |
| グローバルリソース（include_global_resource_types） | 含む |
| ステータス | 有効 |

**Delivery Channel 設定**

| 項目 | 設定 |
| --- | --- |
| 配信先バケット | audit アカウントの集約バケット |
| S3 プレフィックス | 組織ID（`data.aws_organizations_organization.current.id`） |

**展開対象アカウント**

| モジュール | プロバイダ（対象アカウント） |
| --- | --- |
| config_recorder_management | management |
| config-recorder-infrastructure | infrastructure |
| config-recorder-audit | audit |
| config-recorder-evs | evs |
| config-recorder-system-stg | **evs**（注意：コード上 `aws.evs` を指定。`system-stg` を意図する場合は要修正） |

> ※ `config-recorder-system-stg` モジュールのプロバイダが `aws.evs` になっている。名前は system-stg だが実際には evs アカウントに対して適用されるため、system-stg を対象とする意図であれば `aws.system-stg`（相当）への修正が必要。

**最終的な S3 格納パス**

```text
s3://<bucket>/<organizationID>/AWSLogs/<account-id>/Config/<region>/...
```

### 2.6 組織アグリゲータ（audit アカウント）

audit アカウントに組織アグリゲータを作成し、全リージョン・全アカウントの構成情報を集約する。

| 項目 | 設定 |
| --- | --- |
| アグリゲータ名 | `organization-config-aggregator` |
| 集約範囲 | 全リージョン（all_regions = true） |
| 引き受けロール | `aws-config-organization-aggregator-role` |
| アタッチポリシー | `AWSConfigRoleForOrganizations`（service-role） |
| ロールの信頼関係 | `config.amazonaws.com` による `sts:AssumeRole` を許可 |

---

## 3. Security Hub 設計

### 3.1 全体構成

audit アカウントを Security Hub の委任管理者とし、中央設定（Central Configuration）により組織全体へ構成ポリシーを適用する。検出結果は Finding Aggregator で集約する。

### 3.2 有効化と委任管理者

| 項目 | 設定 | 対象アカウント |
| --- | --- | --- |
| Security Hub 有効化 | デフォルト標準は無効（enable_default_standards = false） | audit |
| 信頼されたアクセス | `securityhub.amazonaws.com` | management |
| 委任管理者登録 | audit アカウントを管理者に指定 | management |

> ※ 委任管理者登録後、組織同期のため 30 秒の待機（`time_sleep`）を挟む。

### 3.3 Finding Aggregator

audit アカウントで検出結果アグリゲータを構成する。

| 項目 | 設定 |
| --- | --- |
| リンクモード | `NO_REGIONS`（現行ホームリージョンのみ集約） |

> ※ コード上 `SPECIFIED_REGIONS`（特定リージョン集約）はコメントアウトされており、必要に応じて切り替える設計。

### 3.4 中央設定（Central Configuration）

| 項目 | 設定 |
| --- | --- |
| 構成タイプ | `CENTRAL`（中央設定） |
| 自動有効化（auto_enable） | 無効 |
| 標準の自動有効化（auto_enable_standards） | `NONE` |

### 3.5 構成ポリシー（CSPM ベースライン）

audit アカウントで組織共通の Security Hub CSPM ベースラインポリシーを定義し、組織ルートに関連付ける。

| 項目 | 設定 |
| --- | --- |
| ポリシー名 | `org-securityhub-baseline` |
| サービス有効化 | 有効 |
| 有効化する標準 | AWS Foundational Security Best Practices v1.0.0 / CIS AWS Foundations Benchmark v5.0.0 |
| 無効化するコントロール | なし（コード上は例のみコメントアウト） |
| 関連付け先 | 組織ルート（Organization Root） |

---

## 4. データフロー

```text
[各メンバーアカウント]
  Config Recorder → Delivery Channel
        │
        ▼  s3://<bucket>/<orgID>/AWSLogs/<account-id>/Config/<region>/...
[audit アカウント] 集約 S3 バケット
        │
        ▼
[audit アカウント] Config 組織アグリゲータ（全リージョン・全アカウント構成情報を一元参照）

[各アカウント Security Hub 検出結果]
        │
        ▼  中央設定で組織ルートに構成ポリシーを適用
[audit アカウント] Security Hub 委任管理者 / Finding Aggregator（検出結果を集約）
```

---

## 5. 留意事項

- `config-recorder-system-stg` モジュールのプロバイダが `aws.evs` を指している。system-stg を対象とする意図であればプロバイダ指定の修正が必要。
- Config バケットの失効は 2555 日（約 7 年）に設定されている。保管要件（監査・法令）に応じて見直すこと。
- Security Hub の Finding Aggregator は `NO_REGIONS`（ホームリージョンのみ）で構成されている。マルチリージョンで検出結果を集約する場合は `SPECIFIED_REGIONS` 等への変更を検討する。
- 中央設定では auto_enable / auto_enable_standards をいずれも無効化しているため、新規アカウントへの適用は構成ポリシーの関連付けに依存する。意図した範囲に確実に適用されているか定期確認すること。
- Config・Security Hub いずれも委任管理者として audit アカウントに依存する。audit アカウントの可用性・権限管理に留意すること。
- 標準ARN・ポリシー関連付けはホームリージョン（`local.home_region`）を前提とする。リージョン構成変更時は影響範囲を確認すること。

```

```
# AWS マルチアカウント・アクセス管理設計書

## 1. 目的

本設計書は、AWS Organizations を利用したマルチアカウント環境において、以下を実現するための基本設計を定義する。

- AWSアカウントを用途別に分離する
- OU によってアカウントを論理的に管理する
- IAM Identity Center を利用してユーザー・グループ単位でアクセス権限を管理する
- 管理者権限と作業者権限を分離する
- Workload 系アカウントに対して、組織管理・監査・セキュリティ・課金系操作を制限する

AWS Organizations では OU を利用してアカウントをグループ化し、OU 単位でポリシー管理を行える。OU にアタッチされたポリシーは、その OU 配下のアカウントおよび子 OU に継承される。

---

## 2. 設計方針

本環境では、AWS Organizations を中心に以下の方針で設計する。

| 方針 | 内容 |
|---|---|
| アカウント分離 | 管理、監査、共通基盤、ワークロードを AWS アカウント単位で分離する |
| OU 分離 | security / infrastructure / workload に分け、ワークロードは common / prod / non-prod に分離する |
| 権限分離 | 組織管理者とワークロード作業者を Permission Set で分離する |
| 管理アカウント最小利用 | management アカウントは Organizations / IAM Identity Center など、管理アカウントでしかできない操作に限定する |
| 作業者制限 | workload-operator は PowerUserAccess をベースにしつつ、組織・監査・セキュリティ・課金系操作を明示的に拒否する |

AWS 公式ベストプラクティスでも、management account は通常のワークロードを置かず、management account でしか実行できないタスクに限定することが推奨されている。

---

## 3. AWS Organizations 設計

### 3.1 Organizations 構成

本環境では、AWS Organizations により以下のマルチアカウント構成を管理する。

```text
Root
├── security
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

また、management アカウントは Organizations の管理アカウントとして扱う。

> 注意: 設計上、management アカウントは既存の Organizations 管理アカウントとして扱う。Terraform の `aws_organizations_account` で新規作成する対象ではなく、実際の運用では既存管理アカウントをデータ参照または管理対象外として扱うのが自然である。

---

### 3.2 OU 設計

| OU | 親 OU | 目的 |
|---|---|---|
| security | Root | 監査・セキュリティ管理系アカウントを配置する |
| infrastructure | Root | ネットワーク・共通基盤系アカウントを配置する |
| workload | Root | 業務・アプリケーション系アカウントを配置する |
| common | workload | 共通ワークロード、共通サービス用アカウントを配置する |
| prod | workload | 本番環境アカウントを配置する |
| non-prod | workload | 検証・ステージング・開発系アカウントを配置する |

AWS Organizations では、OU を利用して同じ役割・同じ管理ポリシーを適用したいアカウントをまとめることができる。AWS の推奨構成でも、security、infrastructure、workloads などの目的別 OU 分離が基本的な考え方として示されている。

---

### 3.3 アカウント設計

| アカウント名 | 配置先 | 主な用途 |
|---|---|---|
| management | Root / 管理アカウント | AWS Organizations、IAM Identity Center、請求管理など |
| audit | security OU | AWS Config、Security Hub CSPM、GuardDuty、CloudTrail 集約などの監査・セキュリティ管理 |
| infrastructure | infrastructure OU | Direct Connect、Transit Gateway、共有ネットワーク、共通基盤 |
| evs | workload / common OU | 共通ワークロード、共通アプリケーション基盤 |
| system-prd | workload / prod OU | 本番ワークロード |
| system-stg | workload / non-prod OU | ステージング・検証ワークロード |

---

### 3.4 アカウントタグ設計

アカウントには、管理・検索・コスト管理・運用責任の明確化を目的としてタグを付与する。

| タグキー | 用途 | 設定例 |
|---|---|---|
| AccountType | アカウント種別 | Security / Infrastructure / Workload |
| Environment | 環境区分 | Common / Prod / NonProd |
| ManagedBy | 管理主体 | Kiban |
| Owner | 所有チーム | Kiban |

添付コードでは `infrastructure` や `evs` に `AccountType = "Security"` が設定されているが、設計上は以下のように見直すことを推奨する。

| アカウント | 推奨 AccountType |
|---|---|
| audit | Security |
| infrastructure | Infrastructure |
| evs | Workload または Common |
| system-prd | Workload |
| system-stg | Workload |

---

## 4. IAM Identity Center 設計

### 4.1 基本方針

本環境では、IAM ユーザーをアカウントごとに作成して管理する方式ではなく、IAM Identity Center による集中アクセス管理を採用する。

IAM Identity Center では、ユーザーまたはグループに対して AWS アカウントと Permission Set を割り当てることで、各アカウントに対応する IAM Identity Center 管理ロールが作成される。ユーザーは User Portal または AWS CLI からそのロールを利用してアクセスする。

---

### 4.2 グループ設計

| グループ名 | 説明 | 想定利用者 |
|---|---|---|
| mck-admin | MultiCloud Kiban Team Administrators | 組織全体の管理者 |
| mck | MultiCloud Kiban Team | 基盤チーム一般メンバー |
| bk | Bunsan Kiban Team | 業務基盤チーム |
| nw | Network Team | ネットワークチーム |
| inet | Internet Team | インターネット接続管理チーム |
| assist | Assist Team | 支援・運用補助チーム |

---

### 4.3 Permission Set 設計

本環境では、以下の Permission Set を定義する。

| Permission Set | ベース権限 | 目的 |
|---|---|---|
| org-admin | AdministratorAccess | 組織全体および各アカウントの管理者権限 |
| workload-operator | PowerUserAccess + 明示的 Deny | ワークロード作業者向け権限 |

Permission Set は、ユーザーやグループが AWS アカウントに対して持つアクセスレベルを定義する。Permission Set は IAM Identity Center に保存され、1つ以上の AWS アカウントに割り当てられる。

---

## 5. 権限設計

### 5.1 org-admin

#### 目的

`org-admin` は、AWS Organizations、IAM Identity Center、各アカウントの管理操作を行う管理者向け Permission Set とする。

#### 付与ポリシー

| 種別 | ポリシー |
|---|---|
| AWS 管理ポリシー | AdministratorAccess |

#### 利用対象

主に `mck-admin` グループに付与する。

#### 設計上の注意

`AdministratorAccess` は非常に強い権限であるため、付与対象は最小限にする。特に management アカウントへの `org-admin` 付与は、Organizations や IAM Identity Center を管理する必要があるメンバーに限定する。

---

### 5.2 workload-operator

#### 目的

`workload-operator` は、ワークロード運用者が EC2、VPC、S3、RDS などの一般的な AWS リソースを操作できるようにしつつ、組織管理・監査・セキュリティ・課金系の重要操作を制限するための Permission Set とする。

#### 付与ポリシー

| 種別 | ポリシー |
|---|---|
| AWS 管理ポリシー | PowerUserAccess |
| インラインポリシー | 管理系・監査系・課金系サービスの Deny |

---

### 5.3 workload-operator の明示的拒否設計

`workload-operator` では、PowerUserAccess をベースにしつつ、以下の操作を明示的に拒否する。

#### 5.3.1 Organizations / Account / Control Tower 操作の拒否

| 対象サービス | 拒否理由 |
|---|---|
| AWS Organizations | OU、アカウント、SCP などの組織管理を防止する |
| AWS Account Management | アカウント設定変更を防止する |
| AWS Control Tower | ランディングゾーンやガードレール設定変更を防止する |
| AWS Control Catalog | Control Tower 関連のコントロール管理を防止する |

対象アクション:

```text
organizations:*
account:*
controltower:*
controlcatalog:*
```

---

#### 5.3.2 IAM Identity Center / Identity Store 操作の拒否

| 対象サービス | 拒否理由 |
|---|---|
| IAM Identity Center | Permission Set や Account Assignment の変更を防止する |
| SSO Directory | Identity Center ディレクトリ操作を防止する |
| Identity Store | グループ・ユーザー情報の変更を防止する |

対象アクション:

```text
sso:*
sso-directory:*
identitystore:*
```

---

#### 5.3.3 監査・セキュリティ・ガバナンス操作の拒否

| 対象サービス | 拒否理由 |
|---|---|
| CloudTrail | 監査ログ停止・削除・変更を防止する |
| AWS Config | リソース設定記録の停止・変更を防止する |
| Security Hub | セキュリティ検出結果・集約設定の変更を防止する |
| GuardDuty | 脅威検知の停止・変更を防止する |
| Detective | 調査基盤の変更を防止する |
| Inspector / Inspector2 | 脆弱性管理設定の変更を防止する |
| Macie | データ保護・機密情報検出の変更を防止する |
| Security Lake | セキュリティログ基盤の変更を防止する |
| Access Analyzer | アクセス分析設定の変更を防止する |
| Firewall Manager | 組織横断のセキュリティポリシー変更を防止する |
| Audit Manager | 監査証跡・評価設定の変更を防止する |
| Artifact | コンプライアンス文書管理の変更を制限する |

対象アクション:

```text
cloudtrail:*
config:*
auditmanager:*
securityhub:*
guardduty:*
detective:*
inspector:*
inspector2:*
macie2:*
securitylake:*
access-analyzer:*
fms:*
artifact:*
```

---

#### 5.3.4 Billing / Cost Management 操作の拒否

| 対象サービス | 拒否理由 |
|---|---|
| Billing | 請求設定変更を防止する |
| Cost Explorer | コスト情報・分析設定の変更を制限する |
| Budgets | 予算設定変更を防止する |
| Cost and Usage Report | CUR 設定変更を防止する |
| Pricing | 料金情報操作を制限する |
| Payments / Tax / Invoicing | 支払い・税務・請求情報の変更を防止する |
| Consolidated Billing | 一括請求関連操作を防止する |

対象アクション:

```text
billing:*
ce:*
budgets:*
cur:*
cur-reporting:*
cost-optimization-hub:*
bcm-data-exports:*
pricing:*
payments:*
tax:*
invoicing:*
consolidatedbilling:*
```

---

## 6. Account Assignment 設計

### 6.1 割り当て方針

IAM Identity Center では、グループに対して AWS アカウントと Permission Set を割り当てる。

Account Assignment は、Principal、AWS Account、Permission Set の組み合わせによりアクセスを定義する。ここでいう Principal は IAM Identity Center 上のユーザーまたはグループを指す。

---

### 6.2 割り当て一覧

| 対象アカウント | グループ | Permission Set | 目的 |
|---|---|---|---|
| management | mck-admin | org-admin | Organizations / Identity Center 管理 |
| audit | mck-admin | org-admin | 監査・セキュリティ管理 |
| infrastructure | mck-admin | org-admin | 共通基盤・ネットワーク管理 |
| evs | mck-admin | org-admin | 共通ワークロード管理 |
| system-stg | mck-admin | org-admin | ステージング環境管理 |
| evs | bk | workload-operator | 共通ワークロード作業 |
| system-stg | bk | workload-operator | ステージング環境作業 |
| infrastructure | assist | workload-operator | 基盤運用支援 |
| system-stg | assist | workload-operator | ステージング運用支援 |
| evs | assist | workload-operator | 共通ワークロード運用支援 |
| infrastructure | nw | workload-operator | ネットワーク関連作業 |

---

## 7. セキュリティ設計上の補足

### 7.1 Permission Set と SCP の役割分担

本設計では、`workload-operator` のインラインポリシーで明示的 Deny を設定している。

ただし、これは IAM Identity Center 経由でその Permission Set を利用するユーザーに対する制限である。アカウント全体に対する強制的なガードレールではない。

そのため、組織全体または OU 単位で必ず守らせたい制御は SCP として別途設計する。

| 制御方式 | 適用対象 | 目的 |
|---|---|---|
| Permission Set | 特定のユーザー・グループ | ロールベースのアクセス制御 |
| SCP | OU / アカウント全体 | アカウント単位の最大権限制御 |

SCP は IAM ユーザーや IAM ロールに対する最大権限を制御する仕組みであり、SCP 自体は権限を付与しない。実際の有効権限は、SCP と IAM ポリシーなどの交差で決まる。

---

### 7.2 本設計で追加検討すべき SCP

本設計とは別に、以下の SCP を検討する。

| 対象 OU | SCP 例 | 目的 |
|---|---|---|
| workload | Organizations からの離脱禁止 | メンバーアカウントの統制維持 |
| workload | CloudTrail 停止・削除禁止 | 監査ログ保護 |
| workload | AWS Config 停止禁止 | リソース設定記録の保護 |
| workload | Security Hub / GuardDuty 停止禁止 | セキュリティ監視の保護 |
| prod | 特定リージョン以外の利用禁止 | 本番環境の統制 |
| prod | 重要リソース削除の制限 | 誤操作防止 |

---

## 8. 運用設計

### 8.1 管理アカウントの運用

management アカウントでは、以下の操作に限定する。

- AWS Organizations 管理
- OU / アカウント管理
- IAM Identity Center 管理
- 請求・契約関連管理
- 組織レベルのポリシー管理

通常のアプリケーション、EC2、RDS、S3 などのワークロードは配置しない。

---

### 8.2 audit アカウントの運用

audit アカウントでは、以下のサービスを集約・管理する。

- AWS Config
- AWS Security Hub CSPM
- Amazon GuardDuty
- AWS CloudTrail
- IAM Access Analyzer
- Amazon Detective
- Amazon Inspector
- Amazon Macie

audit アカウントは、セキュリティ・監査チームが管理する前提とし、ワークロード担当者には原則として管理権限を付与しない。

---

### 8.3 infrastructure アカウントの運用

infrastructure アカウントでは、以下の共通基盤を管理する。

- AWS Direct Connect
- AWS Transit Gateway
- 共有 VPC / 共有ネットワーク
- VPC Endpoint
- Route 53 Resolver
- Network Firewall などのネットワークセキュリティ基盤

ネットワークチーム `nw` には作業権限を付与するが、Organizations や監査系サービスの管理権限は付与しない。

---

### 8.4 workload アカウントの運用

workload 配下のアカウントでは、アプリケーションおよび業務システムを管理する。

| アカウント | 用途 |
|---|---|
| evs | 共通ワークロード |
| system-prd | 本番ワークロード |
| system-stg | ステージング・検証ワークロード |

workload-operator は、通常のリソース操作は可能だが、組織・監査・セキュリティ・課金系サービスは操作できない。

# Claude

# AWS マルチアカウント基盤 設計書

**対象**: AWS Organizations / IAM Identity Center
**作成**: MultiCloud Kiban Team
**Version**: 1.0

---

## 目次

- [1. 概要](#1-概要)
  - [1.1 本書の目的](#11-本書の目的)
  - [1.2 設計方針](#12-設計方針)
  - [1.3 構成要素一覧](#13-構成要素一覧)
- [2. アカウント構成](#2-アカウント構成)
  - [2.1 OU 階層構造](#21-ou-階層構造)
  - [2.2 OU 定義](#22-ou-定義)
  - [2.3 アカウント定義](#23-アカウント定義)
- [3. ID・アクセス管理（IAM Identity Center）](#3-idアクセス管理iam-identity-center)
  - [3.1 グループ定義](#31-グループ定義)
  - [3.2 Permission Set 定義](#32-permission-set-定義)
  - [3.3 workload-operator の権限制限](#33-workload-operator-の権限制限)
  - [3.4 アカウント割り当て](#34-アカウント割り当て)
- [4. アクセス権限マトリクス](#4-アクセス権限マトリクス)
- [5. 構築・運用方式](#5-構築運用方式)
  - [5.1 構築手段](#51-構築手段)
  - [5.2 構築後処理](#52-構築後処理)
  - [5.3 留意事項](#53-留意事項)

---

## 1. 概要

### 1.1 本書の目的

本書は、AWS Organizations を中核としたマルチアカウント管理基盤の設計内容を定義するものである。複数の AWS アカウントを組織単位（OU）で階層的に整理し、IAM Identity Center（旧 AWS SSO）による一元的なアクセス管理を実現する。本基盤は Infrastructure as Code（Terraform）により構築・運用される。

### 1.2 設計方針

- **マルチアカウント戦略**: 用途・環境・責務に応じてアカウントを分割し、障害影響範囲と権限の境界を明確化する。
- **最小権限の原則**: ワークロード運用者には特権操作を許可せず、ガバナンス・セキュリティ系操作は明示的に拒否する。
- **一元的 ID 管理**: IAM ユーザーを各アカウントに作成せず、IAM Identity Center で ID とアクセス権限を一元管理する。
- **統制操作の制限**: 運用者の Permission Set では、組織管理・ID管理・セキュリティ・課金に関わる操作を明示的に拒否する。

### 1.3 構成要素一覧

| 構成要素 | 概要 |
| --- | --- |
| AWS Organizations | 複数アカウントを統合管理する組織。OU による階層構造を提供。 |
| Organizational Unit（OU） | アカウントを用途別にグループ化する論理単位。 |
| メンバーアカウント | 実際にリソースを配置する個別の AWS アカウント。 |
| IAM Identity Center | SSO によるアクセス一元管理。Permission Set と グループの割り当てを管理。 |
| Identity Store | ユーザー／グループを保持する ID ストア。 |

---

## 2. アカウント構成

### 2.1 OU 階層構造

組織ルートの直下に 3 つのトップレベル OU（security / infrastructure / workload）を配置する。workload OU の配下にはさらに環境別の 3 つの子 OU（common / prod / non-prod）を配置する。

```text
Root
 ├─ security （OU）
 │   └─ audit （アカウント）
 ├─ infrastructure （OU）
 │   └─ infrastructure （アカウント）
 └─ workload （OU）
     ├─ common （OU）
     │   └─ evs （アカウント）
     ├─ prod （OU）
     │   └─ system-prd （アカウント）
     └─ non-prod （OU）
         └─ system-stg （アカウント）
```

> ※ management（管理）アカウントは組織ルート直下に配置される。

### 2.2 OU 定義

| OU 名 | 親 | 用途・配置方針 |
| --- | --- | --- |
| security | Root | 監査・セキュリティ系アカウントを配置。 |
| infrastructure | Root | 共通インフラ／ネットワーク系アカウントを配置。 |
| workload | Root | 業務システムを格納する親 OU。 |
| common | workload | 共通サービス（EVS 等）を配置。 |
| prod | workload | 本番環境のワークロードを配置。 |
| non-prod | workload | ステージング・検証環境のワークロードを配置。 |

### 2.3 アカウント定義

各メンバーアカウントの配置先 OU と用途は以下の通り。

| アカウント名 | 所属 OU | 種別 | 用途 |
| --- | --- | --- | --- |
| management | Root（直下） | 管理 | 組織の管理アカウント。Organizations の管理主体。 |
| audit | security | セキュリティ | 監査ログの集約・セキュリティ監査。 |
| infrastructure | infrastructure | 共通インフラ | 共通インフラ・ネットワーク基盤。 |
| evs | common | 共通サービス | 共通サービス系ワークロード。 |
| system-prd | prod | ワークロード | 業務システム本番環境。 |
| system-stg | non-prod | ワークロード | 業務システムステージング環境。 |

> ※ 管理タグ（`Environment` / `Owner` / `ManagedBy` 等）を付与し運用区分を識別する。コード上、一部アカウントの `AccountType` タグに `Security` が設定されているが、実際の配置・用途とは必ずしも一致しないため、運用時に整合を確認すること。

---

## 3. ID・アクセス管理（IAM Identity Center）

アクセス管理は IAM Identity Center を用いて一元化する。各アカウントへの IAM ユーザー作成は行わず、ID ストア上のグループに対して Permission Set を割り当てることでアクセスを制御する。

### 3.1 グループ定義

Identity Store に以下のグループを定義する。ユーザーはこれらのグループに所属し、グループ単位でアカウントへのアクセス権を得る。

| グループ名 | 説明 |
| --- | --- |
| mck-admin | MultiCloud Kiban Team Administrators（基盤管理者） |
| mck | MultiCloud Kiban Team |
| bk | Bunsan Kiban Team |
| nw | Network Team |
| inet | Internet Team |
| assist | Assist Team |

### 3.2 Permission Set 定義

アクセスレベルを定義する Permission Set を 2 種類用意する。セッション有効期間はいずれも 8 時間（`PT8H`）とする。

| Permission Set | ベースポリシー | 説明 |
| --- | --- | --- |
| org-admin | AdministratorAccess | 組織全体の管理者権限。 |
| workload-operator | PowerUserAccess + インラインの拒否ポリシー | ワークロード運用者。インフラ操作は可能だがガバナンス系操作は拒否。 |

### 3.3 workload-operator の権限制限

workload-operator には PowerUserAccess をベースとして付与しつつ、以下のカテゴリの操作を明示的に Deny するインラインポリシーを適用する。これにより、運用者が組織統制やセキュリティ・課金設定を変更できないようにする。

| 拒否カテゴリ | 対象サービス（主なもの） |
| --- | --- |
| 組織／アカウント管理系の拒否 | `organizations`、`account`、`controltower`、`controlcatalog`（いずれも操作を拒否） |
| ID 管理（Identity Center） | `sso`、`sso-directory`、`identitystore` |
| セキュリティ・監査・ガバナンス | `cloudtrail`、`config`、`auditmanager`、`securityhub`、`guardduty`、`detective`、`inspector`/`inspector2`、`macie2`、`securitylake`、`access-analyzer`、`fms`、`artifact` |
| 課金・コスト管理 | `billing`、`ce`、`budgets`、`cur`、`cost-optimization-hub`、`pricing`、`payments`、`tax`、`invoicing`、`consolidatedbilling` 等 |

> 補足：Deny は Allow に優先するため、ベースの PowerUserAccess で許可される範囲であっても、上記カテゴリの操作は確実に拒否される。

### 3.4 アカウント割り当て

グループ・Permission Set・対象アカウントの組み合わせを以下の通り割り当てる。割り当ての主体（プリンシパル）はすべてグループ単位とする。

| 対象アカウント | グループ | Permission Set |
| --- | --- | --- |
| management | mck-admin | org-admin |
| audit | mck-admin | org-admin |
| infrastructure | mck-admin | org-admin |
| evs | mck-admin | org-admin |
| system-stg | mck-admin | org-admin |
| infrastructure | nw | workload-operator |
| infrastructure | assist | workload-operator |
| evs | bk | workload-operator |
| evs | assist | workload-operator |
| system-stg | bk | workload-operator |
| system-stg | assist | workload-operator |

> ※ mck-admin は管理対象の各アカウントに org-admin として割り当てられ、基盤全体を管理する。bk / nw / assist などの運用チームは担当アカウントに対し workload-operator として割り当てられる。

---

## 4. アクセス権限マトリクス

グループとアカウントの交差点における付与権限を一覧化する。

| グループ ＼ アカウント | management | audit | infrastructure | evs | system-stg |
| --- | --- | --- | --- | --- | --- |
| mck-admin | org-admin | org-admin | org-admin | org-admin | org-admin |
| nw | - | - | operator | - | - |
| assist | - | - | operator | operator | operator |
| bk | - | - | - | operator | operator |

> `operator` = workload-operator。system-prd は本設計時点でアクセス割り当てを定義していない（管理者経由での運用を想定）。

---

## 5. 構築・運用方式

### 5.1 構築手段

本基盤は Terraform により宣言的に構築する。アカウント・OU・グループ・Permission Set・割り当ては相互の依存関係に従って順序付きで作成される（OU → アカウント → Identity Center 構成）。

### 5.2 構築後処理

割り当て処理の完了後、組織情報を取得・出力する後処理スクリプト（`get-org-info.py`）が実行される。これにより構築結果の確認・記録を行う。

### 5.3 留意事項

- IAM ユーザーは原則作成せず、既存の特権 IAM ユーザー（admin 等）が存在する場合は移行・統制の対象として個別に検討する。
- メールアドレスは各アカウントで一意である必要があり、配布リスト等の運用可能なアドレスを使用する。
- Permission Set のセッション時間（8 時間）はセキュリティ要件に応じて見直すこと。
- system-prd には本設計時点でアクセス割り当てが定義されていないため、運用フェーズで割り当て要否を確定すること。

```
