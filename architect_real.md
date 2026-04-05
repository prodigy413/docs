# 3. 対象範囲

## 3.1 目的

- 本設計書は、AWS Organizations、IAM Identity Center、および AWS Control Tower を利用して構築する AWS マルチアカウント基盤について、対象範囲および全体構成を定義することを目的とする。
- 本設計書により、AWSアカウント管理、アクセス管理、ガバナンス統制、ログ・監査基盤、ならびに運用管理の責任分界を明確化し、今後の詳細設計および構築作業の前提を統一する。

## 3.2 設計対象

本設計書の対象は、以下のAWS基盤機能およびそれに付随する管理機能とする。

### 3.2.1 AWS Organizations

- AWS Organizations を用いたマルチアカウント管理を対象とする。
- 具体的には、組織作成、管理アカウントおよびメンバーアカウントの管理、OU（Organizational Unit）構成、SCP 等の組織統制方針を対象とする。AWS Organizations は複数アカウントを一元管理するための基盤サービスであり、マルチアカウント環境の推奨構成として利用される。

### 3.2.2 IAM Identity Center

- IAM Identity Center を用いた利用者認証およびAWSアカウントアクセス管理を対象とする。
- 具体的には、Identity source の利用方針、ユーザー・グループ設計、Permission Set 設計、各AWSアカウントへのアクセス割当を対象とする。IAM Identity Center は複数AWSアカウントに対する権限付与を一元管理する機能を提供する。

### 3.2.3 AWS Control Tower

- AWS Control Tower を用いた landing zone 構築および統制の標準化を対象とする。
- 具体的には、landing zone 構成、home Region、governed Region、必須共有アカウント、Account Factory、controls の適用方針を対象とする。AWS Control Tower は AWS Organizations、IAM Identity Center、AWS Service Catalog 等を基盤として、マルチアカウント環境の標準化とガバナンスを提供する。

### 3.2.4 管理対象アカウント

本設計の対象とするAWSアカウントは、少なくとも以下を含む。

- Management account
- Log archive account
- Audit / Security account
- Shared services account
- Production account
- Development / Test account

なお、Management account は組織管理に必要な操作へ用途を限定し、業務システムや通常ワークロードは原則配置しない方針とする。AWSでは、管理アカウントにはSCPの制限が直接適用されないため、通常のワークロード配置を避けることが推奨されている。

### 3.2.5 共通管理機能

以下の共通管理機能を本設計の対象に含める。

- アカウント払い出し方針
- アクセス管理方針
- 組織ガバナンス方針
- ログ・監査方針
- 運用・変更管理方針
- コスト管理方針

## 3.3 設計対象外

本設計書では、以下は対象外とする。

### 3.3.1 個別業務システムの詳細設計

- 各業務システム、アプリケーション、ミドルウェア、コンテナ基盤等の詳細設計は対象外とする。
- 本設計書では、これらを稼働させるための共通AWS基盤までを対象とする。

### 3.3.2 個別ネットワーク詳細設計

- 各VPCのCIDR、ルートテーブル、サブネット設計、セキュリティグループ詳細、接続機器設定等のネットワーク詳細設計は対象外とする。
- ただし、アカウント間接続方針や共通ネットワーク利用方針など、基盤レベルの方針は対象に含む。

### 3.3.3 個別監視設定・個別バックアップ設定

- 各システムに固有の監視閾値、アラーム詳細、バックアップ世代設計、復旧手順の詳細は対象外とする。
- 本設計書では、基盤全体としての監視・通知・ログ保全の基本方針のみを対象とする。

### 3.3.4 アプリケーション利用者向け運用手順

- AWS基盤利用者向けの運用手順書、操作マニュアル、申請様式、教育資料は対象外とする。
- これらは別途運用設計書または運用手順書にて定義する。

## 3.4 前提条件

本設計書では、以下を前提条件とする。

- AWSマルチアカウント構成は AWS Organizations を中心に実現する。
- 利用者のAWSアクセスは IAM ユーザーの個別払い出しを原則行わず、IAM Identity Center を用いて統一管理する。
- マルチアカウントの標準化および統制は AWS Control Tower を利用して実現する。
- 新規アカウントの作成は、原則として Control Tower の Account Factory または同等の標準手続きを用いる。Control Tower の Account Factory は landing zone 配下でアカウントの作成・登録・標準化を自動化する。
- 管理対象リージョンは、実際にワークロードを配置する必要があるリージョンに限定する。AWS Control Tower は、不要なリージョンへ landing zone を拡張しないことを推奨している。

## 3.5 制約事項

本設計書における主な制約事項を以下に示す。

- AWS Control Tower の home Region は landing zone 作成時に選択されるため、設計初期段階で確定する必要がある。
- governed Region の追加・変更時には landing zone 更新が必要となり、既存OUや既存アカウントの再登録・更新を要する場合がある。
- Management account は強い権限を持つため、利用者や用途を厳格に制限する必要がある。
- IAM Identity Center における権限付与は Permission Set を介して行い、割当時には各アカウントに IAM Identity Center 管理ロールが作成される。このため、従来の個別IAMユーザー/ロール中心設計とは運用方法が異なる。

## 3.6 想定読者

本設計書の想定読者は以下とする。

- AWS基盤設計担当者
- AWS運用管理担当者
- セキュリティ・監査担当者
- 情報システム部門
- プロジェクトマネージャー
- 各AWSアカウントの利用責任者

# 4. 全体アーキテクチャ概要

## 4.1 構成方針

本システムは、AWS Organizations を基盤としたマルチアカウント構成を採用し、IAM Identity Center により利用者アクセスを集中管理し、AWS Control Tower により landing zone とガバナンスの標準化を実現する構成とする。AWS Control Tower は AWS Organizations、IAM Identity Center、AWS Service Catalog 等と連携して動作し、アカウント払い出し、統制適用、標準設定の展開を支援する。<br><br>

本構成の主目的は以下のとおりとする。

- AWSアカウントの用途分離によるセキュリティ向上
- 権限管理の一元化
- 組織全体への統制の適用
- ログ・監査の集約
- アカウント追加時の標準化と運用負荷軽減

AWS Organizations はマルチアカウント環境の推奨基盤であり、OUやポリシーを用いて組織的なガバナンスを実現する。

## 4.2 全体構成概要

本環境は、1つの Management account の配下に複数の Member account を配置する構成とする。<br>
組織全体は用途別のOUに分割し、各OU配下に関連するアカウントを所属させる。<br>
利用者は IAM Identity Center を通じて認証され、所属グループに応じた Permission Set により、対象AWSアカウントへアクセスする。IAM Identity Center はユーザーまたはグループに対し複数AWSアカウントへのアクセスを一元的に割り当てることができる。<br><br>

AWS Control Tower は landing zone を提供し、必須共有アカウントの整備、controls の適用、Account Factory による新規アカウント払い出しを実施する。

## 4.3 論理構成

本環境の論理構成は、以下の3層で整理する。

### 4.3.1 組織管理層

組織管理層では、AWS Organizations によりAWSアカウント群を管理する。<br>
本層では、Management account、OU構成、SCP等の組織統制を扱う。<br>
Management account は、請求管理、組織設定、ポリシー管理、Control Tower 管理など、組織運営に必要な最小限の用途に限定する。AWSでは、管理アカウントを組織管理用途のみに使用し、ワークロード配置を避けることが推奨されている。

### 4.3.2 アイデンティティ管理層

アイデンティティ管理層では、IAM Identity Center を用いて利用者アクセスを一元管理する。<br>
利用者はユーザーまたはグループとして管理され、Permission Set を通じて対象AWSアカウントへアクセスする。Permission Set 割当時には、各AWSアカウントに対応ロールが自動作成・管理されるため、アカウントごとの個別IAMユーザー作成を抑制できる。

### 4.3.3 ガバナンス・標準化層

ガバナンス・標準化層では、AWS Control Tower により landing zone を構成し、組織全体へ標準設定と統制を適用する。<br>
Control Tower は Account Factory によりアカウント作成と登録を自動化し、AWS Organizations を活用して中央ガバナンスを提供する。

## 4.4 アカウント構成方針

本環境では、責務分離および運用分離の観点から、以下のアカウント種別を採用する。

### 4.4.1 Management account

AWS Organizations および AWS Control Tower の管理を行う中核アカウントとする。<br>
請求管理、組織設定変更、ポリシー管理、landing zone 管理等に利用する。<br>
本アカウントには原則として業務システムを配置しない。

### 4.4.2 Log archive account

