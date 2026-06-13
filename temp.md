# AWS ROSA HCP用VPC設計サンプル

## 概要

ROKS移行プロジェクト向けに、AWS ROSA HCPを利用する場合のVPC設計サンプルを記載する。

## 構成図（シンプルバージョン）

![rosa_network_01.png](./images/rosa_network_01.png)

## 前提 / 要件

- AWS Organizationsを利用したマルチアカウント構成。
- Direct ConnectとTransit Gatewayは`infrastructure account`に配置。
- ROSA HCPとROSA用VPCは`rosa account`に配置。
- ROSAクラスタはMulti-AZ構成。
- ROSAクラスタはPublic Cluster。
- Internet経由でROSA管理可能にする。
- ROSA上のPodはTransit Gateway + Direct Connect経由でオンプレミスサーバーへアクセスする。
- ROSA上のPodは必要に応じてInternetへOutbound通信する。
- VPC CIDR / Pod CIDR / Service CIDR / オンプレ CIDR / 他VPC CIDRは重複させない。

## 用語 / 構成

- Public Cluster
  - 管理端末からインターネット経由でROSA HCPのAPI Endpointへアクセスできる構成。
  - 標準構成では、クラスタ用VPCにInternet GatewayおよびNAT Gatewayを配置する。
  - Public Clusterであっても、Worker Nodeは通常Private Subnetに配置する。
- Multi-AZ構成
  - 可用性向上のため、3つのAvailability Zone（AZ）にWorker Nodeを分散配置する構成。
  - ROSA HCPのMulti-AZクラスタでは、3つのAZに対応するSubnetが必要となる。
  - 単一AZで障害が発生した場合でも、他AZのWorker NodeでWorkloadを継続できる。
- Internet Gateway
  - VPCとインターネット間の通信を可能にする。
  - Public Subnetに配置されたリソースがインターネットと直接通信する際の出口・入口として利用される。
  - NAT Gatewayがインターネットへ通信する際の経路としても利用される。
- NAT Gateway
  - Private Subnet内のWorker NodeやPodが、インターネットおよびAWSのPublic EndpointへOutbound通信を行うために利用する。
  - 外部からのInbound通信は受け付けない。
- VPC Endpoint
  - AWSサービスへインターネットを経由せず、AWSネットワーク内のPrivate経路で接続するために利用する。
  - NAT Gateway経由の通信を削減し、セキュリティ向上および通信コスト削減に寄与する。
- ROSA用CIDR
  - Machine CIDR
    - Worker Nodeなど、クラスタのノードに割り当てるIPアドレス範囲。
    - VPC全体のCIDRそのものを説明するものではなく、ROSA/OpenShiftクラスタがノード用として認識するアドレス範囲。
    - 通常、Machine CIDRはROSA VPCのCIDRと一致させる、もしくはVPC CIDRの範囲内に収まるように設定する。
  - Service CIDR
    - Kubernetes/OpenShiftのServiceに割り当てる仮想IPアドレス範囲。
    - PodやNodeに直接割り当てるIPではなく、ClusterIP Serviceなどの内部通信で利用される。
    - VPCのSubnetとして作成するCIDRではなく、クラスタ内部だけで利用される論理的なIP範囲。
  - Pod CIDR
    - Podに割り当てるIPアドレス範囲。
    - VPCのSubnet CIDRではなく、OpenShiftのクラスタネットワーク内部で利用されるCIDR。
  - Host Prefix
    - Pod CIDRを各Worker Nodeに分割して割り当てる際の1ノードあたりのPod用CIDRサイズ。
    - 例えば、Pod CIDRが10.128.0.0/14、Host Prefixが/23の場合、各Worker NodeにはPod用に/23単位のIP範囲が割り当てられる。<br>
    （Pod数は約500個以上）

## CIDR設計

| 用途 | CIDR |
|---|---:|
| ROSA VPC CIDR / Machine CIDR | `10.1.0.0/16` |
| ROSA Service CIDR | `172.30.0.0/16` |
| ROSA Pod CIDR | `10.128.0.0/14` |
| On-Premise CIDR | `192.168.0.0/16` |

以下は必ず重複させないようにする。

- ROSA VPC CIDR
- ROSA Machine CIDR
- ROSA Pod CIDR
- ROSA Service CIDR
- 他 VPC CIDR
- オンプレミス CIDR
- 将来追加予定の VPC CIDR

## Subnet設計

### Subnet構成

