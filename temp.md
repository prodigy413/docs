```
# Instana バージョンアップ

### 影響確認

- Operatorの変更履歴を確認
  - [Release notes for Instana agent operator](https://www.ibm.com/docs/en/instana-observability/1.0.310?topic=agent-operator)
  - [Release (Github)](https://github.com/instana/instana-agent-operator/releases)
- Bootstrapの変更履歴を確認
  - [Release notes for Instana agent bootstrap](https://www.ibm.com/docs/en/instana-observability/1.0.310?topic=agent-bootstrap-also-includes-assembly-related-information)
- Agentは自動更新されるため、参照程度で良い。
  - [Agent Latest Release Info](https://github.com/instana/agent-updates/tags)

### バージョンアップ関連バージョンの種類

- Change version:<br>IBM Instana Observabilityのバージョン
- Agent bundle:<br>Agent本体のバージョン
- Agent Operator:<br>Agent operatorのバージョン
- Agent bootstrap:<br>Agent bootstrapのバージョン

※`Change version` = `イメージのタグバージョン`であるため、これからInstanaバージョンはChange versionを利用する。

### バージョンアップ対象

- Operator
- Image(bootstrap)

### yaml構成

- instana-agent.yaml:<br>InstanaAgent設定を記載する。
- instana-agent-key.yaml:<br>Agentキー用Secretsリソース。
  - AgentキーはInstanaAgent設定に記載も可能だが、ベタ書きは良くないので分離してSecrets化して管理する。
  - 一度作成しておけばバージョンアップ時に気にしなくて良い。

### Tag

- 現状：tagはlatestを利用している。
- latestのままだとSTG環境と本番環境のバージョンアップ時期が結構離れている場合は各環境で異なるバージョンのイメージを利用する恐れがある。<br>
→ tagはlatestからバージョン指定に変更する。
- イメージの最新タグ確認
```
curl https://icr.io/v2/instana/agent/tags/list | jq
curl https://icr.io/v2/instana/k8sensor/tags/list | jq

# Container Registryのregionをglobalに設定
ibmcloud cr region-set global

# Agentの最新タグのDigestを確認
ibmcloud cr images --restrict instana/agent \
--format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep latest

icr.io/instana/agent:latest 1f7b5c7393d6
icr.io/instana/agent:latest-amd64-dynamic b9f1424eca7c
icr.io/instana/agent:latest-amd64-dynamic-j9 add3294ef931
icr.io/instana/agent:latest-arm64-dynamic ba11f8f5f99d
icr.io/instana/agent:latest-arm64-dynamic-j9 40d114a7a722
icr.io/instana/agent:latest-j9 80c2313a42a3
icr.io/instana/agent:latest-ppc64le-dynamic 2c78a0690a43
icr.io/instana/agent:latest-s390x-dynamic b4ac9855b5a7

# Digestを利用して最新タグを確認
ibmcloud cr images --restrict instana/agent \
--format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep 1f7b5c7393d6

icr.io/instana/agent:1.310.7 1f7b5c7393d6
icr.io/instana/agent:latest 1f7b5c7393d6

# k8sensorの最新タグのDigestを確認
ibmcloud cr images --restrict instana/k8sensor \
--format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep latest

icr.io/instana/k8sensor:latest ee68feda1a7e
icr.io/instana/k8sensor:testlatest 45b0ce404270

# Digestを利用して最新タグを確認
ibmcloud cr images --restrict instana/k8sensor \
--format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep ee68feda1a7e

icr.io/instana/k8sensor:1.2.13 ee68feda1a7e
icr.io/instana/k8sensor:latest ee68feda1a7e

```

### バージョンアップ方法

Agentのインストール/バージョンアップ方法は2つ(operator/helm)あるが、Openshift環境での推奨であるOperator方式を利用する。

# 手順

### AgentキーのSecrets化

```
oc create secret generic instana-agent-key \
--from-literal=key=<Agentキー> \
--dry-run=client -n instana-agent -oyaml \
> instana-agent-key.yaml

# "creationTimestamp: null"は削除

oc create secret generic instana-agent-key \
--from-literal=key=_j7q6jiRQsqAGtQptkd2gA \
--dry-run=client -n instana-agent -oyaml \
> instana-agent-key.yaml
```

### Instana バージョンアップ

### 事前作業

- 作業環境：WSL (Ubuntu)

```
# ログ取得開始
date ; script /tmp/2026xxxx_instana_agent_verup_stg.log

# 作業ディレクトリへ移動
cd /home/obi/test/2026xxxx

# IBM Cloudにログイン
ibmcloud login -g stg

