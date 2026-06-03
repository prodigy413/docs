```
# AWS Organizations マルチアカウント環境におけるユーザー管理方式

## 前提

- VMware/ROKS移行ではAWS Organizationsを利用してマルチアカウント構成を採用している。
- 複数のAWSアカウントを利用するため、ユーザー管理および各アカウントへの権限付与をどの方式で行うかを整理する必要がある。

## ユーザー管理方式の検討

- AWSアカウントへのユーザー管理方式としては、主にIAMユーザーとIAM Identity Centerがある。
- IAMユーザーはAWSアカウントごとに個別作成・管理が必要になるため、AWS Organizationsによるマルチアカウント構成では運用負荷が高い。
- そのため、XXプロジェクトでは複数アカウントにまたがるユーザーと権限を一元管理できる**IAM Identity Center**を利用する。

## Identity Source の検討

- IAM Identity Center では、ユーザー・グループ情報を管理する Identity Source を選択する必要がある。
- 主な選択肢は以下のとおり。

| Identity Source | 概要 |
|---|---|
| Identity Center Directory | IAM Identity Center 内でユーザー・グループを作成・管理する |
| Active Directory | AWS Managed Microsoft AD または AD Connector などを利用してADと連携する |
| External Identity Provider | Microsoft Entra ID、Okta などの外部IdPと連携する |

## Identity Source の制約

- IAM Identity Center で利用できる Identity Source は1つのみである。
- 例えば、Identity Source をActive Directoryなどにした場合、別会社のユーザーをIdentity Center Directory側に個別追加して併用する構成は取れない。

## Identity Center Directory の採用

- XXプロジェクトでは、AWS環境に複数会社のユーザーを追加する必要がある。
- 特定の会社のActive Directoryや外部IdPのみを前提にすると、他社ユーザーを柔軟に追加・管理できない可能性がある。
- そのため、Identity Source として **Identity Center Directory** を採用する。
- Identity Center Directory を利用することで、組織・会社を問わずIAM Identity Center 内でユーザー・グループを作成し、AWSアカウントへのアクセス権限を付与できる。

## Identity Center Directory の制約

- Identity Center Directory では、IAM Identity Center 側で定義されたパスワード要件が適用される。
- IAMユーザーのアカウントパスワードポリシーのように、プロジェクト独自のパスワードポリシーを任意にカスタマイズすることはできない。
- そのため、パスワードポリシーを厳密に独自管理したい場合は、Active Directory または外部IdPの利用を検討する必要がある。

## Identity Center Directory のデフォルトパスワード要件

Identity Center Directory のユーザーには、以下のパスワード要件が適用される。

| 項目 | 要件 |
|---|---|
| 文字数 | 8文字以上、64文字以下 |
| 文字種 | 小文字、大文字、数字、記号をそれぞれ1文字以上含める |
| 大文字・小文字 | 区別される |
| パスワード再利用 | 直近3つのパスワードは再利用不可 |
| 漏えい済みパスワード | 第三者の漏えいデータセットで公開されているパスワードは使用不可 |
```

