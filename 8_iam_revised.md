# 8. IAM Identity Center 設計

## 8.1 目的

本章では、AWS Organizations、AWS Control Tower を用いて構築する AWS マルチアカウント基盤における、人の認証方式、AWS アカウントへのアクセス方式、権限割当方法、および運用方針を定義する。

本環境では、人の AWS アクセスを IAM Identity Center に統一し、アカウント横断の権限管理を一元化する。これにより、管理アカウントおよびメンバーアカウントに対するアクセス制御、運用権限の分離、権限付与・変更・削除の標準化を実現する。

## 8.2 設計方針

本環境の IAM Identity Center 設計は、以下の方針で統一する。

- 人の AWS アクセスは IAM Identity Center 経由に統一する。
- 個人向け IAM ユーザーは、恒常運用では作成しない。
- 権限はユーザー単位ではなく、グループ単位で管理する。
- AWS アカウントへのアクセス権限は Permission Set により付与する。
- 管理者、監査担当、共通基盤運用担当、本番運用担当、開発担当、閲覧専用担当を分離する。
- 高権限の常用を避け、通常作業用権限と管理用権限を分離する。
- CLI 利用も IAM Identity Center ベースとし、個人用の長期アクセスキーは発行しない。
- AWS 上で動作するアプリケーションや自動化処理には、人用認証情報ではなく IAM ロールを利用する。

## 8.3 配置方針

IAM Identity Center は、本 landing zone の home Region に配置された構成を前提とする。IAM Identity Center に関する設定変更、ユーザー・グループ管理、Permission Set 管理は、home Region を基準に実施する。

また、IAM Identity Center の管理は原則として管理アカウントで実施する。管理権限の委任が必要な場合のみ delegated administrator の利用を検討するが、初期構成では採用しない。

## 8.4 Identity source 設計

本環境の Identity source は、**IAM Identity Center directory** を採用する。

採用理由は以下のとおりである。

- 本環境は複数会社で利用し、特定企業の社内認証基盤を共通の認証元として前提にできないため
- 各利用者を IAM Identity Center 上で直接管理する構成のほうが、初期導入および運用責任の分界を明確にしやすいため
- 外部 IdP 連携、SCIM 連携、LDAP 連携を前提としないことで、初期構成を簡素化できるため

したがって、本設計では外部 IdP 連携を前提とした記述は採用しない。

## 8.5 ユーザー・グループ設計

IAM Identity Center では、ユーザーを直接管理し、グループ単位で Permission Set を割り当てる。  
グループは部門名ではなく、運用上の責務単位で設計する。

標準グループは以下とする。

| グループ名 | 用途 |
|---|---|
| AWS-Org-Admins | Organizations、Control Tower、IAM Identity Center 管理担当 |
| AWS-Security-Auditors | Audit account、Log archive account の参照・監査担当 |
| AWS-Platform-Operators | Infrastructure account の運用担当 |
| AWS-Prod-Operators | ROSA Production account の運用担当 |
| AWS-Stg-Operators | ROSA Staging account の運用担当 |
| AWS-EVS-Operators | EVS Common account の運用担当 |
| AWS-ReadOnly | 閲覧専用担当 |
| AWS-BreakGlass-Approvers | 緊急権限利用の承認担当 |

ユーザーへの直接割当は原則行わず、例外承認済みの一時対応に限定する。

## 8.6 Permission Set 設計

Permission Set は、IAM Identity Center から各 AWS アカウントにアクセスするための標準権限単位として定義する。  
本設計では、過度に細分化した Permission Set は作成せず、責務に応じた最小限の種類に整理する。

標準 Permission Set は以下とする。

### 8.6.1 OrganizationAdministrator

- 利用対象: 管理基盤担当者
- 対象アカウント: Management account
- 用途: AWS Organizations、AWS Control Tower、IAM Identity Center の管理
- 方針: 割当人数は最小限とし、日常作業では常用しない

### 8.6.2 SecurityAudit

- 利用対象: 監査担当、セキュリティ担当
- 対象アカウント: Audit account、Log archive account、必要に応じて各メンバーアカウント
- 用途: ログ参照、設定確認、監査、調査
- 方針: 原則として変更権限は付与しない

### 8.6.3 InfrastructureOperator

- 利用対象: 共通基盤運用担当
- 対象アカウント: Infrastructure account
- 用途: 共通基盤の構築、変更、運用
- 方針: 組織管理権限は付与しない

### 8.6.4 ProductionOperator

- 利用対象: 本番運用担当
- 対象アカウント: ROSA Production account
- 用途: 本番環境の運用、障害対応
- 方針: Organizations、IAM Identity Center、請求管理などの組織共通管理権限は付与しない

### 8.6.5 StagingOperator

- 利用対象: ステージング環境運用担当
- 対象アカウント: ROSA Staging account
- 用途: ステージング環境の運用、検証
- 方針: 本番管理権限とは分離する

### 8.6.6 EVSOperator

- 利用対象: EVS 運用担当
- 対象アカウント: EVS Common account
- 用途: EVS 環境の運用
- 方針: 単一アカウント運用であることを前提に、必要範囲に限定して付与する