| AZ | Subnet 種別 | CIDR 例 | 用途 |
|---|---|---:|---|
| ap-northeast-1a | Public | `10.1.0.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1c | Public | `10.1.1.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1d | Public | `10.1.2.0/24` | NAT Gateway / Public LB 用 |
| ap-northeast-1a | Private Worker | `10.1.10.0/24` | ROSA Worker Node |
| ap-northeast-1c | Private Worker | `10.1.11.0/24` | ROSA Worker Node |
| ap-northeast-1d | Private Worker | `10.1.12.0/24` | ROSA Worker Node |
| ap-northeast-1a | TGW Attachment | `10.1.20.0/28` | TGW Attachment 専用 |
| ap-northeast-1c | TGW Attachment | `10.1.20.16/28` | TGW Attachment 専用 |
| ap-northeast-1d | TGW Attachment | `10.1.20.32/28` | TGW Attachment 専用 |
| ap-northeast-1a | VPC Endpoint | `10.1.30.0/28` | Interface Endpoint 用 |
| ap-northeast-1c | VPC Endpoint | `10.1.30.16/28` | Interface Endpoint 用 |
| ap-northeast-1d | VPC Endpoint | `10.1.30.32/28` | Interface Endpoint 用 |

### TGW Attachment Subnetは分離する

TGW Attachment用Subnetは、Worker Node用Subnetと分離する。

- AWS Transit Gateway設計のベストプラクティス。
- TGWとの出入口を明確化できる。
- 障害調査がしやすい。

### AWSの予約IPについて

- 各SubnetごとにAWSの予約IPが存在する。
- 例）10.0.1.0/24
  | IP | 用途 |
  | --- | --- |
  | 10.0.1.0 | ネットワークアドレス |
  | 10.0.1.1 | VPCルーター用 |
  | 10.0.1.2 | DNS用 |
  | 10.0.1.3 | 将来利用のためAWS予約 |
  | 10.0.1.255 | ブロードキャストアドレス |
- 利用可能なIP数
  - /24 = 256 IP
  - AWS予約 = 5 IP
  - 利用可能 = 251 IP

## Route Table設計

### Public Subnet Route Table

| Destination | Target |
| --- | --- |
| 10.1.0.0/16 | local |
| 0.0.0.0/0 | Internet Gateway |

### Private Worker Subnet Route Table

| Destination | Target |
| --- | --- |
| 10.1.0.0/16 | local |
| 192.168.0.0/16 | Transit Gateway |
| 0.0.0.0/0 | NAT Gateway（同一AZ） |

### TGW Attachment Subnet Route Table

| Destination | Target |
| --- | --- |
| 10.1.0.0/16 | local |

## Transit Gateway

### Attachment構成

```text
Transit Gateway
├── Direct Connect Gateway Attachment
└── ROSA VPC Attachment
```

### TGW Route Table

| Destination | Target |
| --- | --- |
| 10.1.0.0/16 | ROSA VPC Attachment |
| 192.168.0.0/16 | Direct Connect Gateway Attachment |

### Direct Connect / オンプレミス側

オンプレミス側ルーターには、ROSA VPC CIDRへのルートが必要。

| Destination | Target |
| --- | --- |
| 10.1.0.0/16 | Direct Connect |

## Gateway

### Internet Gateway

- Internet GatewayはVPCに1つアタッチする。
- Private Worker SubnetからInternet Gatewayへ直接ルーティングしない。
- NAT GatewayはPublic Subnetに配置し、Internet Gateway経由でインターネットへ通信する。

### NAT Gateway

本番レベルでは、AZごとにNAT Gatewayを配置し、各Private Worker Subnetは同一AZのNAT Gatewayへルーティングする。

- AZ障害時の影響を抑止できる。
- クロスAZ通信コストを抑えられる。
- Multi-AZ構成として自然。

## VPC Endpoint

Public Clusterであっても、AWSサービス向け通信にはVPC Endpointを使うことを推奨。

| Endpoint | 種別 | 用途 |
|---|---|---|
| S3 | Gateway Endpoint | S3 アクセス |
| ECR DKR | Interface Endpoint | コンテナイメージ Pull |

## Security Group / NACL

基本的にはSecurity Groupを中心に通信制御を行い、NACLはサブネット単位の補助的なガードレールとして利用する。

| 仕組み | 主な役割 | 適用単位 | 向いている制御 |
| --- | --- | --- | --- |
| Security Group | AWSリソース単位の仮想ファイアウォール | ENI / EC2 / LBなど | Worker Node、Load Balancer、PrivateLink Endpointなどへの許可通信 |
| NACL | Subnet境界の粗いフィルタ | Subnet | Subnet全体に対するガードレール、明示的Deny |

## DNS

オンプレミスサーバーへ名前解決でアクセスする場合は設計必要