```
# ROSAアカウント VPCグランドデザイン

## 1. 設計前提

| 項目 | 内容 |
|---|---|
| 対象AWSアカウント | rosa OU配下の rosa アカウント |
| 用途 | AWS ROSA HCPクラスタ用VPC |
| 接続構成 | rosa VPC → Transit Gateway → Infrastructureアカウント → Direct Connect → オンプレミス |
| Transit Gateway配置 | Infrastructureアカウント |
| ROSA配置 | rosaアカウント |
| VPC方針 | ROSA HCP専用VPCとして構成 |
| クラスタ方式 | Multi-AZ構成を標準 |
| 外部公開 | 原則Private Clusterを推奨。必要に応じてPublic Clusterを選択 |
| 管理方針 | rosaアカウント内のVPCはROSA専用とし、他用途と混在させない |

AWSのマルチVPC設計では、Transit GatewayをハブとしてVPCやオンプレミスを接続するHub-and-Spoke構成が一般的です。Transit Gatewayは、複数VPCおよびオンプレミスネットワークとの接続を集約する中心的な構成要素として利用します。

---

## 2. 基本方針

ROSA HCP用VPCは、**ROSAクラスタ専用VPC** として設計します。

| 方針 | 理由 |
|---|---|
| 1 VPC = 1 ROSAクラスタを基本とする | クラスタごとにVPC/Subnet設計を分離し、ネットワーク・セキュリティ・運用管理を明確化するため |
| Multi-AZを標準とする | 可用性を高めるため。ROSA HCPのMulti-AZ構成では複数AZを利用する |
| Private Subnet中心で構成する | Worker Nodeや内部Load Balancerをインターネットに直接公開しないため |
| Transit Gateway接続用SubnetをROSA Worker Subnetと分離する | TGW Attachmentの用途を明確にし、ルーティングとセキュリティ境界を分離するため |
| Public Subnetはクラスタ方式により判断する | Private Clusterでは原則不要。Public ClusterではNAT GatewayやPublic Load Balancer用に必要 |

---

## 3. 推奨構成パターン

ROSA HCPでは、以下2パターンを明確に分けて考えます。

---

## 3.1 パターンA：Private Cluster 推奨構成

本設計では、**Private Cluster構成を標準推奨** とします。

```text
On-Premises
    |
Direct Connect
    |
Infrastructure Account
    |
Transit Gateway
    |
TGW Attachment Subnet
    |
ROSA VPC in rosa Account
    |
Private Subnets
    |
ROSA HCP Worker Nodes / Internal Load Balancer
```

### 特徴

| 項目 | 内容 |
|---|---|
| Public Subnet | 原則作成しない |
| Internet Gateway | 原則作成しない |
| NAT Gateway | 原則作成しない |
| 外部接続 | Transit Gateway経由でオンプレミスまたは共通出口へ接続 |
| API / Ingress | Private Endpoint / Internal Load Balancer中心 |
| セキュリティ | インターネットから直接到達できない構成 |

Private ClusterではPublic Subnetは必須ではありません。ただし、クラスタ作成、アップグレード、Operator関連通信、イメージ取得などで外部ネットワークへの到達性が必要になる場合があります。

そのためPrivate Clusterの場合でも、以下のいずれかの出口設計が必要です。

| 出口方式 | 内容 |
|---|---|
| TGW経由でオンプレミスProxyへ出る | 企業ネットワーク側のProxy / Firewall / NATを利用 |
| TGW経由で共通Egress VPCへ出る | InfrastructureアカウントにEgress VPCを作る場合 |
| VPC Endpoint中心に閉域化する | S3などAWSサービス向け通信をPrivateLink / Gateway Endpointで処理 |
| Zero Egress構成を検討する | 外部インターネット通信を極小化する高度な構成 |

---

## 3.2 パターンB：Public Cluster構成

ROSAのアプリケーションをインターネット公開する、またはクラスタ側から直接インターネットへ出る構成を単純化したい場合は、Public Cluster構成を選択します。

```text
Internet
   |
Internet Gateway
   |
Public Subnets
   |
NAT Gateway
   |
Private Subnets
   |