監査ログ、操作ログ、設定履歴等の集約保管先として利用するアカウントとする。<br>
各メンバーアカウントで発生するログを集中保管し、運用アカウントや業務アカウントから分離することで、改ざん耐性および監査性を高める。

### 4.4.3 Audit / Security account

セキュリティ監視、監査、調査、統制確認等を実施するためのアカウントとする。<br>
必要に応じてセキュリティ関連サービスの集約管理先とする。

### 4.4.4 Shared services account

共通基盤機能を配置するためのアカウントとする。<br>
共通CI/CD、共通DNS、共通運用ツール、共通ネットワーク機能等を必要に応じて集約する。

### 4.4.5 Workload accounts

業務システムや開発環境を配置するアカウント群とする。<br>
本番、開発、検証、Sandbox等の単位でアカウントを分離する。<br>
AWS Organizations では、用途ごとにアカウントを分離し、命名規則と属性を一貫させることが推奨されている。

## 4.5 OU構成方針

本環境では、統制単位と責任単位を一致させることを目的としてOUを設計する。<br>
想定するOU構成例を以下に示す。

- Security OU<br>Log archive account、Audit / Security account を配置する。
- Infrastructure OU<br>Shared services account など共通基盤アカウントを配置する。
- Production OU<br>本番ワークロード用アカウントを配置する。
- Non-Production OU<br>開発、検証、テスト、Sandbox 用アカウントを配置する。

OUごとに適用するSCP、Control Tower controls、アクセス制御方針を分けることで、環境ごとのセキュリティレベルや運用ルールを整理しやすくする。AWS Organizations は OU に対するポリシー適用を前提とした管理モデルを提供する。

## 4.6 アクセス管理方針

利用者のAWSアクセスは、原則として IAM Identity Center を経由する。<br>
各利用者をグループに所属させ、グループ単位で Permission Set を割り当てる。<br>
これにより、複数アカウントへのアクセス権限を人単位ではなく職務・役割単位で管理する。<br><br>

Permission Set は、管理者権限、運用者権限、監査者権限、閲覧者権限などの役割別に定義する。<br>
また、最小権限の原則に基づき、常用権限と緊急時権限を分離する。AWS公式でも、管理系 Permission Set を作成した後、より制限の厳しい Permission Set を追加し、必要に応じて使い分けることが推奨されている。<br><br>

CLI利用についても IAM Identity Center 認証を前提とし、長期固定アクセスキーの個人払い出しは原則禁止とする。IAM Identity Center は AWS CLI を通じたロール利用にも対応する。

## 4.7 Control Tower利用方針

本環境の landing zone は AWS Control Tower を用いて構築する。<br>
home Region は初期構築時に選定し、運用開始後の変更影響が大きいため、設計段階で確定する。governed Region は、実際にワークロードを配置する必要のあるリージョンのみに限定する。AWS Control Tower は不要リージョンへの拡張を推奨していない。<br><br>

新規アカウントの作成は、原則として Account Factory を利用する。<br>
これにより、標準OUへの配置、基準設定の適用、統制の引き継ぎを一貫して実施する。Account Factory はアカウント作成・登録・カスタマイズを支援する中核機能である。<br><br>

既存アカウントを利用する場合は、Control Tower への enroll 可否を確認し、標準化と運用整合性を確保したうえで取り込む方針とする。AWS Control Tower は既存組織や既存アカウントを登録・取り込みしたうえで反映できる。

## 4.8 ログ・監査の全体方針

監査ログ、操作履歴、設定変更履歴は、ワークロードアカウントと分離された集中管理先へ保管する。<br>
これにより、各システム利用者による不用意な削除・改変リスクを低減し、監査対応時の検索性を向上させる。<br><br>

また、監査・セキュリティ確認は、業務アカウントから独立した監査用アカウントで実施できる構成を基本とする。<br>
Control Tower の landing zone は、マルチアカウント環境におけるセキュリティとコンプライアンスのベストプラクティスに基づく基盤整備を支援する。

## 4.9 運用管理の全体方針

本環境の運用では、以下を基本方針とする。

- AWSアカウント作成は標準化された申請・払い出しプロセスに統一する。
- 利用者権限はグループベースで管理し、個別付与を最小化する。
- 組織統制はOU単位で適用する。
- 管理アカウントの利用者を最小限に制限する。
- リージョン追加やOU再編時は、Control Tower landing zone 更新影響を事前確認する。

## 4.10 全体構成イメージ

本環境の全体像は、概念的には以下のとおりである。

- AWS Organizations
  - Management account
  - Security OU
    - Log archive account
    - Audit / Security account
  - Infrastructure OU
    - Shared services account
  - Production OU
    - Production accounts
  - Non-Production OU
    - Development / Test / Sandbox accounts
- IAM Identity Center
  - Users / Groups
  - Permission Sets
  - Account assignments
- AWS Control Tower
  - Landing zone
  - Governed Regions
  - Controls
  - Account Factory

この構成により、アカウント分離、権限一元管理、統制標準化を同時に実現する。

# 5. アカウント設計

## 5.1 目的

本章では、AWS Organizations、IAM Identity Center、および AWS Control Tower を用いて構築するマルチアカウント環境における AWS アカウントの構成方針、役割分担、命名規則、作成・運用方針を定義する。AWS では、複数の AWS アカウントにワークロードや機能を分離することにより、リソース分離、障害影響範囲の限定、アクセス管理の分離、およびコスト管理の明確化を実現することが推奨されている。

## 5.2 設計方針

本環境における AWS アカウント設計は、以下の方針に基づき実施する。

- AWS アカウントは、用途・責務・統制要件・運用主体の違いに応じて分離する。AWS では、アカウントをリソースの分離境界として扱い、本番環境と開発環境の分離や、機能別・統制別の分離を推奨している。
- Management account は組織管理専用とし、通常の業務ワークロードは配置しない。AWS Organizations の管理アカウントは強い権限を持ち、請求や組織設定の中核となるため、用途を限定することが推奨されている。
- 監査・ログ保管・セキュリティ運用は、業務ワークロードとは別アカウントに分離する。AWS Control Tower は Security OU 配下に Log archive アカウントと Audit アカウントを配置する構成を前提にしている。
- 新規アカウントは、原則として AWS Control Tower Account Factory もしくはそれに準じた標準手続きで払い出す。AWS Control Tower はアカウント作成と統制適用の標準化を支援する。
- アカウント名、メールアドレス、タグは用途が判別できる規則に従って統一する。AWS Organizations は、用途を反映した命名とタグ付与を推奨している。

## 5.3 アカウント構成

本環境では、最小構成として以下のアカウント種別を採用する。

### 5.3.1 Management account

Management account は、AWS Organizations および AWS Control Tower の管理に使用するアカウントとする。主な用途は、組織設定、OU 管理、SCP 管理、請求管理、Control Tower の landing zone 管理、および組織全体に関わる設定変更とする。本アカウントには、業務システム、開発資産、監視基盤、共通業務ツール等の通常ワークロードは原則配置しない。AWS でも、管理アカウントの利用は最小限に抑え、ワークロードを分離することが推奨されている。

### 5.3.2 Log archive account

Log archive account は、組織全体の監査ログ、設定変更履歴、アクセスログ等の集中保管先として使用する。AWS Control Tower の共有アカウントの一つであり、組織全体の CloudTrail および AWS Config ログの保管先として利用される。アクセス権は、監査担当者およびセキュリティ担当者に限定し、一般運用者やアプリケーション担当者には原則付与しない。

### 5.3.3 Audit account

Audit account は、セキュリティ監査、構成確認、調査、コンプライアンス確認等のために利用する。AWS Control Tower の共有アカウントの一つであり、組織内アカウントの監査・レビューを行うための中核アカウントとして位置付ける。本アカウントは、業務ワークロード運用ではなく、監査・統制・セキュリティ確認用途に限定する。

### 5.3.4 Shared services account

Shared services account は、複数の業務アカウントで共通利用する基盤機能を配置するためのアカウントとする。配置対象の例として、共通 CI/CD、共通 DNS、共通運用ツール、共通リポジトリ連携、共通監視補助機能、共通ネットワーク中継機能等を想定する。本アカウントは、業務システムそのものを載せるアカウントではなく、複数ワークロードにまたがる共通基盤を配置するためのアカウントとする。これは AWS の複数アカウント戦略における機能分離の考え方に整合する。

### 5.3.5 Production account

Production account は、本番環境のワークロードを配置するためのアカウントとする。本番系リソースは非本番系とアカウントレベルで分離し、障害影響範囲、権限範囲、および変更統制を明確に区分する。AWS では、本番環境と開発・テスト環境を別アカウントとして分離することを強く推奨している。

