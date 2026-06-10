```
# AWS ROSA HCP用VPC設計サンプル

## 概要

ROKS移行プロジェクト用VPC設計サンプルを記載する。

## 2. 対象構成

```text
On-Premise
  ↓ Direct Connect
infrastructure account
  ↓ Transit Gateway
rosa account
  ↓ ROSA用VPC
ROSA HCP
```

## 3. 要件

- AWS Organizations を利用したマルチアカウント構成
- Direct Connect と Transit Gateway は `infrastructure account` に配置
- ROSA HCP と ROSA 用 VPC は `rosa account` に配置
- ROSA クラスタは Multi-AZ 構成
- ROSA クラスタは Public Cluster
- Internet 経由で `oc` コマンドなどを実行可能にする
- ROSA 上の Pod は Transit Gateway + Direct Connect 経由でオンプレミスサーバーへアクセスする
- ROSA 上の Pod は必要に応じて Internet へ Outbound 通信する
- VPC CIDR / Pod CIDR / Service CIDR / オンプレ CIDR / 他 VPC CIDR は重複させない

## 4. 重要な考え方

### 4.1 Public Cluster と NAT Gateway は役割が違う

Public Cluster は、管理者端末から Internet 経由でクラスタ API Endpoint にアクセスできる構成を意味します。

```text
Admin PC
  ↓ Internet
ROSA HCP Public API Endpoint
```

この入口通信に、ROSA VPC 内の NAT Gateway は直接関係しません。

一方で、NAT Gateway は Private Subnet 内の Worker Node / Pod / クラスタコンポーネントが Internet へ Outbound 通信するために使います。

```text
ROSA Worker Node / Pod / Cluster Component
  ↓ Private Subnet
  ↓ NAT Gateway
  ↓ Internet Gateway
  ↓ Internet
```

つまり、以下のように分けて考えます。

| 通信要件 | 主な経路 |
|---|---|
| 管理者端末から `oc login` / `oc get nodes` を実行 | Public API Endpoint |
| Worker Node / Pod から Internet へ出る | NAT Gateway または Proxy |
| Pod からオンプレミスサーバーへ接続 | Transit Gateway + Direct Connect |
| AWS サービスへ Private 経路で接続 | VPC Endpoint |

### 4.2 NAT Gateway は標準構成では必要

ROSA HCP の Public Cluster を標準的な VPC 構成で構築する場合、NAT Gateway 付き Public Subnet は必要と考えます。

ただし、NAT Gateway が必要なのは `oc` コマンドの入口通信のためではありません。ROSA 側から外部へ出る Outbound 通信のためです。

NAT Gateway を使わない設計も理論上は可能ですが、その場合は以下のような代替 Egress 経路が必要です。

```text
Private Subnet
  ↓ Transit Gateway
  ↓ Central Egress VPC / Proxy / Firewall
  ↓ Internet
```

または、

```text
Private Subnet
  ↓ 社内 Proxy
  ↓ Internet
```

## 5. 指摘事項

### 5.1 添付イメージの方向性

添付イメージの以下の方向性は正しいです。

```text
On-Premise
  ↓ Direct Connect
Infrastructure Account
  ↓ Transit Gateway
ROSA Account
  ↓ ROSA用VPC
ROSA HCP
```

ただし、実際の設計では図に以下を追加する必要があります。

- Public Subnet
- Private Worker Subnet
- TGW Attachment Subnet
- Internet Gateway
- NAT Gateway
- Route Table
- TGW Route Table
- VPC Endpoint
- DNS 設計
- ログ・監査設計

### 5.2 Public Cluster = Worker Node が Public Subnet にある、ではない

Public Cluster であっても、Worker Node は原則として Private Subnet に配置します。

Public Cluster は、クラスタ API Endpoint が Internet 経由でアクセス可能であるという意味であり、Worker Node や Pod を Public Subnet に置くという意味ではありません。

### 5.3 Multi-AZ は 3AZ 前提で設計する

ROSA HCP を Multi-AZ 構成にする場合、3つの Availability Zone を使う前提で設計します。

### 5.4 オンプレ接続は戻りルートも必要

Pod からオンプレミスサーバーへ通信するには、ROSA VPC 側だけでなく、オンプレミス側にも戻りルートが必要です。

```text
ROSA VPC Private Worker Subnet Route Table
  On-Premise CIDR → Transit Gateway

On-Premise Router
  ROSA VPC CIDR → Direct Connect