ROSA HCP Worker Nodes
```

### 特徴

| 項目 | 内容 |
|---|---|
| Public Subnet | 必要 |
| Internet Gateway | 必要 |
| NAT Gateway | 必要 |
| Private Subnet | Worker Node用に必要 |
| 外部公開 | Public Load Balancer利用可能 |
| セキュリティ | Public入口の制御が重要 |

---

# 4. 推奨VPC設計

## 4.1 VPC CIDR設計

サンプルとして、ROSA HCP専用VPCには以下を割り当てます。

```text
VPC CIDR / Machine CIDR: 10.40.0.0/16
```

ROSAでは、VPC CIDRはMachine CIDRと一致させる設計が基本です。また、Machine CIDRはクラスタ作成後に変更できないため、最初の設計で十分に余裕を持たせる必要があります。

### CIDR設計方針

| CIDR種別 | サンプル | 用途 |
|---|---:|---|
| Machine CIDR / VPC CIDR | `10.40.0.0/16` | VPC全体、EC2 Worker Node、AWS Subnet用 |
| Pod CIDR | `10.128.0.0/14` | OpenShift Pod用 |
| Service CIDR | `172.30.0.0/16` | Kubernetes Service用 |
| Host Prefix | `/23` | Nodeごとに割り当てるPod IP範囲 |

### 注意点

Machine CIDR、Pod CIDR、Service CIDRは、オンプレミス、他VPC、Transit Gateway接続先、Direct Connect接続先と重複させてはいけません。

特に以下は避ける方針にします。

```text
100.64.0.0/16
100.88.0.0/16
169.254.0.0/17
172.20.0.1 と競合するCIDR
```

ROSA / OpenShiftでは内部的に利用されるCIDRがあるため、事前に重複確認を行います。

---

## 4.2 Subnet設計

## Private Cluster推奨構成

| Subnet種別 | AZ | CIDR例 | 用途 |
|---|---|---:|---|
| rosa-private-a | ap-northeast-1a | `10.40.10.0/24` | ROSA Worker Node / Internal LB |
| rosa-private-c | ap-northeast-1c | `10.40.11.0/24` | ROSA Worker Node / Internal LB |
| rosa-private-d | ap-northeast-1d | `10.40.12.0/24` | ROSA Worker Node / Internal LB |
| rosa-tgw-a | ap-northeast-1a | `10.40.100.0/28` | TGW Attachment専用 |
| rosa-tgw-c | ap-northeast-1c | `10.40.100.16/28` | TGW Attachment専用 |
| rosa-tgw-d | ap-northeast-1d | `10.40.100.32/28` | TGW Attachment専用 |
| rosa-endpoint-a | ap-northeast-1a | `10.40.110.0/27` | Interface VPC Endpoint用 |
| rosa-endpoint-c | ap-northeast-1c | `10.40.110.32/27` | Interface VPC Endpoint用 |
| rosa-endpoint-d | ap-northeast-1d | `10.40.110.64/27` | Interface VPC Endpoint用 |

ROSA HCPでは、各AZごとにPrivate Subnetを用意します。Multi-AZ構成では3つのAZを利用するため、最低3つのPrivate Subnetを用意します。

Transit Gateway Attachment用Subnetは、ROSA Worker Node用Subnetとは分離します。TGW VPC Attachmentには専用Subnetを使い、CIDRは `/28` のような小さい範囲にします。

---

## Public Clusterを選ぶ場合の追加Subnet

Public Clusterを採用する場合は、上記に加えてPublic Subnetを追加します。

| Subnet種別 | AZ | CIDR例 | 用途 |
|---|---|---:|---|
| rosa-public-a | ap-northeast-1a | `10.40.0.0/24` | NAT Gateway / Public LB |
| rosa-public-c | ap-northeast-1c | `10.40.1.0/24` | NAT Gateway / Public LB |
| rosa-public-d | ap-northeast-1d | `10.40.2.0/24` | NAT Gateway / Public LB |

Public Clusterでは、Public SubnetにNAT Gatewayを配置し、Private SubnetのデフォルトルートをNAT Gatewayへ向けます。

---

# 5. Route Table設計

## 5.1 Private Cluster推奨構成

### Private Subnet Route Table

| Destination | Target | 用途 |
|---|---|---|
| `10.40.0.0/16` | local | VPC内通信 |
| On-Premises CIDR | Transit Gateway | オンプレミス通信 |
| Shared Services CIDR | Transit Gateway | 共通基盤通信 |
| 必要なAWSサービスPrefix | VPC Endpoint | S3など |
| `0.0.0.0/0` | 原則なし / またはTGW | インターネット出口を閉じる、または共通Egressへ集約 |

Private Clusterで完全に閉域化する場合、Private Subnetから `0.0.0.0/0` を直接NAT Gatewayへ出す構成にはしません。外部通信が必要な場合は、TGW経由で共通Egress VPCやオンプレミスProxyへ出す方針にします。

### TGW Attachment Subnet Route Table

| Destination | Target | 用途 |
|---|---|---|
| `10.40.0.0/16` | local | VPC内通信 |
| On-Premises CIDR | Transit Gateway | オンプレミス戻り通信 |
| Shared Services CIDR | Transit Gateway | 共通基盤戻り通信 |

TGW Attachment SubnetはTransit Gatewayとの出入口専用にし、ROSA Worker Nodeやアプリケーションリソースを配置しません。

---

## 5.2 Public Cluster構成

### Public Subnet Route Table

| Destination | Target |
|---|---|
| `10.40.0.0/16` | local |
| `0.0.0.0/0` | Internet Gateway |

### Private Subnet Route Table

| Destination | Target |
|---|---|
| `10.40.0.0/16` | local |
| On-Premises CIDR | Transit Gateway |
| Shared Services CIDR | Transit Gateway |
| `0.0.0.0/0` | NAT Gateway |

---

# 6. Internet Gateway / NAT Gateway設計

## Private Clusterの場合

| リソース | 方針 |
|---|---|
| Internet Gateway | 原則作成しない |
| NAT Gateway | 原則作成しない |
| Public Subnet | 原則作成しない |
| 外部接続 | TGW経由で共通EgressまたはオンプレミスProxyへ集約 |

ただし、クラスタ作成、アップグレード、Operator更新、イメージ取得などで外部到達性が必要になる場合があります。そのため、Private Clusterでも「外へ出ない」という意味ではなく、**インターネットへ直接出さない** という設計にします。

## Public Clusterの場合

| リソース | 方針 |
|---|---|
| Internet Gateway | 作成する |
| NAT Gateway | Public Subnetごとに作成 |
| Public Subnet | 作成する |
| Private Subnet | Worker Node配置用に作成 |

---

# 7. VPC Endpoint設計

ROSA HCPのPrivate Cluster構成では、外部通信を減らすため、可能な範囲でVPC Endpointを利用します。

| Endpoint種別 | サービス例 | 方針 |
|---|---|---|
| Gateway Endpoint | S3 | 推奨 |
| Interface Endpoint | STS | 推奨 |
| Interface Endpoint | ECR API / ECR DKR | 必要に応じて |
| Interface Endpoint | CloudWatch Logs | 必要に応じて |
| Interface Endpoint | EC2 | 必要に応じて |
| Interface Endpoint | ELB | 必要に応じて |
| Interface Endpoint | Secrets Manager | 必要に応じて |
| Interface Endpoint | KMS | 必要に応じて |

S3 Gateway Endpointは、AWSサービス向け通信をVPC内に閉じるため優先的に検討します。

---

# 8. DNS設計

ROSA HCP用VPCでは、以下を必須方針にします。

| 項目 | 方針 |
|---|---|
| DNS hostnames | 有効化 |
| DNS resolution | 有効化 |
| DHCP Option Set | 原則AmazonProvidedDNSを利用 |
| Private Hosted Zone | 必要に応じてRoute 53 Resolverと連携 |
| オンプレDNS連携 | TGW / DX経由でRoute 53 Resolver inbound/outbound endpointを検討 |

カスタムDNS resolverを利用する場合は、ROSA / OpenShiftが必要とする名前解決に影響が出ないよう、Route 53 Private Hosted ZoneやAWS内部DNSの解決可否を事前に確認します。

---

# 9. Subnet Tag設計

ROSA HCPで利用するSubnetには、Kubernetes / OpenShiftがLoad Balancer用Subnetを識別できるようにタグを設定します。

## Private Subnet

```text
kubernetes.io/role/internal-elb = 1
```

## Public Subnetを利用する場合

```text
kubernetes.io/role/elb = 1
```

---

# 10. Security Group / NACL設計

## Security Group方針

| 対象 | 方針 |
|---|---|
| ROSA管理SG | ROSA作成時に必要なものを作成・管理 |
| 追加SG | 必要な場合のみ事前作成 |
| Ingress | 最小許可 |
| Egress | Private Clusterでは宛先をProxy / Endpoint / TGWに制限 |
| On-Premises通信 | 必要なCIDR / Portのみ許可 |

ROSAクラスタ作成時に追加カスタムSecurity Groupを指定する場合は、事前にAWS側で作成し、対象VPCに関連付けておきます。

## NACL方針

| Subnet | 方針 |
|---|---|
| TGW Attachment Subnet | 原則Open |
| ROSA Private Subnet | 必要に応じて制限 |
| Public Subnet | Public Cluster時のみ最小制限 |

TGW Attachment用SubnetのNACLは通信を妨げないようにし、細かい制御はSecurity Group、Route Table、Firewall、またはWorkload Subnet側で行います。

---

# 11. Transit Gateway接続設計

## 11.1 接続方針

rosaアカウントのROSA VPCは、InfrastructureアカウントのTransit GatewayにVPC Attachmentします。

| 項目 | 設計 |
|---|---|
| TGW所有アカウント | Infrastructureアカウント |
| VPC所有アカウント | rosaアカウント |
| 共有方式 | AWS RAMでTGWをrosaアカウントに共有 |
| Attachment Subnet | rosa-tgw-a / c / d |
| TGW Route Table | ROSA用Route Tableを分離推奨 |
| 通信先 | On-Premises / Shared Services / Egress VPC |

Infrastructureアカウントは、ネットワーク集約アカウントとして扱います。

---

## 11.2 TGW Route Table方針

| Route Table | 用途 |
|---|---|
| tgw-rt-rosa | ROSA VPC専用 |
| tgw-rt-infra | Infrastructure / Shared Services用 |
| tgw-rt-onprem | Direct Connect / VPN接続用 |

ROSA VPCから必要な通信先だけを許可します。

| Source | Destination | 許可方針 |
|---|---|---|
| ROSA VPC | On-Premises | 必要なCIDRのみ許可 |
| ROSA VPC | Shared Services | DNS / Proxy / Monitoringなど必要なもののみ許可 |
| ROSA VPC | 他Workload VPC | 原則禁止 |
| On-Premises | ROSA API / App | 必要なPortのみ許可 |
| Internet | ROSA VPC | Private Clusterでは禁止 |

Transit GatewayはRoute TableでSpoke間通信を制御できるため、ROSA VPCを他のWorkload VPCと不用意に相互接続しない設計にします。

---

# 12. ログ・監視設計

| 項目 | 方針 |
|---|---|
| VPC Flow Logs | 有効化 |
| 保存先 | log-archiveアカウントのS3、またはCloudWatch Logs |
| TGW Flow Logs | 可能であれば有効化 |
| Route Table変更 | CloudTrailで監査 |
| Security Group変更 | CloudTrail / AWS Configで監査 |
| VPC Endpoint通信 | CloudTrail / Service側ログで確認 |

ROSAアカウント単体でログを閉じず、AWS Organizations全体の方針に合わせて、log-archiveアカウントへ集約する方針にします。

---

# 13. 命名規則・タグ設計

## 命名規則

```text
<env>-<system>-<resource>-<az>
```

例：

```text
prd-rosa-vpc
prd-rosa-private-apne1a
prd-rosa-private-apne1c
prd-rosa-private-apne1d
prd-rosa-tgw-apne1a
prd-rosa-tgw-apne1c
prd-rosa-tgw-apne1d
prd-rosa-rt-private-apne1a
prd-rosa-rt-tgw
```

## 共通タグ

| Key | Value例 |
|---|---|
| Name | prd-rosa-vpc |
| System | rosa |
| Environment | prd |
| AccountType | workload |
| Owner | platform-team |
| ManagedBy | terraform |
| CostCenter | platform |
| NetworkScope | private |
| DataClassification | internal |

---

# 14. 推奨構成まとめ

## Private Cluster推奨構成

```text
VPC: 10.40.0.0/16