### 5.3.6 Non-Production account

Non-Production account は、開発、検証、テスト、ステージング、PoC 等の非本番ワークロードを配置するためのアカウントとする。非本番環境を本番環境から分離することで、運用ルール、制限事項、権限範囲、およびコスト管理を柔軟に設定できるようにする。必要に応じて、Development、Test、Staging、Sandbox をさらに個別アカウントとして分離する。

## 5.4 推奨アカウント一覧

本設計で想定する標準アカウントは以下のとおりとする。

- Management account<br>組織・請求・Control Tower 管理用
- Log archive account<br>組織ログ集中保管用
- Audit account<br>監査・セキュリティ確認用
- Shared services account<br>共通基盤機能用
- Production account<br>本番ワークロード用
- Non-Production account<br>開発・検証・テスト用

案件要件に応じて、以下の追加アカウントを検討する。

- Sandbox account<br>利用者による実験・検証専用
- Network account<br>Transit Gateway、共通出口、集約ネットワーク機能用
- Security tooling account<br>セキュリティ運用ツール専用
- Backup / DR account<br>退避データや災害対策用途

AWS Control Tower では、Security OU の中核として Log archive と Audit の共有アカウントを扱い、Sandbox OU は任意で採用できる。

## 5.5 アカウント命名規則

AWS アカウントの表示名は、用途・システム・環境が識別できる命名とする。命名規則は以下を基本とする。

<区分><システム名><環境>

例:

- PlatformManagement
- PlatformLogArchive
- PlatformAudit
- SharedServicesCommon
- WorkloadsSalesProd
- WorkloadsSalesDev

または、より簡易な規則として以下を採用してもよい。

<会社略称>-<用途>-<環境>

例:

- corp-mgmt-prd
- corp-log-sec
- corp-audit-sec
- corp-shared-common
- corp-app1-prod
- corp-app1-dev

AWS Organizations は、メンバーアカウント名とメールアドレスにアカウント用途を反映させることを推奨している。

## 5.6 アカウント用メールアドレス規則

各 AWS アカウントには固有のメールアドレスを割り当てる。メールアドレスは用途識別と再利用性を考慮し、プラスアドレスまたはエイリアスを活用する。基本規則は以下とする。

aws+<用途>+<環境>@example.com

例:

- aws+management+prod@example.com
- aws+logarchive+sec@example.com
- aws+audit+sec@example.com
- aws+shared+common@example.com
- aws+sales+prod@example.com
- aws+sales+dev@example.com

AWS Organizations のベストプラクティスでも、用途を反映したメールアドレス設計が推奨されている。

## 5.7 アカウントタグ設計

AWS アカウントには、検索性、分類、運用効率、コスト集計を目的としてタグを付与する。付与する標準タグは以下とする。

- Name
- AccountType
- Environment
- System
- Owner
- CostCenter
- Confidentiality
- ManagedBy
- SecurityLevel

例:

- Name = WorkloadsSalesProd
- AccountType = Workload
- Environment = Production
- System = Sales
- Owner = ITPlatformTeam
- ManagedBy = ControlTower

AWS Organizations はアカウントへのタグ付与をサポートしており、タグポリシーのベストプラクティスでは命名や大文字小文字の統一が推奨されている。

## 5.8 アカウント作成方針

新規アカウントは、原則として AWS Control Tower Account Factory を利用して作成する。これにより、標準 OU への配置、共通ガードレールの継承、共有アカウントとの連携、Control Tower 管理下への登録を一貫して実施する。既存アカウントを利用する場合は、AWS Control Tower への enrollment 可否および前提条件を確認したうえで取り込む。AWS Control Tower は既存 OU と既存アカウントをガバナンス配下へ取り込む機能を提供している。

## 5.9 アカウントアクセス方針

各アカウントへの人のアクセスは IAM Identity Center を経由して実施する。個人向け IAM ユーザーの恒常利用は原則禁止とし、Permission Set によりロールベースでアクセス権を付与する。AWS Organizations でアカウントを作成した場合、既定では OrganizationAccountAccessRole が作成され、この名称は一貫性を保つことが推奨されている。なお、日常運用は IAM Identity Center 中心で設計する。

## 5.10 管理アカウントの利用制限

Management account では、以下の制限を設ける。

- 日常的な業務ワークロードを配置しない
- 運用者のアクセス人数を最小限にする
- 高権限 Permission Set の割当対象を限定する
- 管理作業は必要時のみ実施する
- 監査ログおよびアクセス履歴を重点監視する

これは、管理アカウントが請求や組織設定を含む広範な管理権限を持つためである。AWS も、管理アカウントは慎重に保護し、用途を限定することを推奨している。

## 5.11 既存アカウントの取り込み方針

既存アカウントを本環境に統合する場合は、以下を確認する。

- アカウントが AWS Control Tower の enrollment 要件を満たすこと
- 既存リソースが shared account 要件や landing zone 要件と競合しないこと
- 既存の IAM ユーザー、ロール、CloudTrail、AWS Config、S3 バケット等が統制設計と整合すること
- 統合後の OU 所属先と適用 control を事前に定義すること

AWS Control Tower は、既存アカウントの enroll と既存組織への governance 拡張をサポートするが、前提条件の確認が必要である。

## 5.12 運用上の留意事項

アカウント設計の運用上の留意事項を以下に示す。

- アカウント追加時は用途と責務を明確にし、既存アカウントとの重複を避ける
- 本番系アカウントは、原則として本番ワークロード専用とする
- セキュリティ・監査・ログ保管アカウントは業務用途に流用しない
- タグ・命名規則は必須項目として統一する
- 管理アカウントを例外的な共通運用アカウントとして使わない

# 6. OU（Organizational Unit）設計

## 6.1 目的

本章では、AWS Organizations および AWS Control Tower における OU 構成、OU の役割、所属アカウントの分類方針、統制適用単位、および運用方針を定義する。AWS Organizations において OU は、複数アカウントを用途や統制要件ごとにグルーピングし、SCP などのポリシーを適用するための基本単位である。

## 6.2 設計方針

OU 設計は、以下の方針に基づき実施する。

- OU は、組織図や部門名をそのまま反映するのではなく、共通の統制要件、機能、運用責任、環境区分に基づいて設計する。AWS のセキュリティ指針でも、OU は報告系統ではなく、機能・統制・コンプライアンス要件に基づいて整理することが推奨されている。
- OU は、SCP、Tag Policy、Backup Policy、Control Tower controls 等の適用単位として利用する。
- 本番系と非本番系は OU レベルでも分離し、制限内容、変更統制、利用可能サービス、運用権限を区別する。
- Security OU は AWS Control Tower の前提に従い、Log archive および Audit を中心とする最小構成を維持する。AWS の設計ガイダンスでは、Security OU は Control Tower の要件に沿ったクリーンな構成を保つことが推奨されている。
- 共通基盤、サンドボックス、業務ワークロードは、セキュリティ共有アカウントとは別 OU に分離する。

## 6.3 OU 全体構成

本環境では、Organizations Root 配下に以下の OU を設けることを標準とする。

- Security OU
- Infrastructure OU
- Production OU
- Non-Production OU
- Sandbox OU（任意）

必要に応じて、Production OU および Non-Production OU の下位にシステム別 OU または統制別 OU を追加できる。ただし、初期段階では OU 階層を過度に深くせず、統制単位として意味のある最小構成から開始する。AWS Control Tower は OUs とアカウントの管理をガバナンスの中心として扱う。

## 6.4 各 OU の役割

### 6.4.1 Security OU

Security OU は、監査・ログ保管・組織横断セキュリティ機能を配置するための OU とする。所属アカウントは、原則として以下に限定する。

- Log archive account
- Audit account

AWS Control Tower は Security OU を作成し、その中に Log Archive と Audit の共有アカウントを配置する。AWS のガイダンスでは、この OU には Control Tower の要件に沿う中核セキュリティアカウントのみを配置し、追加のセキュリティ運用アカウントは必要に応じて別 OU に分離することが推奨されている。

### 6.4.2 Infrastructure OU

Infrastructure OU は、共通基盤機能を提供するアカウントを配置するための OU とする。代表例は Shared services account、必要に応じて Network account や Tooling account とする。業務ワークロードとは異なる変更管理、権限制御、サービス許可範囲を適用することを想定する。OU は共通のコントロールセットを持つアカウント群をまとめるための単位として利用する。

### 6.4.3 Production OU

Production OU は、本番ワークロードを配置するアカウントを所属させる OU とする。本 OU には、厳格な変更管理、利用リージョン制限、特定サービス制限、強めの監査設定、および限定的な管理権限を適用する。本番環境を非本番と分離することは AWS の基本的なマルチアカウント設計方針に合致する。