# Openshiftにログイン
oc login -u apikey -p $IBMCLOUD_API_KEY --server https://c100-e.jp-tok.containers.cloud.ibm.com:31924

# 環境確認(STG)
oc get ns application-stg-1
```

### 既存Instana削除

```
# Instanaのリソース確認
date ; oc get -f instana-configuration.yaml ; oc get pod -n instana-agent

# 削除
oc delete -f instana-configuration.yaml

# Instanaのリソースが存在しないことを確認
oc get -f instana-configuration.yaml ; oc get pod -n instana-agent
```

### バージョンアップ

```
# Namespace 作成とポリシー設定
oc new-project instana-agent
oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
oc adm policy add-scc-to-user anyuid -z instana-agent-remote -n instana-agent

# Operator インストール
<フォーマット>
oc apply -f https://github.com/instana/instana-agent-operator/releases/download/<Operatorバージョン>/instana-agent-operator.yaml

<実際のコマンド>
date ; oc apply -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.3/instana-agent-operator.yaml

# Projectをinstana-agentに切り替え
oc project instana-agent

# Operator 確認
oc get deploy,pod

# ログ確認（エラーがないこと）
oc logs deployments/instana-agent-controller-manager

# Secrets 適用
oc apply -f instana-agent-key.yaml

# Secrets 確認
oc get secrets

# InstanaAgent 適用
oc apply -f instana-agent.yaml
```

### バージョンアップ後、確認

- リソース確認
  - Agentのリソース確認<br>Daemonsetの以下項目がすべて`6`であること
    - DESIRED
    - CURRENT
    - READY
    - UP-TO-DATE
    - AVAILABLE
  - PodのSTATUSがすべて`Running`であること
  ```
  oc get deploy,ds,pod
  ```
- 各設定確認
```
# イメージのタグが指定したタグと一致すること
oc get pods -o custom-columns='POD:.metadata.name,IMAGES:.spec.containers[*].image'

# Agentのリソース設定が指定した値と一致すること
oc get pods \
  -o custom-columns='POD:.metadata.name,REQ_CPU:.spec.containers[*].resources.requests.cpu,REQ_MEM:.spec.containers[*].resources.requests.memory,LIM_CPU:.spec.containers[*].resources.limits.cpu,LIM_MEM:.spec.containers[*].resources.limits.memory'
```

- ログ確認（エラーがないこと）
```
oc logs deployments/instana-agent-k8sensor
oc logs ds/instana-agent
```

### IBM Instanaの確認

IBM Instana画面を開き、現在のパフォーマンス情報を確認できることを確認

# 以降バージョンアップ手順

```
# Instanaリソース確認
oc get deploy,ds,pod

# Operator バージョンアップ
<フォーマット>
oc apply -f https://github.com/instana/instana-agent-operator/releases/download/<Operatorバージョン>/instana-agent-operator.yaml

<実際のコマンド>
oc apply -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.4/instana-agent-operator.yaml

# コントローラーの再起動が完了し、PodのSTATUSが「Running」であること
```




# CR(Custom Resource)設定ファイル説明

- Instana OperatorはCR(InstanaAgent)設定を参照してAgentを作成する。<br>
ファイルに記載されていないパラメータにはデフォルト値が適用される。

```yaml
apiVersion: instana.io/v1
kind: InstanaAgent
metadata:
  name: instana-agent # Agent名
  namespace: instana-agent # Namespace名
spec:
  zone:
    name: xxx # ゾーン名（※STGと本番値が異なる。）
  cluster:
      name: xxx # クラスタ名（※STGと本番値が異なる。）
  agent:
    keysSecret: instana-agent-key # Agentキーを持っているSecrets名
    endpointHost: ingress-blue-saas.instana.io # InstataのendpointのURL
    endpointPort: "443" # Instataのendpointのポート
    image:
      tag: "xxx" # Agentイメージのタグ名
    pod:
      nodeSelector: # Agentが稼働するノード選択（※STG環境のみ）
        instana: enable # このラベルを持つノードのみ上でAgentは稼働する
      requests: # Agent稼働に必要な最低限のリソース
        cpu: "0.5"
        memory: "512Mi"
      limits: # Agentが利用可能な最大リソース
        cpu: "1.5"
        memory: "1Gi"
    env:
      INSTANA_AGENT_PROXY_HOST: "xxx.xxx.xxx.xxx" # Agentが利用するプロキシのIP（※STGと本番値が異なる。）
      INSTANA_AGENT_PROXY_PORT: "3128" # Agentが利用するプロキシのポート
      INSTANA_AGENT_PROXY_PROTOCOL: "http" # Agentが利用するプロキシのプロトコル
    configuration_yaml: |
      com.instana.ignore:
        arguments:
          - '/opt/batch/properties/batch.prop'
          - '/opt/batch/properties/if.prop'
          - 'com.mobit.redis2ssh.LogTransfer'
  k8s_sensor:
    image:
      tag: "xxx" # k8sensorイメージのタグ名