Private Subnets:
- 10.40.10.0/24 ap-northeast-1a
- 10.40.11.0/24 ap-northeast-1c
- 10.40.12.0/24 ap-northeast-1d

TGW Attachment Subnets:
- 10.40.100.0/28 ap-northeast-1a
- 10.40.100.16/28 ap-northeast-1c
- 10.40.100.32/28 ap-northeast-1d

Endpoint Subnets:
- 10.40.110.0/27 ap-northeast-1a
- 10.40.110.32/27 ap-northeast-1c
- 10.40.110.64/27 ap-northeast-1d

Internet Gateway: なし
NAT Gateway: なし
Transit Gateway Attachment: あり
VPC Endpoint: あり
External Egress: TGW経由で共通EgressまたはオンプレProxy
```

## Public Cluster構成

```text
VPC: 10.40.0.0/16

Public Subnets:
- 10.40.0.0/24 ap-northeast-1a
- 10.40.1.0/24 ap-northeast-1c
- 10.40.2.0/24 ap-northeast-1d

Private Subnets:
- 10.40.10.0/24 ap-northeast-1a
- 10.40.11.0/24 ap-northeast-1c
- 10.40.12.0/24 ap-northeast-1d

TGW Attachment Subnets:
- 10.40.100.0/28 ap-northeast-1a
- 10.40.100.16/28 ap-northeast-1c
- 10.40.100.32/28 ap-northeast-1d