### 6.4.4 Non-Production OU

Non-Production OU は、開発、検証、テスト、ステージング等の非本番ワークロード用アカウントを配置する OU とする。本 OU では本番 OU より柔軟な権限運用や実験的利用を許容できるが、最低限の統制、ログ取得、タグ付与、コスト可視化は維持する。

### 6.4.5 Sandbox OU

Sandbox OU は、利用者の試験利用や新サービス検証、教育用途など、限定的に自由度を持たせるアカウントを配置する OU とする。AWS Control Tower では Sandbox OU を任意で活用できる設計例が示されている。Sandbox OU は本番や共通基盤と明確に分離し、利用可能サービス、予算、削除ポリシー、サポート範囲を別途定義する。

### 6.5 標準 OU 構成例

標準 OU 構成例を以下に示す。

- Root
  - Security OU
    - Log archive account
    - Audit account
  - Infrastructure OU
    - Shared services account
    - Network account（任意）
    - Tooling account（任意）
  - Production OU
    - Workload account A (Prod)
    - Workload account B (Prod)
  - Non-Production OU
    - Workload account A (Dev)
    - Workload account A (Test)
    - Workload account B (Dev)
  - Sandbox OU
    - Sandbox account 1
    - Sandbox account 2

この構成により、セキュリティ共有アカウント、共通基盤、業務本番、業務非本番、自由検証領域を明確に分離できる。AWS Control Tower は OUs と accounts を中心に governance を適用する。

## 6.6 OU 命名規則

OU 名は、用途と統制単位が明確に判別できる名称とする。標準名称は以下とする。

- Security
- Infrastructure
- Production
- Non-Production
- Sandbox

必要に応じて下位 OU を設ける場合は、以下のような規則を用いる。

- Production/BusinessSystemA
- Production/BusinessSystemB
- Non-Production/BusinessSystemA
- Non-Production/SharedDev

OU 名は、部門名や短期的なプロジェクト名よりも、継続的に意味が変わりにくい運用単位で定義する。

## 6.7 OU ごとの統制適用方針

各 OU には、以下の考え方で統制を適用する。

### Security OU

- 共有アカウント以外の配置を原則禁止
- ログ保管、監査、調査に必要なアクセスのみ許可
- 業務ワークロードのデプロイを禁止

### Infrastructure OU

- 共通基盤に必要なサービスのみ許可
- 本番業務データの常置は原則禁止
- 管理者権限は共通基盤運用担当に限定

### Production OU

- 利用リージョンを必要最小限に制限
- 危険なサービスや未承認サービスを制限
- ログ取得、タグ付与、バックアップ、監査設定を必須化
- 高権限アクセスを厳格に制限

### Non-Production OU

- 開発・検証に必要な柔軟性を確保
- 本番より緩やかな制限とするが、組織標準タグ、基本ログ、コスト可視化は必須
- 長期放置や野良リソース発生を抑止する運用を併用

### Sandbox OU

- 許可対象ユーザーを限定
- 予算上限や利用期限を設定
- 本番接続、機密データ利用、恒久運用を禁止

OU は、これらの統制をまとめて適用する単位として使う。

## 6.8 下位 OU 設計方針

将来的にアカウント数が増加した場合は、Production OU および Non-Production OU の配下に下位 OU を追加する。追加基準は以下とする。

- システムごとに異なる強い統制が必要な場合
- 監査要件や法規制が異なる場合
- 管理主体が大きく異なる場合
- コスト集計や責任分界を OU 単位で明確化したい場合

一方で、単に組織図を表現する目的や一時的な案件のためだけに OU を増やさない。AWS は、OU を機能や統制に沿って設計することを推奨している。

## 6.9 OU 変更方針

OU の新設、統合、名称変更、アカウント移動は、組織ポリシー、Control Tower controls、アカウント権限、コスト集計、運用体制に影響を与えるため、変更管理手続きを経て実施する。特に AWS Control Tower 管理下の OU は登録状態や controls 適用状態に影響するため、事前確認を必須とする。AWS Control Tower は既存 OUs の登録と governance 拡張をサポートしている。

## 6.10 運用上の留意事項

OU 設計の運用上の留意事項を以下に示す。

- Security OU は Control Tower の前提に合わせて最小限構成を維持する
- Production OU と Non-Production OU の混在を禁止する
- Shared services account は業務アプリ実行アカウントとして流用しない
- アカウント作成時に OU 所属先を必ず決定し、後追いでの整理を避ける
- OU 追加時は「適用したい統制の違い」があるかを判断基準にする
- Sandbox OU は自由利用領域ではあるが、完全無統制にはしない

# 7. 組織ポリシー・ガバナンス設計

## 7.1 目的

本章では、AWS Organizations、AWS Control Tower、および関連する組織統制機能を用いて、AWS マルチアカウント環境全体に適用するガバナンス方針を定義する。
本設計の目的は、各 AWS アカウントを独立して運用しつつも、組織全体として一貫したセキュリティ基準、運用基準、変更統制、および監査可能性を維持することである。AWS Control Tower は AWS Organizations を基盤として、継続的なガバナンスのための controls を提供し、controls は preventive、detective、proactive の3種に分類される。さらに guidance の分類として mandatory、strongly recommended、elective が用意されている。

## 7.2 設計方針

本環境における組織ポリシーおよびガバナンスは、以下の方針に基づいて設計する。

- 組織全体の統制は、アカウント単位ではなく OU 単位を基本として適用する。<br>OU は同一統制を適用すべきアカウント群を束ねる単位であり、SCP や Control Tower controls の適用境界として利用する。
- 組織ポリシーは、権限付与ではなく上限統制として扱う。<br>SCP は IAM ユーザーや IAM ロールに権限を付与するものではなく、各アカウントで利用可能な最大権限を制限するガードレールとして利用する。
- 統制は多層で実施する。<br>予防的に禁止する事項は SCP や preventive controls で制御し、逸脱を検知する事項は detective controls で監視し、作成時に要件適合を求める事項は proactive controls を利用する。
- 本番系、非本番系、セキュリティ系では統制強度を分ける。<br>同一のルールを全アカウントへ一律適用するのではなく、OU ごとの責務・リスク・運用目的に応じて制御内容を分ける。
- 例外運用は最小限とし、例外が必要な場合は申請・承認・期限付きの管理を行う。<br>組織統制は継続性が重要であるため、恒久的な例外を作らない方針とする。

## 7.3 ガバナンスレイヤ

本環境では、ガバナンスを以下のレイヤで実施する。

### 7.3.1 AWS Organizations レイヤ

AWS Organizations では、OU 構成、アカウント所属管理、SCP、タグポリシー等の組織レベル統制を実施する。SCP は複数階層にアタッチでき、評価時には組織階層上の適用結果を踏まえて有効権限が決定される。

### 7.3.2 AWS Control Tower レイヤ

AWS Control Tower では、landing zone の標準化、共有アカウント管理、controls の適用、Account Factory によるアカウント標準払い出しを実施する。AWS Control Tower は Organizations、IAM Identity Center、Service Catalog 等と連携してマルチアカウント環境を統制する。

### 7.3.3 アカウント内レイヤ

各メンバーアカウントでは、IAM ポリシー、Permission Set から作成されるロール、サービス設定、タグ運用、ログ取得設定等により個別統制を実施する。
ただし、アカウント内統制は組織統制を逸脱してはならず、Organizations および Control Tower のルールを上位制約とする。SCP はアカウント内 IAM ポリシーと交差して有効権限に影響する。

## 7.4 組織ポリシーの適用対象

本環境では、以下の単位で統制を設計する。

- Root<br>組織共通で最低限必要なガードレールのみを適用する。
- Security OU<br>Log archive account、Audit account に対し、業務ワークロード禁止や監査用途保護の統制を適用する。
- Infrastructure OU<br>Shared services account 等に対し、共通基盤用途に適した統制を適用する。
- Production OU<br>番環境に必要な強い統制を適用する。
- Non-Production OU<br>開発・検証に必要な柔軟性を残しつつ、最低限の統制を適用する。
- Sandbox OU<br>利用範囲・コスト・有効期限に関する強めの制約を適用する。

## 7.5 SCP 設計方針

SCP は粗い粒度のガードレールとして利用する。
SCP はアクセス許可を与える仕組みではなく、各アカウントで利用可能な最大権限を制限するため、細かな業務権限調整ではなく、組織として明確に禁止すべき事項に限定して利用する。AWS 公式でも、SCP は coarse-grained guardrails として使うことが示されている。

