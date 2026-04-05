# 8. IAM Identity Center 設計

## 8.1 目的

本章では、AWS Organizations、AWS Control Tower を用いて構築する AWS マルチアカウント基盤における、人の認証および AWS アカウントへのアクセス制御方式を定義する。  
本設計の目的は、複数 AWS アカウントに対するアクセス管理を IAM Identity Center に集約し、権限付与の標準化、最小権限の徹底、監査性の確保、運用負荷の低減を実現することである。

## 8.2 設計方針

本環境の IAM Identity Center 設計は、以下の方針で統一する。

- 人の AWS アクセスは IAM Identity Center 経由に統一する。
- 恒常的な個人向け IAM ユーザーは作成しない。
- Identity source は IAM Identity Center directory を利用する。
- ユーザーへの直接割当は原則行わず、グループ単位で Permission Set を AWS アカウントへ割り当てる。
- 権限は職務単位で標準化し、アカウント単位の例外付与を最小化する。
- 本番アカウントは非本番アカウントより厳格な権限制御を適用する。
- 緊急時の高権限アクセスは通常権限と分離して管理する。
- CLI 利用も IAM Identity Center 認証を前提とする。

## 8.3 Identity source 方針

### 8.3.1 採用方式

Identity source は IAM Identity Center directory を採用する。

### 8.3.2 採用理由

複数の会社が本基盤を利用する前提であり、特定企業の社内ディレクトリや LDAP を共通の認証基盤として利用できないため、本環境では IAM Identity Center directory を用いてユーザーおよびグループを管理する。

### 8.3.3 運用方針

- ユーザー作成、変更、無効化は IAM Identity Center directory 上で実施する。
- 認証情報のライフサイクル管理は、本基盤の利用申請・変更・廃止フローに従う。
- 外部 IdP 連携および SCIM 連携は本設計の対象外とし、必要となった場合は別途拡張設計とする。

## 8.4 認証方式

- IAM Identity Center へのサインインはユーザー ID とパスワードに加え、MFA を必須とする。
- AWS マネジメントコンソールへのアクセスは IAM Identity Center ポータル経由とする。
- AWS CLI 利用時は IAM Identity Center 認証により取得した一時認証情報を利用する。
- 長期アクセスキーを恒常的な人用認証情報として発行しない。

## 8.5 ユーザーおよびグループ設計

### 8.5.1 基本方針

- 権限付与はグループ単位で行う。
- ユーザー個別の直接割当は一時対応または例外対応に限定し、恒常運用では行わない。
- グループは職務および責務に基づいて定義し、組織図や一時的な案件名には依存しない。
- 複数会社利用を前提とし、会社識別が必要な場合はグループ名に識別子を付与する。

### 8.5.2 標準グループ区分

本環境では、以下の区分を標準とする。

- Platform-Admin
- Security-Audit
- Infrastructure-Operator
- Workload-Prod-Operator
- Workload-Stg-Operator
- Workload-Common-Operator
- ReadOnly

上記は権限分類を示す標準区分であり、必要に応じて会社識別子またはシステム識別子を付与して運用する。

### 8.5.3 グループ命名規則

グループ名は以下の形式を標準とする。

`<Company or Scope>-<Role>-<Environment>`

例:
- `common-platform-admin`
- `common-security-audit`
- `common-infra-operator`
- `common-workload-operator-prod`
- `common-workload-operator-stg`
- `common-workload-operator-common`
- `common-readonly-all`

命名規則の目的は、グループ名から責務、対象範囲、環境区分を判別可能にすることである。  
一時的な案件名や担当者名はグループ名に含めない。

## 8.6 Permission Set 設計方針

### 8.6.1 基本方針

- Permission Set は職務単位で定義する。
- Permission Set 数は必要最小限とし、過度に細分化しない。
- 本番環境と非本番環境で必要な権限差がある場合は、別 Permission Set として分離する。
- AWS 管理ポリシーをベースとし、必要に応じてカスタムポリシーを追加する。
- Permission Set 名は役割が明確に判別できる名称とする。

### 8.6.2 標準 Permission Set 一覧

本環境では、以下を標準 Permission Set とする。

| Permission Set 名 | 用途 | 主な対象 |
|---|---|---|
| PlatformAdministrator | 組織基盤の管理者向け | Management account、共通基盤管理者 |
| SecurityAuditor | 監査・セキュリティ確認向け | Audit account、Log archive account |
| InfrastructureOperator | 共通基盤運用向け | Infrastructure account |
| WorkloadOperatorProduction | 本番ワークロード運用向け | ROSA Production account |
| WorkloadOperatorStaging | ステージング運用向け | ROSA Staging account |
| WorkloadOperatorCommon | 共通ワークロード運用向け | EVS Common account |
| ReadOnlyAccess | 閲覧専用 | 全アカウント共通 |

### 8.6.3 設計上の扱い