Internet Gateway: あり
NAT Gateway: Public Subnetごとに配置
Transit Gateway Attachment: あり
VPC Endpoint: あり
```

---

# 15. 設計判断

今回の前提では、以下を推奨します。

| 項目 | 推奨 |
|---|---|
| ROSAクラスタ方式 | Private Cluster |
| VPC | ROSA専用VPC |
| AZ | 3AZ |
| Worker Node Subnet | Private Subnet |
| TGW Attachment Subnet | 専用 `/28` Subnet |
| Public Subnet | 原則なし |
| NAT Gateway | 原則なし |
| Internet Gateway | 原則なし |
| 外部通信 | TGW経由で共通Egress / オンプレProxy |
| AWSサービス通信 | VPC Endpoint優先 |
| 他VPC通信 | 原則禁止、必要な宛先のみTGWで許可 |
| ログ | log-archiveアカウントへ集約 |

特に、InfrastructureアカウントにDirect ConnectとTransit Gatewayを集約する前提なら、ROSA VPC側に安易にInternet Gateway / NAT Gatewayを置くより、**TGW経由で出口を統制する設計** の方がマルチアカウント運用として自然です。

---

# 16. 設計上の注意点

一番重要なのは、**Private Cluster = 外部通信が不要** ではないことです。

Private Clusterは、インターネットから直接入らない構成です。  
しかし、クラスタ作成、アップグレード、Operator、イメージ取得、S3、STS、ECRなどへの通信が必要になる場合があります。

そのため、Private Clusterを選ぶ場合は、次のどちらかを必ず設計します。

```text
ROSA VPC → TGW → 共通Egress VPC → Internet
```

または、

```text
ROSA VPC → TGW → Direct Connect → On-Premises Proxy / Firewall → Internet
```

この出口設計がないと、「Private ClusterだからPublic SubnetもNATも不要」と考えて作った後に、クラスタ作成・アップグレード・外部レジストリ取得で詰まる可能性があります。

---

# 17. 参考リンク

## AWS

- AWS Transit Gateway design best practices  
  https://docs.aws.amazon.com/vpc/latest/tgw/tgw-best-design-practices.html

- Building a Scalable and Secure Multi-VPC AWS Network Infrastructure  
  https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/transit-gateway.html

## Red Hat ROSA HCP

- ROSA HCP prerequisites  
  https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/prepare_your_environment/rosa-hcp-prereqs

- Creating a ROSA HCP cluster quickly  
  https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/install_clusters/rosa-hcp-sts-creating-a-cluster-quickly

- CIDR range definitions  
  https://docs.redhat.com/ja/documentation/red_hat_openshift_service_on_aws/4/html/networking_overview/cidr-range-definitions

---

# 18. 補足：設計をさらに具体化するために必要な情報

実際の本番設計に進む場合は、以下を追加で確定します。

| 項目 | 確認内容 |
|---|---|
| Cluster方式 | Private Cluster / Public Cluster |
| Region | 例：ap-northeast-1 |
| 利用AZ | 例：ap-northeast-1a / 1c / 1d |
| オンプレミスCIDR | Direct Connect経由で到達するCIDR |
| 他VPC CIDR | TGW接続済みのVPC CIDR |
| Egress方式 | 共通Egress VPC / オンプレProxy / NAT Gateway |
| DNS方式 | AmazonProvidedDNS / オンプレDNS連携 / Route 53 Resolver |
| ログ保存先 | log-archiveアカウントのS3など |
| 運用監視 | CloudWatch / Security Hub / Config / GuardDutyなど |

```