```

## 6. サンプル CIDR 設計

| 用途 | CIDR 例 |
|---|---:|
| ROSA VPC CIDR / Machine CIDR | `10.60.0.0/16` |
| ROSA Service CIDR | `172.30.0.0/16` |
| ROSA Pod CIDR | `10.128.0.0/14` |
| On-Premise CIDR | `192.168.0.0/16` |

以下は必ず重複させないようにします。

```text
ROSA VPC CIDR
ROSA Machine CIDR
ROSA Pod CIDR
ROSA Service CIDR
他 VPC CIDR
オンプレミス CIDR
将来追加予定の VPC CIDR
```

## 7. Subnet 設計

### 7.1 推奨 Subnet 構成

| AZ | Subnet 種別 | CIDR 例 | 用途 |
|---|---|---:|---|
| ap-northeast-1a | Public | `10.60.0.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1c | Public | `10.60.1.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1d | Public | `10.60.2.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1a | Private Worker | `10.60.10.0/23` | ROSA Worker Node |
| ap-northeast-1c | Private Worker | `10.60.12.0/23` | ROSA Worker Node |
| ap-northeast-1d | Private Worker | `10.60.14.0/23` | ROSA Worker Node |
| ap-northeast-1a | TGW Attachment | `10.60.100.0/28` | TGW Attachment 専用 |
| ap-northeast-1c | TGW Attachment | `10.60.100.16/28` | TGW Attachment 専用 |
| ap-northeast-1d | TGW Attachment | `10.60.100.32/28` | TGW Attachment 専用 |
| ap-northeast-1a | VPC Endpoint | `10.60.110.0/28` | Interface Endpoint 用 |
| ap-northeast-1c | VPC Endpoint | `10.60.110.16/28` | Interface Endpoint 用 |
| ap-northeast-1d | VPC Endpoint | `10.60.110.32/28` | Interface Endpoint 用 |

### 7.2 TGW Attachment Subnet は分離する

TGW Attachment 用 Subnet は、Worker Node 用 Subnet とは分けます。

理由は以下です。

- TGW との出入口を明確化できる
- Route Table を分離しやすい
- 障害調査がしやすい
- 将来的な Network Firewall / Inspection VPC 連携を考えやすい

## 8. VPC 構成イメージ

```text
rosa account
└── ROSA VPC: 10.60.0.0/16
    │
    ├── Public Subnet AZ-a: 10.60.0.0/24
    │   ├── Internet Gateway route: 0.0.0.0/0 → IGW
    │   └── NAT Gateway
    │
    ├── Public Subnet AZ-c: 10.60.1.0/24
    │   ├── Internet Gateway route: 0.0.0.0/0 → IGW
    │   └── NAT Gateway
    │
    ├── Public Subnet AZ-d: 10.60.2.0/24
    │   ├── Internet Gateway route: 0.0.0.0/0 → IGW
    │   └── NAT Gateway
    │
    ├── Private Worker Subnet AZ-a: 10.60.10.0/23
    │   ├── 0.0.0.0/0 → NAT Gateway AZ-a
    │   └── 192.168.0.0/16 → TGW
    │
    ├── Private Worker Subnet AZ-c: 10.60.12.0/23
    │   ├── 0.0.0.0/0 → NAT Gateway AZ-c
    │   └── 192.168.0.0/16 → TGW
    │
    ├── Private Worker Subnet AZ-d: 10.60.14.0/23
    │   ├── 0.0.0.0/0 → NAT Gateway AZ-d
    │   └── 192.168.0.0/16 → TGW
    │
    ├── TGW Attachment Subnet AZ-a: 10.60.100.0/28
    ├── TGW Attachment Subnet AZ-c: 10.60.100.16/28
    └── TGW Attachment Subnet AZ-d: 10.60.100.32/28
```

## 9. Route Table 設計

### 9.1 Public Subnet Route Table

```text
Destination        Target
10.60.0.0/16       local
0.0.0.0/0          Internet Gateway
```

### 9.2 Private Worker Subnet Route Table

```text
Destination        Target
10.60.0.0/16       local
192.168.0.0/16     Transit Gateway
0.0.0.0/0          NAT Gateway（同一AZ）
```

意味は以下です。

```text
VPC 内通信           → local
オンプレミス通信      → Transit Gateway
Internet Outbound    → NAT Gateway
```

### 9.3 TGW Attachment Subnet Route Table

