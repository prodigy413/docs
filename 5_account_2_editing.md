# 5. アカウント設計

## 5.1 目的

本章では、AWS Organizations、IAM Identity Center、AWS Control Tower を用いて構築する AWS マルチアカウント基盤における、アカウント体系、用途別の役割、命名規則、作成方針、アクセス方針を定義する。
本設計の目的は、アカウントを分離境界として利用し、セキュリティ、運用、コスト管理、監査対応を明確化することである。

## 5.2 設計方針

本環境の AWS アカウント設計は、以下の方針で統一する。

- AWS アカウントは、用途、責務、統制要件、運用主体の違いに応じて分離する。
- Management account は Organizations および Control Tower の管理専用とし、通常の業務ワークロードは配置しない。
- 監査、ログ保管、共通基盤は、業務ワークロード用アカウントと分離する。
- 新規アカウントは、原則として AWS Control Tower Account Factory により作成する。
- 人のアクセスは IAM Identity Center 経由に統一し、恒常的な IAM ユーザー運用は行わない。
- アカウント名、メールアドレス、タグは標準規則に従って統一する。
- 本番環境と非本番環境はアカウントレベルで分離する。

## 5.3 アカウント体系

本環境では、以下のアカウント体系を標準とする。

| アカウント種別 | 役割 | 配置する主な対象 | 配置しない対象 |
|---|---|---|---|
| Management account | Organizations / Control Tower / 請求管理 | 組織設定、OU 管理、請求管理、Control Tower 管理 | 業務システム、共通基盤、監視基盤 |
| Log archive account | 組織ログの集中保管 | CloudTrail、AWS Config 等の集中保管先 | 業務ワークロード、日常運用ツール |
| Audit account | 監査・セキュリティ確認 | 調査、監査、構成確認、セキュリティレビュー | 業務ワークロード |
| Infrastructure account | 共通基盤の提供 | 共通 NW、共通 DNS、共通運用ツール等 | 個別業務システム本体 |
| Production account | 本番ワークロード実行 | 本番アプリケーション、関連基盤 | 非本番ワークロード |
| Non-Production account | 非本番ワークロード実行 | 開発、検証、テスト、ステージング、PoC | 本番ワークロード |

### 5.3.1 標準アカウント

最終構成として、以下のアカウントを作成する。

- Management account
- Log archive account
- Audit account
- Infrastructure account
- ROSA Production account
- ROSA Staging account
- EVS Common account

追加アカウントを作成する場合は、既存アカウントで代替できないこと、OU 配置先と適用統制が事前に定義されていることを作成条件とする。

## 5.4 各アカウントの利用方針

### 5.4.1 Management account

- Management account は、Organizations、Control Tower、請求管理、組織全体設定の変更に限定して利用する。
- 本アカウントには業務システム、共通運用基盤、監視基盤、検証環境を配置しない。
- 高権限アクセスは必要最小限の管理者に限定し、日常運用作業の実行先として利用しない。

### 5.4.2 Log archive account

- Log archive account は、組織全体の監査証跡および設定変更履歴の集中保管先として利用する。
- 参照権限は監査担当者およびセキュリティ担当者に限定し、一般運用者への書込み権限は付与しない。
- 本アカウントを業務用途や共通ツール配置先として流用しない。

### 5.4.3 Audit account

- Audit account は、組織内アカウントの監査、調査、セキュリティ確認の実施用アカウントとして利用する。
- 本アカウントでは業務ワークロードを実行しない。

### 5.4.4 Infrastructure account

- Infrastructure account は、複数アカウントで共通利用する基盤機能を配置する。
- 配置候補は、共通 NW、共通運用ツールとする。
- 個別業務システムの本体は配置しない。

### 5.4.5 ROSA Production account

- ROSA Production account は、AWS 上の OpenShift サービスである ROSA (Red Hat OpenShift Service on AWS) の本番ワークロード専用アカウントとする。
- 本番環境の変更権限は非本番環境より厳格に管理し、運用権限と開発権限を分離する。
- 本アカウントには本番以外のワークロードを配置しない。

### 5.4.6 ROSA Staging account

- ROSA Staging account は、ROSA に関するステージング環境の実行先とする。
- 本番リリース前の検証、結合テスト、性能検証等を本アカウントで実施する。
- 本番ワークロードは配置しない。

### 5.4.7 EVS Common account

- EVS Common account は、AWS 上の VMware サービスである Amazon EVS (Elastic VMware Service) の実行アカウントとする。
- 本アカウントでは本番環境およびステージング環境を同一アカウント内で運用する。
- 将来的に EVS を廃止し EC2 等への移行を行う可能性があるため、現時点ではアカウントを分離せず単一アカウントでの運用とする。

## 5.5 アカウント命名規則

- 命名規則は「」を参照する。

## 5.6 アカウント用メールアドレス規則

- 命名規則は「」を参照する。

## 5.7 アカウントタグ設計

AWS アカウントには、検索性、分類、コスト集計、運用管理のため、以下の標準タグを付与する。

| タグキー | 用途 | 設定例 |
|---|---|---|
| Name | 表示名との対応 | corp-sales-prd |
| AccountType | アカウント種別 | Workload |
| Environment | 環境区分 | Production |
| System | システム名 | Sales |
| Owner | 管理責任者または管理部門 | Kiban |
| ManagedBy | 管理方式 | ControlTower |

AccountType の値は `Management` `Security` `Shared` `Workload` `Sandbox` のいずれかに統一する。
Environment の値は `Production` `Staging` `Development` `Test` `Sandbox` `Common` `Security` のいずれかに統一する。
タグキーおよびタグ値の表記ゆれ防止は、別章のタグポリシー設計に従う。

## 5.8 アカウント作成方針

- 新規アカウントは、原則として AWS Control Tower Account Factory により作成する。
- 作成時には、OU 配置先、アカウント表示名、メールアドレス、必須タグ、運用責任者を申請時点で確定させる。
- Account Factory を利用しない作成を認めるのは、以下のいずれかに該当する場合のみとする。
  - AWS Control Tower 管理対象外とする明確な要件がある場合
  - 一時的な移行対応として事前承認を得た場合

上記例外で作成したアカウントも、恒久利用する場合は Control Tower 管理下への取り込み可否を評価する。

## 5.9 root ユーザー利用方針

- root ユーザーは初期設定および root ユーザーでしか実施できない操作に限定して利用する。
- 日常運用で root ユーザーを利用しない。
- 各アカウントの root ユーザーには MFA を設定し、認証情報は厳格に保管する。
- メンバーアカウントは、組織運用開始後に root ユーザーの常用を停止し、通常操作は IAM Identity Center 経由へ統一する。

## 5.10 アカウントアクセス方針

- 人のアクセスは IAM Identity Center 経由に統一する。
- 個人向け IAM ユーザーは、恒常運用では作成しない。
- 権限は Permission Set により付与し、本番アカウント、非本番アカウント、共有基盤アカウントで必要な権限区分を分離する。