### 7.5.1 Root に適用する SCP

Root には、組織全体で共通に禁止したい内容のみを適用する。想定例は以下のとおりとする。

- 許可されていないリージョンでの操作制限
- 組織統制に関わる重要サービスの無効化防止
- セキュリティサービス停止の抑止
- 監査ログの破壊につながる操作の抑止

Root に過度な制限を設けると、将来の運用変更や統合時に影響範囲が大きくなるため、最小限とする。

### 7.5.2 Production OU に適用する SCP

Production OU には、厳格な変更統制と安定運用を意識した制限を適用する。想定例は以下のとおりとする。

- 承認対象外リージョンの利用禁止
- ルートユーザーによる通常運用の禁止方針に反する構成変更の抑止
- セキュリティ監査設定、ログ設定、バックアップ設定の停止抑止
- 未承認サービスの利用制限
- 本番に不要な高リスク操作の禁止

### 7.5.3 Non-Production OU に適用する SCP

Non-Production OU には、本番より緩やかな制限を適用する。想定例は以下のとおりとする。

- 組織で未許可のリージョン利用制限
- 監査ログ停止の抑止
- 極端に高コストまたは高リスクなサービスの利用制限
- 組織標準タグを無視した運用の抑止を補助する制御

### 7.5.4 Security OU に適用する SCP

Security OU には、共有セキュリティアカウントの目的外利用を防止する統制を適用する。想定例は以下のとおりとする。

- 業務ワークロード構築の抑止
- 特定の管理者以外による設定変更制限
- ログ削除・改変・保管先変更に関する制限

## 7.6 Control Tower controls 適用方針

AWS Control Tower controls は、landing zone 全体の継続的な統制を担う機能として採用する。controls は preventive、detective、proactive に分類され、mandatory、strongly recommended、elective の guidance があるため、これに従い適用ポリシーを定義する。

### 7.6.1 Mandatory controls

mandatory controls は、AWS Control Tower が要求する基礎統制として全対象 OU に適用する。
これらは landing zone の前提に近いため、無効化や回避を行わない方針とする。

### 7.6.2 Strongly recommended controls

strongly recommended controls は、原則適用とする。
適用除外する場合は、業務影響、代替統制、監査観点、復旧方針を明記したうえで承認を受ける。

### 7.6.3 Elective controls

elective controls は、OU の役割とリスクに応じて選択適用する。
Production OU では広めに採用し、Non-Production OU と Sandbox OU では必要性と運用負荷を評価して決定する。

## 7.7 タグポリシー利用方針

本環境では、アカウントおよび主要リソースに対し、命名・分類・コスト管理・責任分界を明確にするためのタグ運用を行う。
Organizations の管理ポリシーにはタグポリシーがあり、タグのキーや値の標準化に利用できる。一方で、タグポリシーは SCP とは異なり、許可上限を定義するものではないため、タグ準拠の推進と監視のために用いる。SCP の評価説明でも、管理ポリシーは同じ評価対象ではないことが示されている。<br><br>

標準タグは少なくとも以下を対象とする。

- Name
- Environment
- System
- Owner
- CostCenter
- ManagedBy
- Confidentiality

## 7.8 ガバナンス運用方針

組織ポリシーおよび controls の変更は、管理アカウントで実施し、変更管理手続きを経て反映する。
SCP は強い影響を持つため、変更前に対象 OU、対象アカウント、想定影響、ロールバック方法を確認する。AWS Organizations では、複数階層の SCP が評価に関与するため、意図しない権限制限が発生しないよう段階的に適用する。<br><br>

運用ルールは以下とする。

- 新規 OU 作成時は統制テンプレートを定義してから登録する
- 新規アカウントは OU 所属先決定後に controls を継承させる
- 本番系 OU の統制変更は事前レビュー必須とする
- 例外統制には有効期限と見直し日を設定する
- 定期的に controls の非準拠状態を確認する

## 7.9 例外管理方針

組織ポリシーや controls に対する例外は、以下の条件を満たす場合のみ許可する。

-業務要件または法的要件に基づく合理的理由があること
-代替統制が明確であること
-適用対象、適用期間、責任者が明確であること
-定期見直し日が設定されていること

恒久例外は原則認めず、必要であれば設計自体を改定する。

## 7.10 留意事項
- SCP は権限を与えないため、アクセス不可の原因が SCP なのか、Permission Set 側なのかを切り分ける必要がある。
- Management account は特別な位置づけを持つため、通常のメンバーアカウントと同じ発想で統制を設計しない。AWS でも管理アカウントの保護が重要視されている。
- controls と SCP の重複適用は避け、どのレイヤで何を防ぐかを明確にする。

# 8. IAM Identity Center 設計

## 8.1 目的

本章では、AWS マルチアカウント環境における利用者認証、アカウントアクセス、権限割当、および運用方法を IAM Identity Center を中心に定義する。
IAM Identity Center は、複数 AWS アカウントおよびアプリケーションへのアクセスを一元管理でき、Control Tower 環境でも標準的なアクセス管理手段として利用される。AWS Control Tower は既定で IAM Identity Center を利用して、Account Factory で作成したアカウントへのアクセス管理を支援する。

## 8.2 設計方針

本環境における IAM Identity Center 設計は、以下の方針に基づき実施する。

- 人の AWS アクセスは IAM Identity Center 経由を原則とする。<br>個人用 IAM ユーザーの恒常利用は行わず、ユーザーまたはグループに対して Permission Set を割り当てる。
- 権限はユーザー単位ではなくグループ単位で管理する。<br>日常運用では役割ベースで権限を設計し、個人への直接付与は例外とする。Control Tower のガイダンスでも、グループと permission set を組み合わせて役割を管理する考え方が示されている。
- 管理者にも常用の低権限セットを付与する。<br>IAM Identity Center では同一ユーザーに複数の Permission Set を割り当てられるため、管理者であっても日常業務はより制限された権限を選択して使用する。
- CLI 利用も IAM Identity Center ベースとする。<br>長期固定アクセスキーの個人払い出しは原則禁止し、AWS CLI の SSO 機能を利用する。AWS CLI では IAM Identity Center 用の推奨構成として SSO token provider configuration が案内されている。
- 外部 IdP を利用する場合は、SAML による認証連携と、必要に応じて SCIM によるユーザー・グループ同期を行う。外部 IdP 利用時は、IAM Identity Center にユーザーとグループを事前に認識させる必要がある。

## 8.3 配置方針

IAM Identity Center は、本 landing zone の home Region に配置された構成を前提とする。AWS Control Tower では IAM Identity Center 関連設定が home Region に紐づくため、運用時は home Region を基準に管理する。AWS Control Tower のユーザーガイドでも、IAM Identity Center 構成を home Region で管理し、削除しないよう注意が示されている。<br><br>

また、必要に応じて IAM Identity Center の delegated administrator を利用し、管理アカウント以外のアカウントへ一部管理権限を委任できる。ただし、グループ管理権限の取り扱いには注意が必要であることが AWS Control Tower ガイドでも示されている。

## 8.4 Identity source 設計

本環境では、Identity source として以下のいずれかを採用する。

### 8.4.1 IAM Identity Center directory を利用する場合

初期構築段階または小規模環境では、IAM Identity Center 内部ディレクトリを利用する。
ユーザー数が限定的であり、既存社内 IdP との連携要件がない場合に適している。

### 8.4.2 外部 IdP を利用する場合

既存の社内認証基盤が存在する場合は、外部 IdP を IAM Identity Center に接続する。
AWS 公式では、Okta や Microsoft Entra ID などの外部 IdP と接続でき、外部 IdP 利用時は SCIM または手動でユーザー・グループを IAM Identity Center にプロビジョニングする必要がある。<br><br>

本設計では、企業利用を前提として、中長期的には外部 IdP 連携を推奨構成とする。理由は以下のとおりである。

- ユーザーライフサイクルを社内標準基盤へ統合できる
- 入社、異動、退職に伴う権限変更を一元化できる
- MFA や認証ポリシーを社内認証基盤側で統制しやすい

## 8.5 ユーザー・グループ設計

IAM Identity Center では、ユーザーとグループを管理し、グループに対して Permission Set を割り当てる。
グループは職務・責務単位で設計し、部門名だけに依存しない。想定グループは以下のとおりとする。

- AWS-Org-Admins<br>組織管理、Control Tower 管理、SCP 管理担当
- AWS-Security-Auditors<br>Audit account、Log archive account の参照・監査担当
- AWS-Platform-Operators<br>Shared services account や共通基盤運用担当
- AWS-Prod-Operators<br>本番アカウント運用担当
- AWS-Dev-Engineers<br>非本番アカウント開発担当
- AWS-ReadOnly<br>閲覧専用担当
- AWS-BreakGlass-Approvers<br>緊急権限承認担当