```text
Destination        Target
10.60.0.0/16       local
```

TGW Attachment Subnet は TGW Attachment 専用にし、余計な経路は最小限にします。

## 10. Transit Gateway 設計

### 10.1 Attachment 構成

```text
Transit Gateway
├── Direct Connect Gateway Attachment
└── ROSA VPC Attachment
```

### 10.2 TGW Route Table 例

```text
Destination        Target
10.60.0.0/16       ROSA VPC Attachment
192.168.0.0/16     Direct Connect Gateway Attachment
```

より厳密に分離する場合は、以下のように Route Table を分けます。

```text
tgw-rtb-rosa
  - ROSA VPC Attachment を Association
  - On-Premise CIDR → Direct Connect Gateway Attachment

tgw-rtb-onprem
  - Direct Connect Gateway Attachment を Association
  - ROSA VPC CIDR → ROSA VPC Attachment
```

重要なのは、以下の両方を成立させることです。

```text
ROSA VPC → On-Premise
On-Premise → ROSA VPC
```

## 11. Direct Connect / オンプレミス側設計

オンプレミス側ルーターには、ROSA VPC CIDR への戻りルートが必要です。

```text
Destination        Next Hop
10.60.0.0/16       Direct Connect
```

今回の要件は「Pod からオンプレミスサーバーへアクセス」なので、基本の通信フローは以下です。

```text
Pod
  ↓
Worker Node
  ↓
VPC Route Table
  ↓
Transit Gateway
  ↓
Direct Connect
  ↓
On-Premise Server
```

オンプレミスから Pod IP へ直接通信させる設計にする場合は、Pod CIDR の扱い、OpenShift SDN/OVN-Kubernetes の挙動、戻り通信、セキュリティ設計を別途確認する必要があります。

まずは以下のように設計する方が現実的です。

```text
ROSA Pod → On-Premise Server への Outbound 接続
On-Premise → ROSA Application は Service / Route / LoadBalancer 経由
```

## 12. Internet 出口設計

### 12.1 推奨構成

```text
Private Worker Subnet
  ↓
AZ ごとの NAT Gateway
  ↓
Internet Gateway
  ↓
Internet
```

本番レベルでは、AZ ごとに NAT Gateway を配置し、各 Private Worker Subnet は同一 AZ の NAT Gateway へルーティングします。

理由は以下です。

- AZ 障害時の影響を局所化できる
- クロス AZ 通信コストを抑えられる
- Multi-AZ 構成として自然

### 12.2 NAT Gateway を使わない代替案

将来的に Internet 出口を中央管理したい場合は、以下も候補になります。

```text
ROSA VPC
  ↓ Transit Gateway
Central Egress VPC / Proxy / Firewall
  ↓ Internet
```

ただし、この場合は ROSA HCP / OpenShift が必要とする外部通信要件を満たせるかを事前に確認する必要があります。

## 13. VPC Endpoint 設計

Public Cluster であっても、AWS サービス向け通信には VPC Endpoint を使うことを推奨します。

| Endpoint | 種別 | 用途 |
|---|---|---|
| S3 | Gateway Endpoint | S3 アクセス |
| STS | Interface Endpoint | AWS STS 利用 |
| ECR API | Interface Endpoint | ECR API |
| ECR DKR | Interface Endpoint | コンテナイメージ Pull |
| CloudWatch Logs | Interface Endpoint | ログ送信 |
| EC2 | Interface Endpoint | EC2 API |
| Elastic Load Balancing | Interface Endpoint | LB 操作 |

ただし、VPC Endpoint を作れば NAT Gateway が完全に不要になるとは限りません。

実務では以下のように整理します。

```text
AWS サービス向け通信       → VPC Endpoint
AWS 外・Red Hat 関連通信    → NAT Gateway または Proxy
オンプレミス通信           → Transit Gateway + Direct Connect
```

## 14. Security Group / NACL 設計

### 14.1 Security Group

ROSA HCP では ROSA 側が管理する Security Group もあるため、手動変更は最小限にします。

```text
ROSA 管理 Security Group:
  - ROSA が必要とする通信を維持
  - 手動変更は最小限

追加アプリ用 Security Group:
  - アプリ公開要件に応じて作成
  - オンプレミスから必要な Port のみ許可
```

### 14.2 NACL

NACL はステートレス制御であり、細かく制御しすぎるとトラブルになりやすいです。

推奨方針は以下です。