### 8.6.7 ReadOnlyAccess

- 利用対象: 閲覧専用ユーザー
- 対象アカウント: 必要な全アカウント
- 用途: 状態確認、監査補助、問い合わせ対応
- 方針: 変更系操作は付与しない

### 8.6.8 BreakGlassAdmin

- 利用対象: 緊急時対応要員
- 対象アカウント: 原則として ROSA Production account を中心に限定
- 用途: 重大障害時の緊急復旧
- 方針: 通常利用は禁止し、利用時は承認・記録・事後確認を必須とする

## 8.7 Permission Set 命名規則

Permission Set 名は、役割と対象範囲が判別できる名称とする。  
命名規則は以下とする。

`AWS-<Role>-<Scope>`

例:

- AWS-OrganizationAdministrator-Management
- AWS-SecurityAudit-Shared
- AWS-InfrastructureOperator-Infra
- AWS-ProductionOperator-Prod
- AWS-StagingOperator-Stg
- AWS-EVSOperator-Common
- AWS-ReadOnly-All
- AWS-BreakGlassAdmin-Prod

## 8.8 AWS アカウント割当方針

IAM Identity Center の割当はグループ単位で実施する。  
標準割当は以下のとおりとする。

| グループ | Permission Set | 対象アカウント |
|---|---|---|
| AWS-Org-Admins | OrganizationAdministrator | Management account |
| AWS-Security-Auditors | SecurityAudit | Audit account、Log archive account、必要な対象アカウント |
| AWS-Platform-Operators | InfrastructureOperator | Infrastructure account |
| AWS-Prod-Operators | ProductionOperator | ROSA Production account |
| AWS-Stg-Operators | StagingOperator | ROSA Staging account |
| AWS-EVS-Operators | EVSOperator | EVS Common account |
| AWS-ReadOnly | ReadOnlyAccess | 必要な対象アカウント |

なお、Management account へのアクセスは最小限の管理者に限定し、開発担当や一般運用担当への割当は行わない。

## 8.9 セッション時間方針

Permission Set ごとにセッション継続時間を設定する。  
高権限ほど短くし、閲覧専用や開発用途は業務継続性を考慮した標準時間とする。

具体的な時間値は別紙のセキュリティ設定基準に従うが、少なくとも以下の方針を適用する。

- 組織管理権限: 短時間
- 本番運用権限: 中程度
- ステージング運用権限: 標準
- 閲覧専用権限: 標準

## 8.10 CLI 利用方針

CLI 利用は IAM Identity Center 認証を前提とする。  
利用者は AWS CLI の SSO 設定を実施し、IAM Identity Center セッションを用いて操作する。

運用方針は以下のとおりとする。

- 個人用長期アクセスキーは原則禁止とする
- CLI 利用時は IAM Identity Center の認証セッションを利用する
- 利用者は AWS access portal から必要な情報を取得して設定する
- 共用端末や作業端末では、作業終了後にセッションを終了する

## 8.11 自動化・システム認証方針

AWS 上で動作するアプリケーション、バッチ、CI/CD、運用自動化処理には、人用の IAM Identity Center 認証情報を使用しない。

システム認証は以下の方針とする。

- AWS 上のワークロードは IAM ロールを利用する
- EC2、Lambda、EKS、ROSA などでは、実行主体に応じた IAM ロールを割り当てる
- 長期アクセスキーをコード、設定ファイル、CI/CD 変数へ保存しない
- 人の操作とシステムの操作は認証主体を分離する

## 8.12 ユーザーライフサイクル管理方針

IAM Identity Center directory を利用するため、ユーザーの追加、変更、停止、削除は IAM Identity Center 上で実施する。

運用ルールは以下のとおりとする。

- 新規ユーザー作成時は、所属グループを同時に設定する
- 権限変更時は、既存グループからの削除と新グループへの追加で対応する
- 利用終了時は、速やかにユーザーを無効化または削除する
- 委託終了、異動、退任時も同様にアクセス停止を実施する
- 定期的にグループ所属およびアカウント割当を棚卸しする

## 8.13 緊急時アクセス方針

通常権限での復旧ができない重大障害時に限り、BreakGlassAdmin を利用できる。  
BreakGlassAdmin の利用時は、以下を必須とする。

- 事前承認、または緊急時ルールに基づく事後承認
- 利用理由の記録
- 利用者、利用開始時刻、利用終了時刻の記録
- 実施操作の監査ログ確認
- 利用後の事後レビュー

BreakGlassAdmin は常設の通常業務用権限として利用しない。

## 8.14 運用上の注意事項

- 管理アカウントの高権限は最小人数に限定する
- Permission Set の追加や変更は、対象アカウント、用途、影響範囲を確認したうえで実施する
- 本番アカウント向け権限は、ステージングや共通基盤向け権限と分離して管理する
- 例外的なユーザー直接割当は、期限と理由を明記して管理する
- IAM Identity Center 設定変更は、home Region を基準に実施する