- 本設計では、Permission Set の詳細な IAM アクション一覧までは定義しない。
- 詳細権限は別紙の権限マトリクスまたは運用手順書で管理する。
- 基本設計書では、役割区分、対象アカウント、分離方針を定義対象とする。

## 8.7 AWS アカウント割当方針

### 8.7.1 基本方針

- AWS アカウントへのアクセス権は、グループに対して Permission Set を割り当てる方式で付与する。
- 割当はアカウントの役割および OU の統制方針に従う。
- 本番アカウントへの高権限割当は限定し、一般利用者への広範な管理者権限付与は行わない。

### 8.7.2 標準割当方針

| AWS アカウント | 主な割当 Permission Set | 割当対象グループの例 |
|---|---|---|
| Management account | PlatformAdministrator, ReadOnlyAccess | common-platform-admin, common-readonly-all |
| Log archive account | SecurityAuditor, ReadOnlyAccess | common-security-audit, common-readonly-all |
| Audit account | SecurityAuditor, ReadOnlyAccess | common-security-audit, common-readonly-all |
| Infrastructure account | InfrastructureOperator, ReadOnlyAccess | common-infra-operator, common-readonly-all |
| ROSA Production account | WorkloadOperatorProduction, ReadOnlyAccess | common-workload-operator-prod, common-readonly-all |
| ROSA Staging account | WorkloadOperatorStaging, ReadOnlyAccess | common-workload-operator-stg, common-readonly-all |
| EVS Common account | WorkloadOperatorCommon, ReadOnlyAccess | common-workload-operator-common, common-readonly-all |

### 8.7.3 アカウント別制御方針

- Management account は組織管理用途に限定し、アクセス対象者を最小限にする。
- Security OU 配下アカウントは監査・調査・ログ参照用途を中心とし、一般運用者の変更権限は付与しない。
- Infrastructure account は共通基盤運用担当者に限定して運用権限を付与する。
- Production OU 配下アカウントは、本番変更権限を厳格に制限する。
- Staging OU および Common OU 配下アカウントは、本番より柔軟な運用を認めるが、管理者権限の無秩序な付与は行わない。

## 8.8 管理者権限・運用者権限・閲覧権限の分離

- 管理者権限、運用者権限、閲覧権限は分離する。
- 閲覧のみで足りる利用者には ReadOnlyAccess を基本とする。
- 共通基盤運用、本番運用、監査確認はそれぞれ別グループ・別 Permission Set とする。
- 本番アカウントでは、開発用途の権限と運用用途の権限を兼務前提にしない。
- 権限追加は最小権限を原則とし、恒常的な管理者権限の乱用を避ける。

## 8.9 緊急用権限の設計

- 緊急対応用の高権限アクセスは、通常運用用グループおよび通常運用用 Permission Set と分離する。
- 緊急用権限は対象者を限定し、利用時は事前承認または事後記録を必須とする。
- 緊急用権限の常時利用は禁止する。
- 緊急用権限の付与対象アカウントは、Management account、Infrastructure account、ROSA Production account を優先対象とする。
- 緊急時アクセス手段の具体的な保管方法および手続きは、権限管理設計または運用設計で別途定義する。

## 8.10 CLI 利用方針

- AWS CLI は IAM Identity Center 認証を前提として利用する。
- 利用者は必要な Permission Set が割り当てられた状態でサインインし、CLI 用プロファイルを利用して対象アカウントへアクセスする。
- 長期アクセスキーを用いた個人利用は認めない。
- 自動化やシステム間連携は、人用の IAM Identity Center 認証ではなく、別途システム用 IAM ロールまたはサービスロールで設計する。

## 8.11 運用方針

### 8.11.1 ユーザー追加・変更・削除

- ユーザー追加時は、所属、利用目的、対象アカウント、必要権限を確認したうえでグループへ追加する。
- 異動、役割変更、プロジェクト終了時は、所属グループおよび割当権限を見直す。
- 利用終了時は、ユーザー無効化または削除を速やかに実施する。

### 8.11.2 権限申請・承認

- 権限付与は申請・承認を前提とする。
- 本番アカウントへの高権限付与は、非本番より高い承認レベルを要求する。
- 例外的な個別付与を行った場合は、期限と解除条件を明確化する。

### 8.11.3 定期棚卸し

- グループ所属、Permission Set 割当、対象アカウントの整合性を定期的に棚卸しする。
- 不要権限、期限切れ例外、未使用アカウント割当を確認し、是正する。

## 8.12 前提・制約

- 複数会社利用を前提とするため、単一企業の LDAP や社内ディレクトリへの依存は行わない。
- Identity source は IAM Identity Center directory を利用する。
- 本設計では Permission Set の詳細権限定義までは扱わない。
- 外部 IdP 連携、SCIM 自動連携、高度な属性連携は本設計の対象外とする。
- システム用権限、IAM ロール、ブレークグラスアカウントの詳細運用は次章「権限管理設計」で定義する。