```text
NACL:
  - 基本は広め
  - 明確な遮断要件がある場合のみ制御

Security Group:
  - 実際の通信制御の中心
```

## 15. DNS 設計

オンプレミスサーバーへ名前解決でアクセスする場合、Route 53 Resolver を検討します。

```text
ROSA Pod
  ↓
VPC DNS / Route 53 Resolver
  ↓
Route 53 Resolver Outbound Endpoint
  ↓
On-Premise DNS
```

オンプレミスから ROSA 側の名前解決が必要な場合は、Inbound Resolver Endpoint も検討します。

## 16. ログ・監査設計

最低限、以下を有効化することを推奨します。

| ログ / 監査 | 出力先 / 管理先 |
|---|---|
| VPC Flow Logs | Log Archive アカウントの S3 |
| CloudTrail | Organizations Trail で Log Archive へ集約 |
| AWS Config | Audit アカウントの Aggregator |
| Security Hub CSPM | Audit アカウントで中央管理 |
| TGW Flow Logs | Infrastructure または Log Archive |

ROSA VPC とオンプレミス間の通信調査では、VPC Flow Logs と TGW Flow Logs を組み合わせると運用しやすくなります。

## 17. 通信フロー

### 17.1 oc コマンド

```text
Admin PC
  ↓ Internet
ROSA HCP Public API Endpoint
```

この通信に ROSA VPC 内の NAT Gateway は使いません。

### 17.2 Pod からオンプレミスサーバー

```text
ROSA Pod
  ↓
Worker Node
  ↓
Private Worker Subnet Route Table
  ↓ 192.168.0.0/16 → Transit Gateway
Transit Gateway
  ↓
Direct Connect Gateway
  ↓
Direct Connect
  ↓
On-Premise Server
```

### 17.3 Pod から Internet

```text
ROSA Pod
  ↓
Worker Node
  ↓
Private Worker Subnet Route Table
  ↓ 0.0.0.0/0 → NAT Gateway
NAT Gateway
  ↓
Internet Gateway
  ↓
Internet
```

### 17.4 Pod から AWS サービス

```text
ROSA Pod
  ↓
Worker Node
  ↓
VPC Endpoint
  ↓
AWS Service
```

Endpoint 未設定の AWS サービスについては NAT Gateway 経由になる可能性があります。

## 18. 最終構成案

### 18.1 rosa account 側

```text
ROSA VPC: 10.60.0.0/16

Public Subnets:
  - 10.60.0.0/24    ap-northeast-1a
  - 10.60.1.0/24    ap-northeast-1c
  - 10.60.2.0/24    ap-northeast-1d

Private Worker Subnets:
  - 10.60.10.0/23   ap-northeast-1a
  - 10.60.12.0/23   ap-northeast-1c
  - 10.60.14.0/23   ap-northeast-1d

TGW Attachment Subnets:
  - 10.60.100.0/28     ap-northeast-1a
  - 10.60.100.16/28    ap-northeast-1c
  - 10.60.100.32/28    ap-northeast-1d

VPC Endpoint Subnets:
  - 10.60.110.0/28     ap-northeast-1a
  - 10.60.110.16/28    ap-northeast-1c
  - 10.60.110.32/28    ap-northeast-1d
```

### 18.2 Route 方針

```text
Public Subnet:
  0.0.0.0/0 → Internet Gateway

Private Worker Subnet:
  On-Premise CIDR → Transit Gateway
  0.0.0.0/0 → NAT Gateway 同一AZ

TGW Route Table:
  ROSA VPC CIDR → ROSA VPC Attachment
  On-Premise CIDR → Direct Connect Gateway Attachment

On-Premise Router:
  ROSA VPC CIDR → Direct Connect
```

## 19. まとめ

この設計では、通信目的ごとに経路を分離します。

```text
oc コマンドによるクラスタ操作
  → Public API Endpoint

Pod からオンプレミスサーバーへの通信
  → Transit Gateway + Direct Connect

Pod / Worker Node から Internet への Outbound 通信
  → NAT Gateway または Proxy

AWS サービスへの通信
  → VPC Endpoint
```

特に重要なのは、`Public Cluster` と `NAT Gateway` を混同しないことです。

- Public Cluster は、外部からクラスタ API にアクセスするための入口設計
- NAT Gateway は、Private Subnet から Internet へ出るための出口設計

この2つを分けて考えることで、ROSA HCP の VPC 設計ミスを減らせます。