Control Tower では preconfigured groups が用意される場合があり、環境に応じてこれらと整合させる。

## 8.6 Permission Set 設計

Permission Set は、IAM ポリシーのテンプレートとして設計し、ユーザーまたはグループに AWS アカウントアクセスを割り当てる。Permission Set は1つ以上の IAM ポリシーで構成され、同一ユーザーに複数割当も可能である。セッション時間も Permission Set ごとに設定できる。<br><br>

本環境では、少なくとも以下の Permission Set を定義する。

### 8.6.1 OrganizationAdministrator

利用対象: 管理基盤担当者
対象アカウント: Management account、必要に応じて共有アカウント
用途: Organizations、Control Tower、IAM Identity Center 管理
備考: 割当人数を最小限に限定し、常用を避ける

### 8.6.2 SecurityAudit

利用対象: 監査担当、セキュリティ担当
対象アカウント: Audit account、Log archive account、必要に応じて全メンバーアカウント
用途: ログ参照、設定確認、調査
備考: 変更権限は原則付与しない

### 8.6.3 PlatformOperator

利用対象: 共通基盤運用担当
対象アカウント: Shared services account、Infrastructure OU 配下
用途: 共通サービス運用
備考: 組織管理権限は付与しない

### 8.6.4 ProductionOperator

利用対象: 本番運用担当
対象アカウント: Production OU 配下
用途: 本番運用、障害対応
備考: IAM や Organizations 変更は不可とする方向で設計する

### 8.6.5 DeveloperPowerUser

利用対象: 開発担当
対象アカウント: Non-Production OU 配下
用途: 開発・検証
備考: 日常作業用。AWS でも管理者に追加でより制限された permission set を持たせる考え方が示されている。

### 8.6.6 ReadOnlyAccess

利用対象: 閲覧専用ユーザー
対象アカウント: 必要な全アカウント
用途: 状態確認、監査補助、問い合わせ対応
備考: 変更系操作なし

### 8.6.7 BreakGlassAdmin

利用対象: 緊急時対応要員
対象アカウント: Production OU 配下を中心に限定
用途: 重大障害時の緊急復旧
備考: 通常利用禁止、利用時の申請・承認・監査必須

## 8.7 Permission Set 命名規則

Permission Set 名は役割が明確にわかる名称とする。基本規則は以下とする。

AWS-<Role>-<Scope>

例:

- AWS-OrganizationAdministrator-Global
- AWS-SecurityAudit-Global
- AWS-PlatformOperator-Infra
- AWS-ProductionOperator-Prod
- AWS-DeveloperPowerUser-NonProd
- AWS-ReadOnly-All
- AWS-BreakGlassAdmin-Prod

## 8.8 アカウント割当方針

IAM Identity Center の割当は、グループ単位で実施する。
ユーザーへの直接割当は、一時的な対応または例外承認済みケースに限る。<br><br>

標準割当方針は以下とする。

- AWS-Org-Admins → OrganizationAdministrator → Management account
- AWS-Security-Auditors → SecurityAudit → Audit / Log archive / 必要な対象アカウント
- AWS-Platform-Operators → PlatformOperator → Shared services account
- AWS-Prod-Operators → ProductionOperator → Production OU 配下
- AWS-Dev-Engineers → DeveloperPowerUser → Non-Production OU 配下
- AWS-ReadOnly → ReadOnlyAccess → 必要な対象アカウント

この設計により、人単位ではなく役割単位でアカウントアクセスを管理する。

## 8.9 セッション時間方針

Permission Set ごとにセッション継続時間を設定する。IAM Identity Center では Permission Set ごとに session duration を設定可能である。<br><br>

標準方針は以下とする。

- 高権限管理用: 短め
- 本番運用用: 中程度
- 開発用: 業務継続性を考慮した標準長
- 閲覧専用: 標準長

具体時間はセキュリティ要件に応じて別紙で定義するが、高権限ほど短くする方針とする。

## 8.10 CLI / 自動化利用方針

CLI 利用は IAM Identity Center 認証を前提とする。AWS CLI では aws configure sso による設定が案内されており、推奨方式は SSO token provider configuration である。<br><br>

運用方針は以下とする。

- 個人用長期アクセスキーは原則禁止
- CLI 利用時は IAM Identity Center セッションを利用する
- 開発者は AWS access portal から必要な SSO Start URL と SSO Region を取得して設定する
- 作業終了後は必要に応じて aws sso logout を利用する

また、AWS 上で動作するアプリケーションや自動化ワークロードには、人用アクセスキーではなく IAM ロールによる一時認証情報を利用する。AWS IAM のベストプラクティスでも、EC2 や Lambda などの AWS コンピュートでは IAM ロールを用い、長期認証情報配布を避けることが推奨されている。

## 8.11 管理権限の委任方針

IAM Identity Center の日常管理は、必要に応じて delegated administrator を活用し、管理アカウントから分離することを検討する。
ただし、グループ管理者が管理アカウントへ割り当てられたグループにも影響を与え得るため、委任先アカウント、担当者、操作範囲を明確に制御する。AWS Control Tower ガイドでもこの点への注意が示されている。

## 8.12 ユーザーライフサイクル管理方針

ユーザーの追加、変更、停止、削除は、社内の入社・異動・退職フローに合わせて実施する。
外部 IdP を利用する場合は IdP 側をマスターとし、IAM Identity Center へ同期する。外部 IdP 連携時は、ユーザーとグループを IAM Identity Center に事前プロビジョニングしてから割当を行う必要がある。<br><br>

運用ルールは以下とする。

- 新規ユーザーはグループ所属と同時に権限を有効化する
- 異動時は旧グループから除外し、新グループへ追加する
- 退職時は即時無効化する
- 休職・委託終了時もアクセス停止を行う
- 定期的に割当棚卸しを実施する

## 8.13 緊急時アクセス方針

重大障害または通常権限での復旧不可時に限り、BreakGlassAdmin を利用する。
緊急権限は常用せず、利用時は以下を必須とする。

- 事前承認または事後承認ルール
- 利用理由の記録
- 利用時間の記録
- 実施操作の監査ログ確認
- 利用後の棚卸し

高権限の常用を避け、必要時のみ昇格する設計とする。

## 8.14 留意事項

- AWS Control Tower で IAM Identity Center を self-manage に切り替えた場合、Control Tower が自動作成する顧客向けグループやロールの振る舞いが変わるため、初期設計時に方針を決めておく必要がある。
- home Region を誤って変更前提で扱わないこと。IAM Identity Center と Control Tower の運用は home Region 依存が強い。
- Permission Set の不足と SCP 制限は似た挙動に見えるため、障害切り分け手順を別途整備する。

# 9. 権限管理設計

## 9.1 目的

本章では、AWS Organizations、IAM Identity Center、および各 AWS アカウント内の IAM を前提として、AWS マルチアカウント環境における権限管理の基本方針、権限の分類、付与方法、運用方法、および緊急時のアクセス制御方針を定義する。
AWS では、人およびワークロードの双方に対して IAM ロールと一時的な認証情報を使うことが推奨されており、恒久的な認証情報の使用は最小化することが推奨されている。

## 9.2 設計方針

本環境における権限管理は、以下の方針に基づいて設計する。

- 人のアクセスは IAM Identity Center を経由したロールベースアクセスを原則とする。<br>個人用 IAM ユーザーの恒常利用は原則禁止とし、Permission Set により各 AWS アカウントへアクセスさせる。IAM Identity Center の Permission Set は IAM ポリシーのテンプレートとして機能し、アカウント割当時に各アカウント内へ対応ロールが作成される。
- 権限は最小権限の原則に従って設計する。<br>日常業務に必要な権限のみを通常付与し、組織管理や緊急対応に必要な高権限は限定された利用者にのみ付与する。AWS IAM のベストプラクティスでも最小権限と一時的認証情報の利用が推奨されている。
- 人用権限とシステム用権限を分離する。<br>人が操作するための権限と、AWS サービスや自動化ジョブが利用する権限は別管理とし、ワークロードには IAM ロールを利用する。AWS は AWS 上のワークロードに対してロール利用を推奨している。
- 組織統制とアカウント内権限を分離する。<br>SCP は利用可能な最大権限を制限する上位ガードレールとし、Permission Set や IAM ロールは実際の操作権限を与えるために用いる。Organizations では、アカウントの有効権限は SCP と IAM 権限の両方の影響を受ける。
- 緊急時アクセスは通常権限と分離する。<br>障害対応や重大インシデント対応に必要な高権限は、Break Glass 用の権限セットまたは専用ロールとして分離し、通常時は使用しない。

