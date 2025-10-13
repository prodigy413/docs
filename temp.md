~~~
0_summary
# SCCWP (IBM Cloud Security and Compliance Center Workload Protection)

概要/特徴は以下リンクから<br>
https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-about
<br>
IBM Cloud上で動作する「セキュリティとコンプライアンス管理の自動化ツール」です。  
金融機関向けフレームワーク（FS Cloud Framework）、DORA、CIS、PCIなど、業界標準ルールに基づいて  
クラウド環境を自動チェックし、違反があれば修正を支援します。
---

## 🌐 主な特徴（Postureモジュール）

### 1. 統合ビューでの管理
IBM Cloudだけでなく、他クラウド（AWS, Azureなど）やオンプレ環境も含めて  
セキュリティとコンプライアンスを一元管理できます。  

**対象:** 管理サービス、仮想マシン、ホスト、コンテナ、Kubernetes/OpenShiftクラスタなど。
---

### 2. 豊富な標準フレームワーク対応
以下のような業界基準テンプレートがすでに用意されています：

- 金融サービス（Financial Services）  
- PCI（クレジットカード業界標準）  
- DORA（欧州のデジタル運用レジリエンス法）  
- CIS、NIST など  

👉 これにより、法律や業界規制を簡単に満たすことができます。
---

### 3. 全クラウド資産のインベントリ管理
クラウドやオンプレの**すべてのリソース（VM、ホスト、K8sリソース、ID、権限など）**を自動的に一覧化。  
セキュリティ状況を「どこで何が起きているか」すぐに把握できます。
---

### 4. リスク受容（Risk Acceptance）機能
検出された違反のうち「一時的に許容するリスク」を登録できます。

- 理由や有効期限を設定可能  
- 特定リソースだけでなく全体的に承認も可能  
---

### 5. 修正ガイドと改善支援
失敗したチェック項目には**具体的な修正手順**が提示されます。  
→ チームがすぐに対応できるようサポートします。
---

### 6. カスタムポリシー作成
独自のポリシー・コントロール・パラメータを作成可能。  
→ 自社固有の基準にも柔軟に対応できます。
---

### 7. エンタープライズ統合
すべてのWorkload Protectionアカウントをシームレスに統合。  
→ 大規模な組織でも統一されたガバナンスを実現します。

### Region

- Supported regions for Workload Protection<br>
https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-regions

| Geography      | Region                   | EU-Supported | HA Status |   |
|----------------|--------------------------|---------------|------------|---|
| Asia Pacific   | Sydney (au-syd)          | N/A           | MZR        |   |
| Asia Pacific   | Osaka (jp-osa)           | N/A           | N/A        | OK |
| Asia Pacific   | Tokyo (jp-tok)           | N/A           | MZR        | OK |
| Europe         | Frankfurt (eu-de) (*)    | YES           | MZR        |   |
| Europe         | London (eu-gb)           | NO            | MZR        |   |
| North America  | Dallas (us-south)        | N/A           | MZR        |   |
| North America  | Washington (us-east)     | N/A           | MZR        |   |
| North America  | Toronto (ca-tor)         | N/A           | MZR        |   |
| South America  | Sao Paulo (br-sao)       | N/A           | MZR        |   |

### Pricing

https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-pricing

### Release notes

- Release notes for IBM Cloud Security and Compliance Center Workload Protection<br>
https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-release-notes
- Sysdig Release Notes<br>
https://docs.sysdig.com/en/release-notes/

### Available pre-defined policies for IBM Cloud CSPM in Workload Protection

https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-about&interface=ui#about-available-policies

### List of Services Supported by Workload Protection

https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-about&interface=ui#about-available-services








1_install.md

- Controlling access through IAM<br>
https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-iam
- Provisioning an instance
  - UI<br>https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-provision&interface=ui
  - CLI<br>https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-provision&interface=cli
  - Pricing / Paln<br>
  https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-pricing
- Managing access keys<br>https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-access_key&interface=ui
- Managing the Workload Protection agent in Red Hat OpenShift by using a HELM chart<br>
https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-agent-deploy-openshift-helm






2_configuration.md

- Zone
  - By default, Workload Protection creates a scope for all of your connected IBM Cloud services, clusters and workloads in a Zone called Entire Infrastructure.
  - [Managing zones](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-zones)
  - [Linking a policy to a zone](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-link-policy-to-zone)