vpc_ec2_tgw.tf
##############################
# Variable
##############################
locals {
  system-prd-id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "system-prd"
  ][0]
  management-id = [
    for account in data.aws_organizations_organization.current.accounts :
    account.id if account.name == "management"
  ][0]
}

##############################
# Transit Gateway
##############################
resource "aws_ec2_transit_gateway" "main" {
  provider = aws.infrastructure

  description                     = "test-tgw"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = "test-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  provider = aws.infrastructure

  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "test-tgw-rt"
  }
}

##############################
# RAM
##############################
resource "aws_ram_sharing_with_organization" "this" {
  provider = aws.management
}

# aws_ram_sharing_with_organizationは作成完了まで時間がかかるため、リソース共有の前に待機する
resource "time_sleep" "wait_ram" {
  depends_on      = [aws_ram_sharing_with_organization.this]
  create_duration = "60s"
}

resource "aws_ram_resource_share" "tgw" {
  provider = aws.infrastructure

  name                      = "test-tgw-share"
  allow_external_principals = false

  tags = {
    Name = "test-tgw-share"
  }

  depends_on = [
    aws_ram_sharing_with_organization.this
  ]
}

resource "aws_ram_resource_association" "tgw" {
  provider = aws.infrastructure

  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.tgw.arn

  depends_on = [time_sleep.wait_ram]
}

resource "aws_ram_principal_association" "system-prd" {
  provider = aws.infrastructure

  principal          = local.system-prd-id
  resource_share_arn = aws_ram_resource_share.tgw.arn

  depends_on = [time_sleep.wait_ram]
}

resource "aws_ram_principal_association" "management" {
  provider = aws.infrastructure

  principal          = local.management-id
  resource_share_arn = aws_ram_resource_share.tgw.arn

  depends_on = [time_sleep.wait_ram]
}

##############################
# VPC (system-prd)
##############################
data "aws_availability_zones" "system-prd" {
  provider = aws.system-prd
  state    = "available"
}

resource "aws_vpc" "system-prd" {
  provider = aws.system-prd

  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "system-prd-vpc"
  }
}

resource "aws_subnet" "system-prd_private" {
  provider = aws.system-prd

  vpc_id                  = aws_vpc.system-prd.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.system-prd.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "system-prd-private-subnet"
  }
}

resource "aws_route_table" "system-prd_private" {
  provider = aws.system-prd

  vpc_id = aws_vpc.system-prd.id

  tags = {
    Name = "system-prd-private-rt"
  }
}

resource "aws_route_table_association" "system-prd_private" {
  provider = aws.system-prd

  subnet_id      = aws_subnet.system-prd_private.id
  route_table_id = aws_route_table.system-prd_private.id
}

##############################
# TGW VPC Attachments
##############################
resource "aws_ec2_transit_gateway_vpc_attachment" "system-prd" {
  provider = aws.system-prd

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.system-prd.id
  subnet_ids         = [aws_subnet.system-prd_private.id]

  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "system-prd-to-test-tgw"
  }

  depends_on = [
    aws_ram_resource_association.tgw,
    aws_ram_principal_association.system-prd
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "management" {
  provider = aws.management

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.rosa.id
  subnet_ids         = aws_subnet.management-private[*].id

  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "management-to-test-tgw"
  }

  depends_on = [
    aws_ram_resource_association.tgw,
    aws_ram_principal_association.management
  ]
}

##############################
# TGW Route Table Association
##############################
resource "aws_ec2_transit_gateway_route_table_association" "system-prd" {
  provider = aws.infrastructure

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.system-prd.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "management" {
  provider = aws.infrastructure

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.management.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

##############################
# TGW Routes
##############################
resource "aws_ec2_transit_gateway_route" "to_system-prd" {
  provider = aws.infrastructure

  destination_cidr_block         = aws_vpc.system-prd.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.system-prd.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id

  depends_on = [
    aws_ec2_transit_gateway_route_table_association.system-prd
  ]
}

resource "aws_ec2_transit_gateway_route" "to_management" {
  provider = aws.infrastructure

  destination_cidr_block         = aws_vpc.rosa.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.management.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id

  depends_on = [
    aws_ec2_transit_gateway_route_table_association.management
  ]
}

##############################
# Workload VPC Routes to TGW
##############################
resource "aws_route" "system-prd_to_management" {
  provider = aws.system-prd

  route_table_id         = aws_route_table.system-prd_private.id
  destination_cidr_block = aws_vpc.rosa.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.system-prd
  ]
}

resource "aws_route" "management_to_system-prd" {
  provider = aws.management
  count    = 3

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = aws_vpc.system-prd.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.management
  ]
}