```

- [Environment variables](https://www.ibm.com/docs/en/instana-observability/1.0.310?topic=references-environment-variables)




oc exec -it ingtana-agent -- bash

cat /opt/instana/agent/etc/instana/com.instana.agent.main.config.UpdateManager.cfg

# cat /opt/instana/agent/etc/instana/com.instana.agent.main.config.UpdateManager.cfg
# Instana Update Manager configuration.
# AUTO for automatic updates with given schedule. OFF for no automatic updates.
mode = AUTO
# DAY for daily, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
every = DAY
# Time is hh:mm in 24 hours format.
at = 4:50
# Extend default jitter to -45 / +45 minutes to spread update load on backend infrastructure
jitter = 90

cat /opt/instana/agent/data/log/agent.log | grep -i update

Operatorのinstanaagentに記載したconfigurationは異なるディレクトリにマウントされる。
設定自体はconfigmapではなくsecrets(instana-agent-config)に保管される。
# cat /opt/instana/agent/etc/instana-config-yml/configuration.yaml 
com.instana.ignore:
  arguments:






- 現在：
  - 公式イメージ作成用Dockerfileを利用し、ゼロベースのビルドをしている。
  - 鍵も直接作成して運用。
  - OSも固定して運用。
  - バージョンアップなど運用負荷増加
- 改善
  - 特別要件がないかぎりゼロビルドは不要で公式イメージを利用する。<br>→ 鍵の管理もOSの世代管理も不要
  - 必要な設定/PKGを追加してビルドするだけで良い。
---
- 公式 nginx イメージは “Docker Official Image” として提供・運用されているNGINX 側の Docker Maintainers がメンテしていて、利用方法や前提が Docker Hub にまとまっている。自前で Dockerfile を抱えるより「責任の境界」が明確。 
- いま使っている “ベースイメージの Dockerfile を直接コピって運用” は、実質的に「公式イメージを自分たちで再実装」になっている
公式側の Dockerfile は「生成物なので直接編集しないで」と明記されており、追従の手間が出る前提。 
- キー（GPG/署名）を自前で作って管理する必要は基本ない<br>
公式の Debian 系 Dockerfile では、NGINX の公開鍵を取得し keyring に入れ、signed-by で apt リポジトリ検証をしている。つまり「公式の信頼の鎖」を使う設計。アプリ側が別の鍵を抱えると、漏洩・ローテーション・監査対応のコストとリスクが増える。 
- 供給網（サプライチェーン）的に “自前鍵を焼き込む/保持する” は避けたい<br>
公式イメージは透明性・保守・検証の仕組みが整理されている一方、独自ビルドで秘密鍵まで扱うと「作る人しか分からない暗黙運用」になりやすい。 
- 公式イメージをベースにすれば、アプリ側のカスタムは最小差分（設定・静的ファイル・追加ツール）だけにできる<br>
典型は FROM nginx:<tag> にして COPY で設定を差し替える。必要なら自分たちの設定だけを管理すればよく、OSパッケージングや鍵まわりの保守から解放される。 
- アップデート追従がシンプルになる（やることが “ベース更新＋再ビルド” に収束）<br>
自前 Dockerfile だと「Debian 世代更新」「鍵の追加/変更」「ビルド手順変更」まで全部追う必要がある。公式をベースにすると、こちらはタグ/ダイジェスト固定と定期リビルド運用に寄せられる。 
- “同じことをやるなら公式を使う” が標準的で、説明責任も果たしやすい<br>
「なぜ独自に鍵と Dockerfile を持つのか？」より、「公式をベースに必要な設定だけ追加する」の方が監査・引継ぎ・セキュリティレビューで通りやすい。 
- 継続的なセキュリティパッチの自動適用<br>
公式イメージは、脆弱性（CVE）が発見されるたびにメンテナンスチームによって更新されます。FROM nginx:latest（または特定バージョン）を利用していれば、ベースイメージを更新するだけで最新のセキュリティ修正を反映できます。Dockerfileを直接コピーしている場合、本家側の修正を自分たちで検知し、手動でコードを書き換えない限り、脆弱性が放置されるリスクがあります。
- 署名と検証プロセスの委譲<br>
提示されたDockerfile内で行っているGPGキーのインポートや署名検証は、公式イメージのビルド時に既に完了しています。自前でこれを行うと、キーの有効期限管理やインポート失敗時の対応など、アプリの本質とは無関係な「インフラ維持コスト」が発生してしまいます。公式イメージを使えば、信頼されたビルド済みバイナリをそのまま利用できます。
- ビルド時間の短縮とレイヤーの最適化<br>
公式イメージはDocker Hub上のビルド済みレイヤーとして提供されています。自前で全工程をビルドすると、apt-get install などの時間のかかる処理が毎回走ることになり、CI/CDパイプライン全体の速度を低下させます。また、他のチームも同じ公式イメージを使っていれば、ホストマシン上でのレイヤーキャッシュが共有され、ディスク容量の節約にも繋がります。
- 「責任共有モデル」による関心の分離<br>
「OSやミドルウェアのインストール（土台）」はNginx公式が責任を持ち、「その上の設定やコンテンツ（アプリ）」をアプリチームが担当するという、役割の明確化が可能です。Dockerfileを直接持つということは、Nginxのインストール手順そのものに責任を持つことになり、ミドルウェアの深い専門知識が求められ続けることになります。
- 業界標準への準拠（可読性の向上） 多くのエンジニアにとって FROM nginx:xxx は「標準的なNginx環境」であると一目で理解できます。100行近いベースイメージの定義がDockerfileに混ざっていると、どこからが独自のカスタマイズなのか判別しにくくなり、コードの可読性とメンテナンス性が著しく低下します。
- ベースOS（Debian/Alpine 等）の選定・世代管理をアプリ側が背負うことになる<br>
公式 nginx イメージは Debian slim などのOSイメージを前提に組み立てており（例：FROM debian:...-slim）、OSの世代を何にするかがビルド成果物を決めます。これを自分たちのDockerfileとして固定してしまうと、OSの世代更新（例：bullseye→bookworm）までアプリ側の作業になります。 
- OSの脆弱性対応は「apt upgrade」ではなく、基本は“ベース更新→再ビルド”運用になる<br>
Dockerは「イメージはスナップショット」なので、依存（＝ベースOS含む）を最新化するには、更新されたベースイメージを取り直して再ビルドするのが前提です（--pull 推奨）。Dockerfileを自前で抱えるほど、この再ビルド運用（頻度・検証・リリース手順）をアプリ側で設計・継続する必要が出ます。 
- OSレイヤの更新計画（頻度・検証・ロールバック）を“チームで運用”する必要が出る<br>
「いつOSのセキュリティ更新を取り込むか」「スキャンで検出されたCVEをどのSLAで潰すか」「更新で壊れた時の戻し方」までアプリ側の定常運用になります。公式イメージをベースにしておけば、こちらは **“ベースタグ更新＋再ビルド”**に寄せられ、差分を小さくできます。 
- apt リポジトリ/証明書/鍵回りの面倒も “OS運用の一部” として持つことになる<br>
公式のDebian系Dockerfileでは apt-get を使い、鍵や証明書（ca-certificates等）を含む前提でパッケージ導入をしています。これを自前運用にすると「鍵の取得方式変更」「証明書ストア周り」「リポジトリ設定」の追従まで自分たちの保守範囲になります。 
- OSパッケージの脆弱性管理（CVE対応）の長期化<br>
Dockerfile内に apt-get install などの記述がある場合、インストールされるOSパッケージのバージョン管理責任はアプリチームに移ります。セキュリティスキャン（Trivyなど）でOSレベルの脆弱性が検知された際、公式イメージなら「タグを更新するだけ」で済むところを、自前管理の場合は「どのパッケージをどう更新すべきか、既存のミドルウェアと競合しないか」を自分たちで調査・修正しなければなりません。
- OS自体のライフサイクル（EOL）への追従<br>
ベースOS（例：Debian 11から12へなど）のサポートが終了する際、Dockerfileを直接管理していると、OSのアップグレードに伴うパッケージリポジトリの変更や、インストールコマンドの挙動の変化に直接対応する必要があります。公式イメージを利用していれば、NginxチームがOSの移行検証を済ませた状態で新しいイメージを提供してくれるため、チームの移行コストを最小限に抑えられます。
- ライブラリの依存関係トラブルの回避<br>
Dockerfile内で行われている複雑な依存関係の解決（特定のバージョンのOpenSSLやglibcの要求など）は、OSのアップデートによって容易に壊れることがあります。公式イメージは、そのOS環境でNginxが最適かつ安定して動くことが保証された「完成品」です。Dockerfileを自前で持つことは、この「安定性の検証作業」をすべて肩代わりすることを意味します。
- ビルド環境の「冪等性（べきとうせい）」の喪失<br>
apt-get update を含むDockerfileを自前でビルドし続けると、ビルドを実行したタイミングによってインストールされるパッケージの微細なバージョンが異なってしまうことがあります。これにより、「開発環境では動いたが、本番のビルドではOS側の仕様変更でエラーになる」という、追跡の難しい問題が発生するリスクを抱えることになります。







```

