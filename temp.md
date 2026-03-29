```
# 基本設計書の項目案

対象: AWS Organizations / IAM Identity Center / Control Tower を利用したAWSマルチアカウント基盤

## 1. 文書情報

- 文書名
- 版数 / 更新履歴
- 作成者 / レビュー者 / 承認者
- 作成日 / 最終更新日
- 関連文書一覧

## 2. 目的・背景

- 本設計の目的
- 導入背景
- 解決したい課題
- 対象システム概要
- 想定利用部門 / 利用者

## 3. 対象範囲

- 設計対象
  - AWS Organizations
  - IAM Identity Center
  - AWS Control Tower
  - 管理アカウント / メンバーアカウント
- 設計対象外
  - 各業務システム個別設計
  - アプリケーション詳細設計
  - ネットワーク詳細設計
- 前提条件
- 制約事項

## 4. 全体アーキテクチャ概要

- 全体構成図
- マルチアカウント構成概要
- 各サービスの役割
  - Organizations: アカウント統制・OU・ポリシー管理
  - IAM Identity Center: ユーザー/グループへの複数アカウントアクセス管理
  - Control Tower: landing zone 構築、ガバナンス、Account Factory による標準化されたアカウント払い出し
- 管理対象リージョンの考え方
- 他サービスとの関係
  - CloudTrail
  - AWS Config
  - Security services
  - Log archive / Audit account

## 5. アカウント設計

- アカウント体系
- アカウント種別
  - Management account
  - Log archive account
  - Audit / Security account
  - Shared services account
  - Production account
  - Development / Test / Sandbox account
- アカウント命名規則
- アカウント払い出し方針
- Account Factory 利用方針
- 既存アカウントの移行 / enroll 方針
- rootユーザー利用方針
- 管理アカウント利用制限方針<br>AWS公式でも、管理アカウントは組織管理など必要な用途に限定し、ワークロードを置かないことが推奨されています。

## 6. OU（Organizational Unit）設計

- OU構成方針
- OU一覧
- OUごとの用途
- OU階層構成
- 基盤用OU / 業務用OU / Sandbox用OU の分離方針
- 将来拡張方針<br>AWS OrganizationsではOUでアカウントをグルーピングして統制する設計が推奨されています。

## 7. 組織ポリシー・ガバナンス設計

- SCP 設計方針
- RCP 利用有無 / 利用方針
- Control Tower Controls 適用方針
- 必須統制 / 推奨統制 / 任意統制の区分
- リージョン制限
- 禁止サービス / 制限操作
- タグポリシー利用方針
- バックアップポリシー利用方針
- 例外申請 / 一時緩和運用

## 8. IAM Identity Center 設計

- Identity source 方針
  - Identity Center directory
  - 外部IdP連携有無
- 認証方式
- ユーザー / グループ設計
- グループ命名規則
- Permission Set 設計方針
- Permission Set 一覧
- AWSアカウント割当方針
- 管理者権限 / 運用者権限 / 閲覧権限の分離
- 緊急用権限の設計
- CLI利用方針<br>IAM Identity Center は複数AWSアカウントへのアクセスを一元管理でき、Permission Set を複数アカウントへ割り当て可能です。AWS CLI も IAM Identity Center 認証に対応しています。

## 9. 権限管理設計

- 権限管理の基本方針
- 最小権限の原則
- Permission Set と IAM Role の関係
- ブレークグラスアカウント運用
- 管理権限の分離
- 人用権限とシステム用権限の分離
- 権限付与 / 変更 / 削除フロー
- 定期棚卸し方針

## 10. Control Tower 設計

- Landing zone 設計方針
- ホームリージョン / governed Region 方針
- 必須共有アカウント設計
- Control Tower controls 適用対象
- Account Factory 設計
- 既存Organizationsとの整合方針
- 自動作成リソースの扱い
- ランディングゾーン更新方針
- Control Tower は landing zone を中核に、Organizations を基盤として統制を提供します。

## 11. ログ・監査設計

- CloudTrail 設計
- AWS Config 設計
- ログ保存先アカウント
- ログ保管期間
- アクセスログ / 監査ログの区分
- 改ざん防止方針
- 監査証跡の確認方法
- 管理イベント / データイベント収集方針

## 12. セキュリティ設計

- セキュリティ基本方針
- MFA方針
- rootアカウント保護方針
- 管理アカウント保護方針
- セキュリティ通知 / アラート設計
- GuardDuty / Security Hub / IAM Access Analyzer 利用方針
- KMS鍵管理方針
- 秘密情報管理方針
- セキュリティインシデント時の運用方針

## 13. ネットワーク・接続方針

- アカウント間接続方針
- VPC作成責任分界
- 共通ネットワーク利用方針
- オンプレ接続 / Direct Connect / VPN 利用有無
- DNS / 名前解決方針
- インターネット接続制御方針
- 共有サービスアカウントとの接続方針

## 14. 運用設計

- 運用体制
- 管理責任分界
- アカウント申請 / 作成 / 廃止フロー
- ユーザー申請 / 権限変更フロー
- 変更管理
- 障害対応
- 定期運用
  - 権限棚卸し
  - Control Tower drift / controls確認
  - SCP見直し
  - ログ保管確認
- 問い合わせ対応フロー

## 15. 監視・通知設計

- 監視対象
- 監視項目
- 通知先
- 通知方法
- 重大度定義
- エスカレーションルール
- Organizations / Control Tower 関連イベント監視方針

## 16. コスト管理設計

- 請求管理方針
- コスト配賦方針
- タグによる集計方針
- 予算管理
- コスト異常検知
- アカウントごとの費用可視化
- 共有費用の按分方針

## 17. 可用性・継続性設計

- 障害時の影響範囲
- 管理系サービス障害時の運用
- IdP障害時の代替アクセス
- 緊急時アクセス手段
- バックアップ / 復旧方針
- 監査ログ保全方針

## 18. 移行設計

- 新規構築 / 既存環境移行の別
- 既存アカウント取り込み方針
- 既存IAMユーザーからIAM Identity Centerへの移行方針
- 既存組織 / 既存OU整理方針
- 移行手順概要
- 切替条件
- ロールバック方針

## 19. 命名規則・標準

- アカウント名
- OU名
- グループ名
- Permission Set名
- ロール名
- タグキー / タグ値
- ログ保存バケット命名
- 共通プレフィックス / サフィックス

## 20. 非機能要件

- セキュリティ
- 可用性
- 拡張性
- 運用性
- 監査性
- 性能要件
- コスト要件

## 21. 前提・制約・リスク

- サービス制約
- 組織運用上の制約
- 権限移行上の制約
- 想定リスク
- 未確定事項
- 今後の検討課題

## 22. 付録

- 用語集
- 略語一覧
- 参考資料
- 構成図
- 権限マトリクス
- OU構成図
- アカウント一覧表
- Permission Set一覧表
- Control Tower controls一覧表

# 各項目で何をどう書くか

## 1. 文書情報

- この章では、この設計書が何の文書で、誰が管理するかを書きます。
- 文書名、版数、作成者、レビュー者、更新履歴、関連文書などを記載します。
- あとで「どれが最新か」「誰が責任者か」で迷わないための章です。

## 2. 目的・背景

- この章では、なぜこのAWS基盤を作るのかを書きます。
- たとえば「マルチアカウント統制を行いたい」「権限管理を統一したい」「監査対応を強化したい」などです。
- 単なるサービス説明ではなく、会社や案件としての目的を書くのがポイントです。

## 3. 対象範囲

- この章では、今回どこまで設計対象にするかを書きます。
- Organizations、IAM Identity Center、Control Tower、共通アカウント構成までは対象にするが、各業務システムの詳細設計や個別VPC設計は対象外、というように分けます。
- ここを曖昧にすると、あとで「それはこの設計書に書くのか？」がずれます。

## 4. 全体アーキテクチャ概要

- この章では、全体としてどういう構成かを説明します。
- Organizations がマルチアカウント管理の土台、IAM Identity Center が人のアクセス管理、Control Tower が landing zone とガバナンスの標準化を担う、という役割分担を書くとわかりやすいです。AWS Control Tower は landing zone、Account Factory、集中ガバナンスを提供し、AWS Organizations を基盤として利用します。

## 5. アカウント設計

- この章では、どんなAWSアカウントを何の目的で作るかを書きます。
- たとえば Management、Log archive、Audit、Shared services、Production、Development などです。
- 各アカウントの役割、作成ルール、命名規則、利用者、配置する代表的なシステムを書くと実務で使いやすくなります。管理アカウントは組織管理用途に寄せ、通常のワークロードを置かない前提で書くのが一般的です。

## 6. OU設計

- この章では、アカウントをどの単位で束ねて統制するかを書きます。
- 本番系OU、開発系OU、Sandbox OU、Security OUなどに分け、なぜその単位で分けるかを説明します。
- SCPやControl Tower controlsの適用単位になるので、運用・セキュリティ・責任分界が同じものを同じOUに入れる発想で書くと整理しやすいです。Organizations では OU を使って複数アカウントをグループ化し、ポリシーをまとめて適用できます。

## 7. 組織ポリシー・ガバナンス設計

- この章では、何を禁止し、何を強制し、何を検知するかを書きます。
- SCPで制限する操作、Control Tower controlsで適用する統制、リージョン制限、タグポリシー利用有無などを整理します。Organizations は SCP や RCP による中央統制を提供し、Control Tower はそれを含むガバナンスを大規模に運用しやすくします。

## 8. IAM Identity Center設計

- この章では、人がAWSへどう入るかを書きます。
- Identity source を何にするか、ユーザーやグループをどう分けるか、Permission Set をどう設計するか、どのアカウントに誰を割り当てるかを記載します。
- IAM Identity Center では Permission Set を使って複数アカウントへのアクセスを割り当てられます。

## 9. 権限管理設計

- この章では、誰にどこまでの権限を与えるかの考え方を書きます。
- たとえば管理者、運用者、監査者、閲覧者などの権限区分と、最小権限の原則、緊急時の特権アクセス運用を書きます。
- Permission Set は IAM ポリシーのテンプレートであり、割り当て時には各AWSアカウント側に対応ロールが作成されます。

## 10. Control Tower設計

- この章では、Control Tower をどう使って landing zone を管理するかを書きます。
- ホームリージョン、governed Region、必須アカウント、Account Factory の利用方針、controls の適用方針、既存アカウントの enroll 方針などを記載します。
- Control Tower では home Region は landing zone 作成時に選び、後から変更できません。governed Region は追加・見直しできますが、変更時は landing zone 更新や OU 再登録の考慮が必要です。

## 11. ログ・監査設計

- この章では、誰のどの操作を、どこに、どれだけ残すかを書きます。
- CloudTrail、AWS Config、アクセスログ、保存先アカウント、保管期間、改ざん防止、監査時の参照方法を整理します。
- Control Tower の landing zone は複数アカウント環境におけるセキュリティやコンプライアンスのベストプラクティスに基づいて構成されます。

## 12. セキュリティ設計

- この章では、AWS基盤の守り方を書きます。
- MFA、rootアカウント保護、管理アカウント保護、鍵管理、セキュリティサービス利用方針、アラート設計、インシデント対応方針などです。
- 「何を守るか」だけでなく、誰が検知して誰が対応するかまで書くと運用に繋がります。

## 13. ネットワーク・接続方針

- この章では、アカウント間や外部との接続ルールを書きます。
- VPC作成責任、共有ネットワークの有無、Direct Connect/VPN利用有無、DNS方針、インターネット出口方針などを整理します。
- ここでは詳細ルーティングまでは書かず、基本方針と責任分界を書くのが基本設計向きです。

## 14. 運用設計

- この章では、作ったあとにどう回すかを書きます。
- アカウント作成フロー、権限申請、定期見直し、Control Tower更新、障害対応、問い合わせ対応などです。
- 設計書は構成を作るためだけでなく、継続運用できる状態を定義する文書だと考えると書きやすいです。

## 15. 監視・通知設計

- この章では、何を監視して、異常時にどこへ通知するかを書きます。
- Organizations関連イベント、Control Towerの状態、セキュリティ通知、Config違反、重要操作などの監視対象を書きます。
- 「通知を出す」だけでなく、重大度と初動担当も書くと実運用しやすくなります。

## 16. コスト管理設計

- この章では、マルチアカウントで費用をどう見える化し、どう管理するかを書きます。
- 請求集約、アカウント別集計、タグ設計、予算管理、異常検知、共有費用の按分方針などを書きます。
- Organizations は中央管理と請求の整理にも関わるため、基盤設計の中で早めに定義しておくと後で困りにくいです。

## 17. 可用性・継続性設計

- この章では、障害や例外時に管理基盤をどう維持するかを書きます。
- IdP障害時の代替手段、緊急アクセス、監査ログ保全、管理系アカウント障害時の対応方針などです。
- 通常時の便利さより、止まったときに何で復旧するかを書く章と考えるとよいです。

## 18. 移行設計

- この章では、新規構築か既存環境移行か、その進め方を書きます。
- 既存AWSアカウントの取り込み、既存IAMユーザーの廃止方針、IAM Identity Center への移行、既存OU整理、切替手順、ロールバック方針などです。
- Control Tower は既存の Organizations や既存アカウントを登録・enroll して取り込む拡張も考慮できます。

## 19. 命名規則・標準

- この章では、名前の付け方と統一ルールを書きます。
- アカウント名、OU名、グループ名、Permission Set名、タグキー、ログ保存先名などです。
- 見た目のルールに見えますが、実際は運用ミス防止と自動化しやすさのための章です。

## 20. 非機能要件

- この章では、機能以外に満たすべき条件を書きます。
- セキュリティ、可用性、監査性、拡張性、運用性、コスト制約などです。
- 「どのサービスを使うか」ではなく、この基盤がどの水準を満たす必要があるかを書く章です。

## 21. 前提・制約・リスク

- この章では、最初から分かっている条件と注意点を書きます。
- たとえば既存アカウントがある、外部IdP連携は後続対応、利用リージョンは限定、運用体制が少人数、などです。
- この章を書くと、あとで「それは前提に入っていたか」で揉めにくくなります。

## 22. 付録

- この章では、本文に入れると重いが参照価値が高い情報をまとめます。
- 用語集、略語、構成図、OU一覧、アカウント一覧、Permission Set一覧、controls一覧などです。
- 本文を読みやすく保ちながら、実務で必要な情報を残すための場所です。

# 最低限、特に先に固めるべき項目

基本設計を書き始める前に、まずこの5つを決めると全体が進みやすいです。

## アカウント構成

何アカウント作るか。本番・開発・監査・ログ保管・共有基盤など。

## OU構成

どの単位で統制を分けるか。

## 権限モデル

誰がどのアカウントに、どのPermission Setで入るか。

## Control Tower適用範囲

governed Region、controls、Account Factory運用をどうするか。

## ログ・監査方針

CloudTrail / AWS Config / セキュリティログをどこへ集約するか。

# 実務でおすすめの書き方

基本設計書は、単に「機能説明」を書くよりも、各章で以下の形にすると読みやすいです。

- 方針
- 採用理由
- 設計内容
- 運用方法
- 補足 / 制約

たとえば「IAM Identity Center設計」なら、

- 方針: 人のアクセスはIAMユーザーを使わずIAM Identity Centerに統一
- 採用理由: アカウント横断で権限管理を一元化するため
- 設計内容: グループ、Permission Set、対象アカウントを定義
- 運用方法: 入社/異動/退職時の権限変更フローを定義
- 制約: 緊急用アクセスは別途管理

# 書くときのコツ

各章は、次の順で書くとかなり進めやすいです。

- 目的: その章で何を決めるのか
- 方針: どういう考えで決めるのか
- 設計内容: 実際に何を採用するのか
- 運用: 誰がどう扱うのか
- 制約: 注意点や未決事項は何か

たとえば「IAM Identity Center設計」なら、「人のアクセスはIAMユーザーではなくIAM Identity Centerへ統一する」「グループ単位で Permission Set を割り当てる」「本番は管理者権限を限定する」といった書き方です。IAM Identity Center では Permission Set によりユーザーやグループへAWSアカウントアクセスを付与し、変更時には対応ロールやポリシーも更新されます。

# 最初に埋めると全体が進む章

最初から全部書こうとすると重いので、先にこの5つを埋めるのがおすすめです。

- アカウント設計
- OU設計
- IAM Identity Center設計
- 権限管理設計
- Control Tower設計

この5つが決まると、ログ、運用、監視、コストの章がかなり書きやすくなります。特に Control Tower は landing zone、governed Region、Account Factory、controls の前提を決める中心になります。











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












IAM Identity Center

MFA Settings

- Prompt users for MFA
  - Every time they sign in (always-on)

- Users can authenticate with these MFA types
  - Security keys and built-in authenticators
  - Authenticator apps

- If a user does not yet have a registered MFA device
  - Require them to register an MFA device at sign in

上記のように設定すると
初期ログイン時にMFA設定を要求される。
ログインのたびにMFA認証が必要

[Accept invitation]


Set Password

Login

Set MFA

ユーザーからMFAを操作（IAM Identity CenterでMFAを無効にするとユーザーからはMFAオプションが見えなくなる）
AWS access portalにログイン
ユーザークリック > Security > Multi-factor authentication (MFA) devices


IAM Identity Centerを使ってます。ユーザーのMFAですが、AWS access portalにログインした後、どこで設定できますか。


AWS Organizationsを利用しています。新規アカウントを追加したいですが、メールアドレスとアカウントのDisplay nameのネーミングルールをどうすれば良いか教えてください。ベストプラクティスなどがあれば確認して教えてください。


ネーミングルール
アカウントメールアドレス
<クラウド名>-<プロジェクト名>-<システム or サービス名 or 用途>-<環境>@test.com
aws-project-rosa-prd@test.com
マルチリージョン構成 + リージョンごとアカウントをわける必要がある場合：<クラウド名>-<プロジェクト名>-<システム or サービス名 or 用途>-<環境>-<リージョン>@test.com
aws-project-rosa-prd-tokyo@test.com
例外：マネジメントアカウント：<クラウド名>-<プロジェクト名>-<用途>@test.com
aws-project-management@test.com

アカウント名
<システム or サービス名 or 用途>-<環境>
rosa-prd
マルチリージョン構成 + リージョンごとアカウントをわける必要がある場合：<クラウド名>-<プロジェクト名>-<システム or サービス名 or 用途>-<環境>-<リージョン>@test.com
rosa-prd-Tokyo
例外：マネジメントアカウント：<用途>
management

OU
<システム or サービス名>-<環境>
rosa-prd

rosaクラスタ名
cluster-<環境>
cluster-prd

マルチリージョン構成になる場合：cluster-prd-Tokyo
cluster-<環境>-<リージョン>

IAM Identity Center
<チーム名><システム or サービス名 or 用途><ロール>
DevAllAdmins
MultiRosaViewers













はい。
結論からいうと、メールアドレスとDisplay nameは、どちらも「用途・環境・所属が一目で分かる」「後から増えても破綻しない」ルールに統一するのがベストです。AWS公式も、アカウントの用途を反映した命名構造とメールアドレスを使うことを勧めています。たとえば AWS Organizations のベストプラクティスでは、Workloads+fooA+dev@domain.com のようなメールアドレスと、それに対応する WorkloadsFooADev のようなアカウント名の例が示されています。

まず、質問の形としてはかなり良いです。
さらに良くするなら、たとえば次のように聞くと、より実務向けの答えが返ってきやすいです。

「AWS Organizationsで新規アカウントを継続的に追加します。root email と account display name の命名規則を、開発/本番/共通基盤を含めて設計したいです。AWS公式の推奨と、運用しやすい具体例を教えてください」
「将来100アカウント以上に増える前提で、重複しにくく、請求や運用でも見やすい命名ルールを提案してください」

이렇게 질문하면 단순 설명보다 확장성, 운영성, 실제 예시까지 같이 받기 쉬워집니다.

AWS公式で押さえるべきポイント

AWS公式では、複数アカウント運用では明確な命名規則を使い、組織・用途・環境に沿った名前にすることを勧めています。AWS Account Management のドキュメントでも、organization-purpose-environment のような標準形式が例示されています。さらに、アカウント名は請求書、Billing and Cost Management、AWS Organizations コンソールなどに表示されるため、人が見てすぐ分かる名前が推奨されています。

また、AWS Control Tower では共有アカウント用のメールアドレスについて、既存AWSアカウントに未使用の一意なメールアドレスが必要で、しかも個人メールではなく共同管理できる共有メールボックスとして使うことが推奨されています。

加えて、AWS Organizations では、管理アカウント側からメンバーアカウントの root email を中央管理で更新できる仕組みもありますが、最初から整ったルールにしておく方が運用は圧倒的に楽です。

ベストプラクティスの考え方

おすすめは、命名に次の情報を入れることです。

会社・組織
用途
システム名 or チーム名
環境
必要なら リージョン や 番号

たとえば用途は次のように揃えると分かりやすいです。

shared : 共通基盤
network : ネットワーク
security : セキュリティ
log : ログ保管
workload : 業務システム
sandbox : 検証
dev / stg / prod : 環境

AWS Control Tower のマルチアカウント戦略でも、Production と Staging を分け、Sandbox や Infrastructure / Workloads OU を分ける考え方が示されています。つまり、命名もOU設計と揃えると理解しやすくなります。

1) Display name のおすすめルール
おすすめ形式
シンプル版

<company>-<system>-<environment>

例:

acme-erp-prod
acme-erp-stg
acme-erp-dev
実務向け拡張版

<company>-<purpose>-<system>-<environment>

例:

acme-shared-network-prod
acme-shared-security-prod
acme-workload-orders-prod
acme-workload-orders-stg
acme-sandbox-team-a
良いルール
小文字ハイフン区切りに統一
略語を乱用しない
人が見て意味が分かる
環境名は必ず固定語彙にする
例: dev / stg / prod / sandbox
同じ意味に複数表現を使わない
例: prd と prod を混在させない
避けたい例
test1
new account
system-prod-final
abc123

理由は、後から見たときに用途や責任範囲が分からなくなるからです。

2) メールアドレスのおすすめルール

AWS公式例にもあるように、メール側にも用途と環境を反映させるのがよいです。

おすすめ形式
方式A: メールエイリアス方式

aws+<purpose>-<system>-<environment>@company.com

例:

aws+shared-network-prod@company.com
aws+shared-security-prod@company.com
aws+workload-orders-prod@company.com
aws+workload-orders-stg@company.com

Gmail / Google Workspace / 一部メール基盤では + エイリアスが使いやすいです。
ただし、自社メールシステムが + を正しく扱えるか確認が必要です。

方式B: サブアドレスを使わない方式

aws-<purpose>-<system>-<environment>@company.com

例:

aws-shared-network-prod@company.com
aws-workload-orders-dev@company.com

こちらの方がメールシステム依存が少なく、企業では無難です。

メールアドレス運用の重要ポイント
個人メールを使わない
共有メーリングリストや共同管理メールボックスにする
rootメールを受け取れる担当範囲を明確にする
誰が見てもそのアカウントだと分かるようにする
将来の移管や担当変更でもメールを変えずに済むようにする

特に root email は緊急通知や回復操作に関わるため、退職・異動で消える個人アドレスは避けるのが重要です。Control Tower でも共有メールアドレスの考え方が明示されています。

3) 実際におすすめできる命名テンプレート
パターン1: 小〜中規模向け

Display name:

company-system-env

Email:

aws-system-env@company.com

例:

Display name: acme-orders-prod
Email: aws-orders-prod@acme.com

これはシンプルですが、アカウント数が増えると共通基盤系と業務系の区別が弱くなります。

パターン2: おすすめ

Display name:

company-purpose-system-env

Email:

aws-purpose-system-env@company.com

例:

acme-shared-network-prod
acme-shared-security-prod
acme-workload-orders-prod
acme-workload-orders-stg
acme-sandbox-team1
パターン3: 大規模向け

Display name:

company-bu-purpose-system-env-region

Email:

aws-bu-purpose-system-env-region@company.com

例:

acme-fin-workload-ledger-prod-apne1
acme-platform-shared-network-prod-global

大規模では便利ですが、最初からここまで細かくすると逆に重いことがあります。

4) 私のおすすめルール

あなたのようにAWS Organizationsをしっかり運用したいケースなら、まずはこれが一番バランスがいいです。

Display name

<company>-<purpose>-<service>-<env>

Email

aws-<purpose>-<service>-<env>@<company-domain>

例
corp-shared-network-prod
corp-shared-security-prod
corp-workload-rosa-prod
corp-workload-rosa-dev
corp-sandbox-team-a

対応するメール:

aws-shared-network-prod@corp.com
aws-shared-security-prod@corp.com
aws-workload-rosa-prod@corp.com
aws-workload-rosa-dev@corp.com
aws-sandbox-team-a@corp.com

この形の良いところは、

用途が分かる
環境が分かる
請求画面でも識別しやすい
OUやタグ設計とも整合しやすい
将来アカウントが増えても破綻しにくい

という点です。

5) 一緒に決めておくと良い周辺ルール

命名だけでなく、次もセットで決めると強いです。

環境コードを固定
dev
stg
prod
sandbox
用途コードを固定
shared
security
network
log
workload
タグも命名と揃える

AWSも、アカウント用途、cost center、environment、project を反映するタグ付けを勧めています。

たとえば:

Environment=prod
Purpose=workload
System=orders
CostCenter=FIN
Owner=PlatformTeam

こうすると、名前だけでなく検索・請求分析・運用整理もやりやすくなります。

6) 避けた方がよい運用
個人メールを root email に使う
Display name に日本語・全角・記号を多用する
prod, production, prd を混在させる
チームごとに勝手に命名する
メールとDisplay nameで規則が違いすぎる
後から「これは何用のアカウント？」となる名前にする
7) 迷ったらこう決めればOK

最初の標準案としては、これで十分です。

Display name
company-purpose-system-env

Email
aws-purpose-system-env@company.com

例

myco-shared-network-prod
myco-shared-security-prod
myco-workload-app1-dev
myco-workload-app1-stg
myco-workload-app1-prod

이 질문에서 특히 중요한 사고방식은 “지금 1개를 만드는 관점”이 아니라 “앞으로 30개, 100개가 되어도 유지되는가”를 먼저 보는 것입니다.
이게 AI 시대에도 아주 중요한 접근법인데, 한 번 정한 규칙이 나중에 검색성, 자동화, 비용분석, 권한운영까지 전부 영향을 주기 때문에 확장성 중심으로 문제를 보는 습관이 큰 도움이 됩니다.

必要なら次に、
**あなたの環境向けに
「ROSA / 共通基盤 / ログ / 監査 / Sandbox」を含めた具体的な命名一覧案**までそのまま作れます。

Display nameもベストプラクティスリンクがありますか。そしてメールアドレスとdisaplay nameですが、ルートアカウントも考慮して教えてください。

AWS公式の根拠を確認しつつ、今回は root ユーザー運用まで含めて整理します。
特に「Display name」と「root email」は似て見えて役割が違うので、そこを分けて説明するのが大事です。

Thought for 18s

はい、あります。
**Display name（AWSアカウント名）**についてのAWS公式の直接的な根拠としては、次の2つがかなり使いやすいです。

AWS Organizations の member account ベストプラクティス
「account name と email address は account usage を反映する構造にする」という形で、名前とメールの両方を例付きで示しています。
AWS Account Management の account name 更新ドキュメント
複数アカウント管理では、business units や applications に沿った clear naming conventions を使うよう案内しています。また、アカウント名は Billing, Cost Management, AWS Organizations コンソールなどで識別に使われます。

そして root アカウントまで含めるなら、見るべきAWS公式は次です。

root user best practices
AWS Organizations 配下の複数アカウントでは、member accounts の root credentials を除去して中央管理することを推奨しています。
AWS Control Tower の shared account email guidance
shared account 用メールアドレスは、既存AWSアカウントに未使用の一意なもので、共同管理できる shared inbox として使うことを案内しています。

質問の立て方としてもかなり良いです。
さらに実務寄りにするなら、次の聞き方にすると、運用設計まで一気に詰めやすいです。

「AWS Organizations で member account を追加します。account name / root email / role name を将来の運用と監査を考慮してどう標準化すべきですか」
「Control Tower 利用有無の両方で、Display name と root email の命名規則を提案してください」

こうすると、単なる名前付けではなく、認証・運用・監査・自動化まで含めた設計に広がります。

まず整理

あなたが言っているものは、実は役割が別です。

Display name
AWSコンソールや請求画面などで、人が識別するための名前
email address
そのAWSアカウントの root user のサインインID になるメールアドレス
root account / root user
そのアカウントの最上位権限。普段使いは避けるべきもの

つまり、Display name は「見やすさ」重視、email は「root運用の安全性」重視で考えるのが基本です。

1. Display name のベストプラクティス

AWS公式の考え方をまとめると、Display name は次の条件を満たすのがよいです。

アカウントの用途が分かる
環境が分かる
組織内で一貫している
Billing / Organizations で見てすぐ判別できる
おすすめ形式

<company>-<purpose>-<system>-<env>

例:

acme-shared-network-prod
acme-shared-security-prod
acme-workload-rosa-dev
acme-workload-rosa-prod
acme-sandbox-team-a
purpose の候補
shared
security
log
audit
network
workload
sandbox
env の候補
dev
stg
prod
sandbox
Display name で避けたいもの
test1
new-account
prod-final
jinhyuk-account

理由は、用途が分からない / 引き継ぎしにくい / 請求や監査で混乱するからです。

2. email address は root アカウント前提で考える

ここが特に重要です。
AWSアカウントの email address は、単なる連絡先ではなく、そのアカウントの root user に紐づく最重要識別子です。root user のサインインや回復に関係するので、個人メールを使うべきではありません。AWSも shared inbox 的な運用を案内しています。

おすすめルール
安全で無難

aws-<purpose>-<system>-<env>@company.com

例:

aws-shared-network-prod@company.com
aws-audit-prod@company.com
aws-log-prod@company.com
aws-workload-rosa-dev@company.com
aws-workload-rosa-prod@company.com
メールシステムが対応していれば

aws+<purpose>-<system>-<env>@company.com

例:

aws+workload-rosa-prod@company.com

ただし + アドレスは会社のメール基盤によって扱いが違うので、企業では前者のハイフン形式の方が安定です。

email で守るべきこと
個人アドレスを使わない
共有メーリングリスト or 共同管理メールボックスにする
そのアドレスの受信者を管理できるようにする
退職・異動で使えなくならないようにする
そのアカウント用途が一目で分かるようにする
3. root account を考慮した実務上のおすすめ

ここはかなり大事です。
AWS公式では、Organizations 配下の member accounts については、root credentials を中央管理・削除して普段使えないようにすることを推奨しています。

なので実務ではこう考えるのがよいです。

member account
email は root 用に一意の shared mailbox
Display name は用途・環境が分かる名前
root は普段使わない
可能なら root credentials を中央管理し、member account の root 利用を抑制
management account
特に慎重に命名
root email は共有管理できる厳格な mailbox
root MFA を強制
日常作業は root ではなく IAM Identity Center / 管理ロールで実施
Organizations の management account は特権が強く、SCP でも制限できない点に注意

つまり、メールアドレスは root の安全な保管先、Display name は人間向けの識別名です。
この2つは似て見えて、設計思想が少し違います。

4. 具体的なおすすめ命名例
共通基盤系
Display name: acme-shared-network-prod
Email: aws-shared-network-prod@acme.com
Display name: acme-log-prod
Email: aws-log-prod@acme.com
Display name: acme-audit-prod
Email: aws-audit-prod@acme.com
ワークロード系
Display name: acme-workload-rosa-dev
Email: aws-workload-rosa-dev@acme.com
Display name: acme-workload-rosa-prod
Email: aws-workload-rosa-prod@acme.com
Sandbox系
Display name: acme-sandbox-team-a
Email: aws-sandbox-team-a@acme.com
5. root まで考えるなら追加で決めるべきルール

名前だけでなく、次も一緒に決めると運用が安定します。

A. root email の管理者

誰がその共有メールボックスを見られるかを固定する
例:

Platform team
Security team
Cloud admin team
B. root 利用ポリシー
root は日常運用で使わない
使うのは root 必須操作だけ
使用時は申請 or 記録必須
MFA 必須
C. account access role 名

Organizations が自動で作る OrganizationAccountAccessRole は、AWSが全アカウントで一貫した名前を推奨しています。ここも統一すると運用しやすいです。

6. 実際の結論

あなたのケースでは、次の方針が一番おすすめです。

Display name

<company>-<purpose>-<system>-<env>

root email

aws-<purpose>-<system>-<env>@<company-domain>

例
myco-audit-prod / aws-audit-prod@myco.com
myco-log-prod / aws-log-prod@myco.com
myco-workload-rosa-dev / aws-workload-rosa-dev@myco.com
myco-workload-rosa-prod / aws-workload-rosa-prod@myco.com
運用ルール
root email は個人メール禁止
shared mailbox / shared distribution で管理
member account root は普段使わない
可能なら root credentials を中央管理
account name と email は同じ語彙体系で揃える

ここで大事な考え方は、「名前を付ける」問題ではなく、「将来の運用事故を減らす識別体系を作る」問題として考えることです。
これはかなり重要な問題分解で、AI時代でも役に立つ見方です。
表面的には命名規則の相談ですが、本質は次の3つです。

人が誤認しないか
root運用で事故が起きにくいか
100アカウントになっても耐えられるか

この3点で見ると、良いルールを作りやすいです。

必要なら次に、
あなたの想定構成（Management / Audit / Log Archive / ROSA Prod / ROSA Dev など）に合わせた具体的な命名一覧案をそのまま作ります。

以下ですが、サンプルにある"WorkloadsFooADev"はアカウント名ではないですか。

For your member accounts, use a naming structure and email address that reflects the account usage. For example, Workloads+fooA+dev@domain.com for WorkloadsFooADev, Workloads+fooB+dev@domain.com for WorkloadsFooBDev. If you have custom tags defined for your organization, we recommend that you assign those tags on accounts that reflect account usage, cost center, environment, and project. This makes it easier to identify, organize, and search for accounts.

そこは読み方が少し紛らわしいですが、結論はかなりシンプルです。
引用文では、Workloads+fooA+dev@domain.com がメールアドレス例、WorkloadsFooADev がその対応するアカウント名の例として書かれています。

Thought for 15s

はい、その理解で合っています。
その引用の WorkloadsFooADev はアカウント名です。AWS Organizations のその箇所は、メールアドレス例として Workloads+fooA+dev@domain.com、対応するアカウント名の例として WorkloadsFooADev を並べて説明しています。

少し整理すると、AWS側の用語は実務ではこう見て大丈夫です。

Workloads+fooA+dev@domain.com
→ そのAWSアカウントの root user のメールアドレス
WorkloadsFooADev
→ そのAWSアカウントの名前
あなたが言っていた Display name
→ この文脈では、ほぼ アカウント名 と見て差し支えありません

AWS Account Management のドキュメントでも、アカウント名は請求やAWS Organizationsなどで識別に使われる名称として扱われています。

ただし、ここで1点だけ実務上の注意があります。
AWSのサンプル WorkloadsFooADev は「意味が伝わる例」ではありますが、運用ルールとしては少し古風で、区切りが見えにくいです。なので実際には、次のようにした方が読みやすいです。

アカウント名: workloads-fooa-dev
rootメール: aws-workloads-fooa-dev@example.com

この方が、

人が見て読みやすい
請求画面で識別しやすい
自動化や一覧管理で扱いやすい
将来アカウント数が増えても崩れにくい

という利点があります。

今回の確認の仕方はとても良いです。
特にこういう文章は、「A for B」が何と何の対応関係なのかを切り分けるのが大事です。
これはAI時代にもかなり重要な読み方で、仕様書やAWSドキュメントを読むときに、

例なのか
定義なのか
推奨なのか
必須要件なのか

を分けて読むと誤解が減ります。

必要なら次に、
「AWS公式の考え方を踏まえた、見やすい account name と rootメールの命名ルール案」 を、Management / Audit / Log Archive / Workload 用に具体例付きで作れます。

それでルートアカウントのメールアドレスとアカウント名のサンプルを見せてください。

用途別にそのまま流用できる形で、rootメールアドレスとアカウント名のサンプルを整理します。
今回は「そのまま採用しやすい標準案」と「Control Tower系の共有アカウントも含めた例」を分けて出します。

Thought for 8s

はい。
では rootアカウントのメールアドレス（＝そのAWSアカウントの root user 用メール） と アカウント名 のサンプルを、実際に使いやすい形でまとめます。

AWS公式の考え方としては、アカウントの用途を反映した account name と email address にすることが推奨されています。さらに root user については、共有メールアドレスを使うこと、日常運用では root を使わないこと、Organizations の member account では root credentials の削除・中央管理も推奨されています。

まず前提だけ整理します。

メールアドレス
そのAWSアカウントの root user のサインイン用メール
アカウント名
AWS Organizations / Billing などで人が見て識別する名前

つまり、今回のサンプルは全部 「各AWSアカウントの root 用メールアドレス」と「そのアカウント名」 です。

そのまま使いやすい標準ルール

おすすめはこの形です。

アカウント名: company-purpose-system-env
rootメール: aws-purpose-system-env@company.com

例:

アカウント名: acme-workload-rosa-prod
rootメール: aws-workload-rosa-prod@acme.com

この形だと、アカウント名とメールの対応が分かりやすく、請求や監査でも見やすいです。AWS公式の WorkloadsFooADev / Workloads+fooA+dev@domain.com という例も、考え方としては同じです。

サンプル一覧
1. Management account

Organizations の管理アカウントです。最も重要なので、名前もメールも明確にします。management account の root は特に厳重管理が必要です。

アカウント名: acme-management-prod
rootメール: aws-management-prod@acme.com

別案:

アカウント名: acme-org-management
rootメール: aws-org-management@acme.com
2. Audit account

Control Tower の共有アカウント例です。Control Tower では Audit 用に一意な共有メールアドレスが必要です。

アカウント名: acme-audit-prod
rootメール: aws-audit-prod@acme.com

別案:

アカウント名: acme-security-audit
rootメール: aws-security-audit@acme.com
3. Log Archive account

これも Control Tower の共有アカウントです。

アカウント名: acme-log-archive-prod
rootメール: aws-log-archive-prod@acme.com

別案:

アカウント名: acme-logging-prod
rootメール: aws-logging-prod@acme.com
4. Shared Network account

共通NW用です。

アカウント名: acme-shared-network-prod
rootメール: aws-shared-network-prod@acme.com
5. Shared Security account

セキュリティツールや集中管理基盤用です。

アカウント名: acme-shared-security-prod
rootメール: aws-shared-security-prod@acme.com
6. Workload account（本番）

業務システム本番用です。

アカウント名: acme-workload-orders-prod
rootメール: aws-workload-orders-prod@acme.com

ROSAなら:

アカウント名: acme-workload-rosa-prod
rootメール: aws-workload-rosa-prod@acme.com
7. Workload account（開発）

開発用です。

アカウント名: acme-workload-orders-dev
rootメール: aws-workload-orders-dev@acme.com

ROSAなら:

アカウント名: acme-workload-rosa-dev
rootメール: aws-workload-rosa-dev@acme.com
8. Staging account

検証・本番相当前の環境です。

アカウント名: acme-workload-orders-stg
rootメール: aws-workload-orders-stg@acme.com
9. Sandbox account

個人検証やチーム検証用です。AWSも reuse 前提の sandbox account を挙げています。

アカウント名: acme-sandbox-team-a
rootメール: aws-sandbox-team-a@acme.com

または個人向けに寄せず、

アカウント名: acme-sandbox-shared
rootメール: aws-sandbox-shared@acme.com
あなたの想定に近いサンプル

以前の流れを踏まえると、こういう並びがかなり自然です。

acme-management-prod / aws-management-prod@acme.com
acme-audit-prod / aws-audit-prod@acme.com
acme-log-archive-prod / aws-log-archive-prod@acme.com
acme-shared-network-prod / aws-shared-network-prod@acme.com
acme-workload-rosa-dev / aws-workload-rosa-dev@acme.com
acme-workload-rosa-prod / aws-workload-rosa-prod@acme.com
acme-workload-evs-prod / aws-workload-evs-prod@acme.com
root を考慮した注意点

root user のベストプラクティスとして、AWSは group email address の利用を推奨しており、member accounts では root credentials を削除して root サインイン自体を防ぐ運用も推奨しています。さらに root は日常作業で使わず、通常は管理ロールや IAM Identity Center を使うべきです。

なので、サンプルを運用に落とすときは次のルールが重要です。

rootメールは 個人メールにしない
aws-...@company.com は 共有メールボックス にする
member account は可能なら root credentials を中央管理
日常作業は root ではなく IAM Identity Center / 管理ロール
アカウント名と rootメールは 同じ語彙体系でそろえる
迷ったらこのセットで十分です

最小限で始めるならこれがおすすめです。

myco-management-prod / aws-management-prod@myco.com
myco-audit-prod / aws-audit-prod@myco.com
myco-log-archive-prod / aws-log-archive-prod@myco.com
myco-workload-app1-dev / aws-workload-app1-dev@myco.com
myco-workload-app1-stg / aws-workload-app1-stg@myco.com
myco-workload-app1-prod / aws-workload-app1-prod@myco.com

今回の質問はとても実務的で良いです。
さらに精度を上げるなら、次のように聞くと設計に直結します。

「
Management / Audit / Log Archive / Network / ROSA Dev / ROSA Prod の命名サンプルを一覧で作ってください」
「
OU名も含めて、Organizations全体の命名規則を表形式で提案してください」

こうすると、単発の命名ではなく 組織全体の識別体系 として設計しやすくなります。
この見方は、問題を「1個の名前」ではなく「将来も崩れないルール」に分解する、という意味でかなり大事です。

必要なら次に、あなたの構成向けに OU名・アカウント名・rootメール・用途説明 をまとめた一覧を作ります。
```