vpc_rosa.tf
resource "aws_vpc" "rosa" {
  provider             = aws.management
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-vpc"
  })
}

resource "aws_internet_gateway" "rosa" {
  provider = aws.management
  vpc_id   = aws_vpc.rosa.id

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-igw"
  })
}

resource "aws_subnet" "management-public" {
  provider = aws.management
  count    = 3

  vpc_id                  = aws_vpc.rosa.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name                     = "${local.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "management-private" {
  provider = aws.management
  count    = 3

  vpc_id            = aws_vpc.rosa.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 10)

  tags = merge(local.tags, {
    Name                              = "${local.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_eip" "nat" {
  provider = aws.management
  count    = 3

  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "nat" {
  provider = aws.management
  count    = 3

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.management-public[count.index].id

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.rosa]
}

resource "aws_route_table" "public" {
  provider = aws.management
  vpc_id   = aws_vpc.rosa.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rosa.id
  }

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  provider = aws.management
  count    = 3

  subnet_id      = aws_subnet.management-public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  provider = aws.management
  count    = 3

  vpc_id = aws_vpc.rosa.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  provider = aws.management
  count    = 3

  subnet_id      = aws_subnet.management-private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  provider          = aws.management
  vpc_id            = aws_vpc.rosa.id
  service_name      = "com.amazonaws.${local.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(local.tags, {
    Name = "${local.cluster_name}-s3-endpoint"
  })
}










locals {
  aws_region      = "ap-northeast-1"
  cluster_name    = "rosa-hcp-sample"
  role_prefix     = "rosa-hcp-sample"
  operator_prefix = "rosa-hcp-sample"

  vpc_cidr     = "10.2.0.0/16"
  service_cidr = "172.30.0.0/16"
  pod_cidr     = "10.128.0.0/14"
  host_prefix  = 23

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # OIDC endpoint URL をスキームなしのホスト名へ正規化し、全箇所で統一して使う
  oidc_endpoint_url = replace(
    rhcs_rosa_oidc_config.oidc.oidc_endpoint_url,
    "https://",
    ""
  )

  tags = {
    Environment = "dev"
    Project     = "rosa-hcp-sample"
    Terraform   = "true"
  }
}









cluster.tf
resource "rhcs_cluster_rosa_hcp" "this" {
  name                   = local.cluster_name
  cloud_region           = local.aws_region
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_billing_account_id = data.aws_caller_identity.current.account_id

  version       = "4.21.17" # 取得したい具体的なバージョンを指定
  channel_group = "stable"  # "stable", "fast", "nightly" など（通常は stable）

  # HCP / STS
  sts = {
    role_arn             = aws_iam_role.installer.arn
    support_role_arn     = aws_iam_role.support.arn
    operator_role_prefix = local.operator_prefix
    oidc_config_id       = rhcs_rosa_oidc_config.oidc.id

    instance_iam_roles = {
      worker_role_arn = aws_iam_role.worker.arn
    }
  }

  # Network
  machine_cidr = local.vpc_cidr
  service_cidr = local.service_cidr
  pod_cidr     = local.pod_cidr
  host_prefix  = local.host_prefix

  aws_subnet_ids = concat(
    aws_subnet.management-public[*].id,
    aws_subnet.management-private[*].id
  )

  availability_zones = local.azs

  # Cluster type
  private = false

  # Worker nodes
  replicas             = 3
  compute_machine_type = "m5.xlarge"

  # IMDS
  ec2_metadata_http_tokens = "required"

  # Admin user
  create_admin_user = true

  wait_for_create_complete            = true
  wait_for_std_compute_nodes_complete = true

  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }

  tags = local.tags

  depends_on = [
    time_sleep.wait_account_roles,
    time_sleep.wait_operator_roles,
    aws_nat_gateway.nat,
    aws_route_table_association.private,
    aws_route_table_association.public,
    aws_vpc_endpoint.s3
  ]
}

resource "rhcs_hcp_default_ingress" "default" {
  cluster          = rhcs_cluster_rosa_hcp.this.id
  listening_method = "external"

  depends_on = [
    rhcs_cluster_rosa_hcp.this
  ]
}

```