```powershell
# Set-ExecutionPolicy Bypass -Scope Process
# Get-ExecutionPolicy
# aws s3 sync s3://>bucket_name> C:\Users\obi\test\20251220_manual_download
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Get-Date ; aws s3 sync s3://>bucket_name> .\ | Tee-Object .\out.log ; Get-Date
# Start-Transcript ..\out.log ; Get-Date ; aws s3 sync s3://>bucket_name> .\ ; Get-Date ; Stop-Transcript
# =================================================================
# AWS S3 Download & Zip Compression Script
# =================================================================

Start-Transcript .\out.log | Out-Null
# --- 1. 設定ファイルの読み込み ---
$configPath = Join-Path $PSScriptRoot "config.json"

if (!(Test-Path $configPath)) {
    Write-Error "設定ファイルが見つかりません: $configPath"
    return
}

# 今日の日付を取得
$dateStr = Get-Date -Format "yyyyMMdd"

# JSONを読み込んでオブジェクトに変換
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

$s3Uri              = "s3://$($config.Bucket)"  # S3のパス（末尾に/を推奨）
$localDownloadPath  = Join-Path $config.LocalPath $dateStr       # ダウンロード先
$zipDestinationPath = Join-Path $config.LocalPath "zip"     # 作成するZipのパス
$zipFile = Join-Path $zipDestinationPath "$($config.Bucket).zip"

## --- 設定項目 ---
#$s3Uri = "s3://>bucket_name>/"  # S3のパス（末尾に/を推奨）
#$localDownloadPath = "C:\Users\obi\test\20251220"         # ダウンロード先
#$zipDestinationPath = "C:\Users\obi\test\Backup.zip"      # 作成するZipのパス

# --- 環境準備 ---
# 日本語文字化け対策
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# .NETの圧縮ライブラリをロード（PS5で大容量Zipを扱うために必要）
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 各パスが既に存在するかチェック
$paths = @($zipFile, $localDownloadPath, $zipDestinationPath)

foreach ($p in $paths) {
    if (Test-Path $p) {
    Write-Error "エラー: [$p] が既に存在します。"
    return
    }
}

while ($true) {

    $answer = (Read-Host "対象バケット名で$($config.Bucket)で正しいですか？ (Y/N)")

    if ($answer -eq "y") {
        break
    }
    elseif ($answer -eq "n") {
        Write-Host "--- スクリプトを終了します ---" -ForegroundColor Red
        exit
    }
    else {
        Write-Host "無効な入力です。" -ForegroundColor Yellow
    }
}

# ディレクトリ作成
New-Item -ItemType Directory -Path $localDownloadPath -Force | Out-Null
New-Item -ItemType Directory -Path $zipDestinationPath -Force | Out-Null

try {
    # 1. AWS S3からダウンロード
    Write-Host "--- S3からダウンロードを開始します ---" -ForegroundColor Cyan

    Get-Date
    # syncコマンドは差分転送や再試行に強いため採用
    aws s3 sync $s3Uri $localDownloadPath --no-progress 2>&1
    Get-Date

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLIでのダウンロードに失敗しました。"
    }

    # 2. Zip圧縮
    Write-Host "--- 圧縮を開始します ---" -ForegroundColor Cyan
    
    # [System.IO.Compression.ZipFile]::CreateFromDirectory(元フォルダ, 保存先, 圧縮レベル, ディレクトリ名を含むか, エンコーディング)
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    $includeBaseDirectory = $false
    $encoding = [System.Text.Encoding]::GetEncoding("UTF-8")

    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $localDownloadPath, 
        $zipFile, 
        $compressionLevel, 
        $includeBaseDirectory, 
        $encoding
    )

    Write-Host "--- 完了しました ---" -ForegroundColor Green
    Write-Host "保存先: $zipFile"
    Write-Host "X:に圧縮ファイルを保管してください。"
    Write-Host "作業依頼者へ完了メールを送信してください。"    

    $mail = @"
XXX様

お世話になっております。XXです。

作業が完了しました。

以上、よろしくお願いいたします。
"@

Write-Host $mail
}
catch {
    Write-Error "エラーが発生しました: $_"
}

Stop-Transcript | Out-Null

```