- Policy
  - [Managing Posture Policies](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-policies&interface=ui)
  - [Creating a custom policy](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-policy-create)
  - [Creating a custom policy from a template](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-policy-create-template)
- Posture Controls
  - [Posture Controls](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-controls)
- Requirements
  - Managing requirements and requirement groups
---
- [Reviewing posture results and downloading reports](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-cspm-best-practices&interface=ui#cspm-best-practices-review-reports)
- [Reviewing all connected resources in Inventory](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-cspm-best-practices&interface=ui#cspm-best-practices-review-resources)
---
- CSPM
  - [Implementing CSPM (Cloud Security Posture Management) for IBM Cloud](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-cspm-implement&interface=ui)
  - [Getting started with App Configuration](https://cloud.ibm.com/docs/app-configuration?topic=app-configuration-getting-started)
    - IBM Cloud App Configurationは、Web・モバイルアプリやマイクロサービスなどの分散環境向けに機能や設定を集中管理できるサービスです。
    - 開発者は App Configuration SDK・ダッシュボード・管理API を利用して、フィーチャーフラグ（機能のON/OFF切り替え）や設定プロパティを定義・管理できます。
    - これらはコレクションに整理され、特定のユーザーセグメントにターゲティングすることも可能です。
    - アプリを再起動せずにクラウド上から機能を動的に有効化／無効化でき、分散アプリの設定を一元的に管理できます。
    - さらに、構成データの集約機能を有効または無効にすることができ、ガバナンスやコンプライアンス対応に役立つ最新のIBM Cloudリソース設定情報を一か所で確認できます。
    - [Managing service access](https://cloud.ibm.com/docs/app-configuration?topic=app-configuration-ac-service-access-management)
  - [Creating trusted profiles](https://cloud.ibm.com/docs/account?topic=account-create-trusted-profile&interface=ui#tp-roles-reqs)
- Auditing events
  - https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-at_events&interface=ui
  - [Getting started with IBM Cloud Activity Tracker Event Routing](https://cloud.ibm.com/docs/atracker?topic=atracker-getting-started)
- [Evaluate and remediate](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-evaluate-remediate)
- [Reports](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-compliance-reports)
- [High availability and disaster recovery](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-ha-dr&interface=ui)
- [Working with notification channels](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-notifications&interface=ui)




3_terminology.md

- posture policy
  - In Workload Protection, posture policies are collections of controls that you use to evaluate your compliance. You can use the predefined policies or create custom ones.
  - [Managing posture policies](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-cspm-best-practices&interface=ui#cspm-best-practices-manage-policies)
- Posture Controls
  - A control describes a rule, for example `/etc/docker/certs.d/*/* owned by root:root`, the code that is run to evaluate it, and a remediation playbook to fix the violation that might be detected.
  - https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-posture-controls
- IBM Cloud Framework for Financial Services
  - https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-financial-services&interface=ui#version-20
---
- Control（コントロール）<br>
セキュリティやプライバシー要件を満たすための技術的/管理的/物理的な対策項目。評価は規則（Rule）で自動化され、脆弱性やミスコンフィグを検出します。
- Requirement（リクワイアメント）<br>
ポリシーの中で「何を満たすべきか」をまとめる要件単位。1つ以上のControlで構成します。ダッシュボード上では「要件が何個Pass/Failか」を集計します。
- Policy（ポリシー）<br>
要件（Requirement）群を束ねた最上位の評価単位。カスタム作成でき、公開（Publish）すると環境に対してコンプライアンス評価に使われます。
- Requirement Group はポリシー内だけに属する（他ポリシーと共有しない）構造化用コンテナ。Requirement もポリシー横断では共有されません。必要なら別ポリシー側で新たにRequirementを作り、Controlをリンクし直します。
- RequirementにControlをリンクしていくのが実装手順（Severity・Type・Target等でフィルタして選定）。
~~~
Policy
 └─ Requirement Group（任意の階層化に使う入れ物）
     └─ Requirement（要件）
         └─ Control（実チェック項目、Ruleで評価）
~~~




4_terraform.md

- Sysdig Provider<br>
https://registry.terraform.io/providers/sysdiglabs/sysdig/latest/docs


~~~