## 9.3 権限管理の対象

本環境における権限管理対象は、以下の 3 区分とする。

- 人用アクセス権限
- システム／ワークロード用権限
- 緊急時アクセス権限

この区分により、利用者の責務、認証方式、監査対象、および棚卸し方法を明確に分離する。

## 9.4 人用アクセス権限

人用アクセス権限は、IAM Identity Center を通じて付与する。
ユーザーはグループへ所属し、グループごとに Permission Set を AWS アカウントへ割り当てる。
これにより、個人単位ではなく職務・役割単位で権限管理を行う。IAM Identity Center の Permission Set は複数アカウントへ一貫したアクセス付与を行うための中心機能である。<br><br>

人用アクセス権限は、少なくとも以下の権限区分で管理する。

- 組織管理権限
- セキュリティ監査権限
- 共通基盤運用権限
- 本番運用権限
- 非本番開発／運用権限
- 閲覧専用権限
- 緊急時管理権限

## 9.5 システム／ワークロード用権限

AWS 上で動作するアプリケーション、Lambda、EC2、EKS、CI/CD ジョブ等のシステム権限は、IAM ロールにより付与する。
アクセスキーの静的配布は原則禁止とし、必要なサービスに対して一時的認証情報を取得できるロールを割り当てる。AWS IAM のベストプラクティスでは、ワークロードに対し IAM ロールと一時的認証情報を使うことが推奨されている。<br><br>

外部環境で動作するワークロードについても、長期アクセスキーではなく、可能な限り一時的認証情報を用いる。AWS では AWS 外のワークロード向けにも Roles Anywhere を含む一時的認証情報の仕組みを提供している。

## 9.6 緊急時アクセス権限

緊急時アクセス権限は、重大障害、セキュリティインシデント、通常権限では復旧不能な事象に限定して利用する。<br>
通常運用で使用する権限と分離し、利用対象者、利用条件、承認手続き、ログ確認、および事後レビューを明確に定義する。<br>
高権限は恒常的に配布せず、必要なときのみ使う運用とする。<br><br>

## 9.7 権限付与モデル

本環境では、以下の多層構造で権限を管理する。

### 9.7.1 組織レベルの上限制御

Organizations の SCP により、各 OU またはアカウントで利用可能な最大権限を制限する。<br>
SCP は権限付与を行わず、許可上限を制御する。したがって、SCP で禁止された操作は、Permission Set や IAM ポリシーで許可されていても実行できない。

### 9.7.2 アカウントアクセス付与

IAM Identity Center の Permission Set により、どの利用者がどの AWS アカウントへアクセスできるかを定義する。<br>
Permission Set の割当結果としてアカウント側に対応ロールが作成され、ユーザーはそのロールを利用してアクセスする。

### 9.7.3 アカウント内権限

各アカウント内では、IAM ロール、リソースポリシー、KMS キーポリシー、S3 バケットポリシー等により細かなアクセス制御を実施する。<br>
ただし、これらは組織レベルの制約を超えることはできない。

## 9.8 権限区分設計

本環境では、権限を以下の区分で設計する。

### 9.8.1 Organization Administrator

Management account を中心に、Organizations、Control Tower、IAM Identity Center の設定変更を実施できる権限とする。<br>
付与対象は最小限とし、日常的なアプリケーション運用者には付与しない。Management account は組織全体の重要設定を管理するため、アクセス対象を厳格に制限する。

### 9.8.2 Security Auditor

Audit account および Log archive account を中心に、ログ参照、設定確認、コンプライアンス確認、調査を実施するための権限とする。<br>
AWS Control Tower の Audit account は、セキュリティおよびコンプライアンスチームが監査を実施するための共有アカウントとして位置づけられている。

### 9.8.3 Platform Operator

Shared services account や共通基盤向けアカウントに対して、共通基盤運用、共通ツール保守、共通ネットワーク機能の運用等を行うための権限とする。<br>
Organizations や Control Tower 変更権限は原則含めない。

### 9.8.4 Production Operator

Production OU 配下の本番ワークロードアカウントに対し、障害対応、設定変更、運用保守を行うための権限とする。<br>
本番系は特に変更影響が大きいため、IAM 管理や組織管理まで含めた過剰権限は避ける。

### 9.8.5 Developer / Non-Production Operator

Non-Production OU 配下で、開発、検証、構築、試験を実施するための権限とする。<br>
本番系より柔軟な権限を許容するが、組織統制の範囲内に制限する。

### 9.8.6 Read Only

状態確認、監査補助、運用支援、問い合わせ対応等のための閲覧専用権限とする。<br>
基本的にすべての変更系操作を含めない。

### 9.8.7 Break Glass Administrator

重大障害・緊急復旧用途のみに利用する高権限とする。<br>
通常利用を禁止し、利用時の記録と事後レビューを必須とする。

## 9.9 Permission Set と IAM ロールの関係

人用アクセスでは IAM Identity Center の Permission Set を使用し、システム用アクセスでは IAM ロールを使用する。<br>
Permission Set は人に対してアカウントアクセスを割り当てるための仕組みであり、IAM ロールは AWS 内外のワークロードやアカウント間アクセスを実現する仕組みである。AWS では、ロールを引き受けることで一時的認証情報が発行される。<br><br>

このため、設計上は以下の責務分離を行う。

- 人 → IAM Identity Center + Permission Set
- AWS 上のワークロード → IAM ロール
- AWS 外のワークロード → 原則一時的認証情報を利用する IAM ロール系方式
- 緊急対応 → 専用 Permission Set または専用ロール

## 9.10 アカウント間アクセス

組織管理や特定運用で必要なアカウント間アクセスは、明示的な IAM ロール引受により実施する。<br>
AWS Organizations で作成した新規メンバーアカウントには、既定で OrganizationAccountAccessRole が作成され、管理アカウントからの管理アクセスに利用できる。既存アカウントを組織へ招待して参加させた場合は、同等のロールを別途作成できる。<br><br>

ただし、日常的な人のアクセスはこのロールではなく、IAM Identity Center を中心に運用する。
OrganizationAccountAccessRole は、主に組織管理や移行時対応など限定用途で使用する。

## 9.11 認証情報管理方針

本環境では、以下の方針で認証情報を管理する。

- 個人用長期アクセスキーの払い出しは禁止を原則とする
- root ユーザーは緊急用途のみに限定する
- MFA を必須とする
- 人の CLI 利用は IAM Identity Center ベースとする
- システムの認証情報は一時的認証情報またはサービスロールを利用する

AWS IAM では、長期認証情報よりも一時的認証情報の利用が推奨されている。

## 9.12 権限付与・変更・削除フロー

権限の付与、変更、削除は、以下の運用を基本とする。

- 新規付与<br>所属、職務、対象アカウント、利用期間を明確化したうえで、グループ単位で付与する
- 変更<br>異動、担当変更、プロジェクト変更に応じてグループ所属または割当アカウントを変更する
- 削除<br>退職、契約終了、担当解除時に即時削除する
- 定期棚卸し<br>一定周期でグループ所属、Permission Set 割当、例外権限をレビューする

外部 IdP を利用する場合は、可能な限り IdP 側のライフサイクル管理と連携させる。

## 9.13 緊急時権限運用

Break Glass 権限の利用時は、以下を必須とする。

- 利用理由の記録
- 承認者の記録
- 利用開始／終了時刻の記録
- 実施操作のログ確認
- 利用後レビュー

高権限は付与すること自体が目的ではなく、通常権限で足りない例外的状況を安全に処理するための最後の手段として扱う。

## 9.14 留意事項

- アクセス拒否時は、SCP による制限、Permission Set 不足、アカウント内 IAM 制約のどれかを切り分ける必要がある。
- Management account に対する高権限配布は最小限とする。Control Tower と Organizations の中心機能が集約されるためである。
- OrganizationAccountAccessRole は存在しても、日常の人用アクセス設計の中心に据えない。

# 10. Control Tower 設計

## 10.1 目的

本章では、AWS Control Tower を用いた landing zone の構成方針、共有アカウント、リージョン設計、OU 登録方針、アカウント払い出し方針、および既存アカウントの取り込み方針を定義する。<br>
AWS Control Tower は、AWS Organizations、IAM Identity Center、Service Catalog 等と連携して、マルチアカウント環境の標準化と継続的ガバナンスを提供する。

## 10.2 設計方針

本環境における Control Tower 設計は、以下の方針に基づいて実施する。

- landing zone は AWS マルチアカウント環境の標準基盤として利用する。<br>アカウント作成、共有アカウント管理、controls 適用、OU 単位の統制を Control Tower の運用モデルへ統一する。
- home Region は初期構築時に慎重に決定する。<br>Control Tower の home Region は landing zone 作成時に決まり、後から変更できない。
- governed Region は必要最小限に限定する。<br>AWS は、実際にワークロードを実行する予定がないリージョンまで landing zone を拡張しないことを推奨している。
- 新規アカウントは原則として Account Factory 系の標準手段で作成する。<br>これにより、アカウント作成後に Control Tower のベースラインや controls を一貫して適用する。
- 既存アカウントを利用する場合は、enroll 方針を明確にする。<br>既存アカウントを governance 配下に取り込む場合、前提条件や競合リソースを確認してから登録する。

## 10.3 landing zone 構成方針

本環境では、Control Tower により landing zone を構築し、AWS Organizations 配下の複数アカウントに対して標準設定を展開する。<br>
landing zone の中核要素として、少なくとも以下を管理対象とする。

- Management account
- Log archive account
- Audit account
- 登録対象 OU
- governed Region
- controls
- Account Factory

Control Tower は landing zone 作成および更新時に、共有アカウントや対象 OU／アカウントへベースラインや関連リソースを展開する。

## 10.4 home Region 設計

home Region は、Control Tower 運用の中核となるリージョンとして定義する。<br>
landing zone 作成時に選択したリージョンが home Region となり、後から変更はできない。Control Tower の一部リソースは home Region に作成される。<br><br>

home Region の選定にあたっては、以下を評価基準とする。

- 運用チームが主に利用するリージョンであること
- 関連する主要ワークロードの配置計画と整合すること
- 監査・運用上の主たる管理拠点として妥当であること
- 将来の Region 拡張方針と整合すること

## 10.5 governed Region 設計

governed Region は、Control Tower による governance を有効にする対象リージョンとして定義する。<br>
AWS は、ワークロードを配置する必要があるリージョンに限定して governed Region を設定することを推奨している。governed Region を追加または削除すると landing zone 更新が行われ、既存アカウントは自動更新されないため、OU の再登録が必要になる場合がある。<br><br>

本設計では、以下の方針を採用する。

- 初期導入時は必要最小限の governed Region のみ選定する
- 新規 Region を追加する場合は、業務要件、統制要件、コスト、運用負荷を評価する
- Region 変更時は landing zone 更新影響と OU 再登録要否を事前確認する

## 10.6 共有アカウント設計

Control Tower の共有アカウントとして、少なくとも Audit account と Log archive account を採用する。<br>
これらは landing zone 作成時に自動セットアップでき、既存アカウントを指定することも可能である。AWS は、これら shared accounts を移動または削除しないよう案内している。

### 10.6.1 Log archive account

Log archive account は、登録 OU に属するアカウント群のログ集中保管先として利用する。<br>
運用チームや監査チームが組織全体のログへアクセスするための中核アカウントとする。

### 10.6.2 Audit account

Audit account は、セキュリティおよびコンプライアンス確認のための共有アカウントとする。<br>
AWS の説明では、Audit account はセキュリティ／コンプライアンスチーム向けに設計され、landing zone 内アカウントに対する監査用途のクロスアカウントロール利用を想定している。

## 10.7 OU 登録方針

Control Tower は OU を governance 対象として登録し、その OU に属するアカウントへ controls や baseline を適用する。<br>
Control Tower の controls は OU 単位で適用され、その OU 内のすべてのアカウントに影響する。<br><br>

本設計では、以下を標準登録対象とする。

- Security OU
- Infrastructure OU
- Production OU
- Non-Production OU
- Sandbox OU（必要に応じて）

OU 新設時は、登録前に以下を確認する。

- 配下アカウントの目的が統一されていること
- 適用すべき controls が明確であること
- ベースライン適用影響を把握していること

## 10.8 baseline 設計方針

Control Tower では baseline が OU や landing zone 全体に適用される設定のまとまりとして扱われる。
AWS の用語定義では、AWSControlTowerBaseline は OU 登録を支援する主要 baseline の一つである。

本環境では、登録 OU に対して Control Tower 標準 baseline を適用し、OU ごとの controls をその上に追加する。
独自設定は baseline の置換ではなく、Account Factory customization や後続の IaC により補完する。

## 10.9 controls 適用方針

controls は、OU ごとの統制要件に基づいて適用する。<br>
controls には preventive、detective、proactive の 3 種類があり、mandatory、strongly recommended、elective の guidance が存在する。<br><br>

本設計では、以下の方針を採用する。

- mandatory controls は対象 OU に原則適用する
- strongly recommended controls は原則採用し、未適用時は理由を明文化する
- elective controls は OU ごとの用途・リスクに応じて選定する
- Production OU では比較的広く controls を適用する
- Sandbox OU では自由度とコスト統制の両立を意識して選定する

## 10.10 Account Factory 設計

新規アカウントの標準払い出しは、Control Tower Account Factory を利用することを原則とする。<br>
AWS Control Tower では、Organizations がアカウントを作成した後、Control Tower が blueprints や controls を適用してプロビジョニングを完了させる。<br><br>

Account Factory 利用時は、少なくとも以下を入力標準とする。

- アカウント表示名
- アカウント用メールアドレス
- 所属 OU
- SSO ユーザー／アクセス管理方針
- 必要な初期タグ

また、アカウント作成後に追加設定が必要な場合は、Account Factory customization もしくは Terraform ベースの AFT を利用する。<br>
Account Factory customization は新規・既存アカウントのカスタマイズを自動化でき、AFT は Terraform パイプラインでアカウントのプロビジョニングとカスタマイズを支援する。

## 10.11 AFT 利用方針

Terraform を用いたアカウント払い出し標準化が必要な場合は、Account Factory for Terraform（AFT）を利用する。<br>
AFT は Control Tower 環境上で Terraform ベースのアカウントプロビジョニングとカスタマイズを行う仕組みであり、専用の AFT 管理アカウントを用いて構築することが推奨されている。<br><br>

本設計では、以下の場合に AFT 利用を推奨する。

- アカウント払い出しを Git ベース申請で管理したい場合
- Terraform で組織標準設定を自動適用したい場合
- Account Factory 単体では不足するカスタマイズを標準化したい場合

## 10.12 既存アカウントの enroll 方針

既存アカウントを Control Tower 管理下へ取り込む場合は、Enroll account 機能または対応する標準手続きを用いる。<br>
AWS Control Tower のコンソールには既存アカウントを governance 配下に登録する機能があり、登録前に競合リソースや前提条件を確認する必要がある。共有アカウントとして既存アカウントを利用する場合も、Control Tower 要件に競合するリソースがないかを確認する。<br><br>

既存アカウント取り込み時は、以下を確認する。

- 既存 CloudTrail、AWS Config、S3 バケット等が Control Tower の期待値と競合しないこと
- 対象 OU と適用 controls が事前に決まっていること
- アカウントの運用責任者が明確であること
- 必要なクロスアカウントアクセスや初期ロール整備方針が決まっていること

## 10.13 リソース変更方針

Control Tower により作成または管理されるリソースは、可能な限り Control Tower の管理境界を尊重して扱う。<br>
アカウント作成・登録時には、IAM ロール、CloudTrail 関連設定、Service Catalog プロビジョニング済み製品などのリソースが配置される場合がある。AWS は、Control Tower リソースの手動変更について注意を促している。<br><br>

したがって、本設計では以下を原則とする。

- Control Tower 管理対象リソースを手動で変更しない
- 変更が必要な場合は AWS のガイダンスと影響を確認する
- 個別設定は Account Factory customization、AFT、または別 IaC レイヤで管理する

## 10.14 運用方針

Control Tower の日常運用では、以下を実施する。

- landing zone 状態の定期確認
- controls の準拠状況確認
- governed Region 変更時の影響確認
- OU の登録状態確認
- 新規アカウント払い出しの標準化
- 共有アカウント保護状態の確認

特に Region 変更や OU 再編は landing zone 更新や再登録に影響するため、変更管理対象とする。

## 10.15 留意事項

- home Region は後から変更できないため、初期設計時の判断が重要である。
- governed Region を変更しても既存アカウントは自動更新されない場合があり、OU 再登録が必要になる。
- shared accounts は landing zone の中核であり、移動・削除を避ける。
- Control Tower 管理対象リソースの直接変更は、将来の更新や整合性に影響する可能性がある。
