```
# Status Checker

XX環境のOpenshift監視ツールに障害発生または停止した場合に備え、定期的にクラスタ上、リソースのステータスを確認するツールを作成する。

## 監視対象と確認ポイント

監視対象と確認ポイントは以下手順を確認する。
※Sorryページ監視は対象外
[xx](xx)

## 全体構成

本構成では、ROKS Cluster上にInfraツール専用のNamespaceを作成し、そのNamespace内でステータス確認用のCronJobを運用する。<br>
![status-checker_01.png](./images/status-checker_01.png)

- CronJobは1時間ごとにPython Scriptを実行し、対象システムのステータス確認を行う。  
- スクリプトの実行結果は、コンテナ内の`/data`ディレクトリに出力する。
- `/data`ディレクトリはPVとしてマウントされて、PVのバックエンドにはIBM Cloud Object Storageを利用する。  
- これにより、CronJobの実行結果ファイルをObject Storage上に保管し、必要に応じて簡単にダウンロードできる構成とする。

## コンポーネント

### マニフェスト構成

- ClusterRole
  - CronJob内のスクリプトを実行できる権限を設定する。
- ClusterRoleBinding
  - ClusterRoleとCronJobのServiceAccountと紐づく
- ServiceAccount
  - CronJob用ServiceAccount
- CronJob
  - 定期的にステータスを確認し、レポートを作成する。
- Secret
  - イメージプール用認証情報を設定する。
  - IBM Object Storage用Service Credentialを設定する。
- PersistentVolumeClaim
  - レポート保管用PVを作成する。

### イメージ

- Redhatの公式 + 最新のPythonイメージを利用
- [Red Hat Ecosystem Catalog - Containers](https://catalog.redhat.com/en/search?searchType=Containers)
- 以下検索する。
  - 検索キーワード：`ubi10 python 3.14 minimal`<br>
  ![redhat_image_01.png](./images/redhat_image_01.png)
- 検索結果をクリックする。<br>
![redhat_image_02.png](./images/redhat_image_02.png)
- イメージの参照先をDockerfileに設定<br>
![redhat_image_03.png](./images/redhat_image_03.png)

```Dockerfile
FROM registry.access.redhat.com/ubi10/python-314-minimal:10.2-1779887616
..........
..........
```

- イメージにインストールしたいOCコマンドのバージョンをDockerfileに設定<
```Dockerfile
..........
ARG OC_VERSION=4.xx.xx
..........
```

### Object Storage

- ステータス確認スクリプトの実行結果を保管するため、Object Storageを利用する。
- 実行結果ファイルはBucketに保存し、30日経過後に自動削除する。
- Object Storageへの書き込みには、Writer権限の資格情報を利用する。
- S3互換APIでアクセスするため、HMAC認証を有効化する。

## 手順

- 必要コマンド
  - ibmcloud
  - terraform
  - oc
  - docker
  - jq

### イメージビルド

- ICRのNamespace作成

```
# ICRにログイン
ibmcloud cr login

# ICRのリージョンを日本に変更
ibmcloud cr region-set ap-north

# ICRのNamespaceを確認
ibmcloud cr namespaces

# MCK用Namespaceを追加
ibmcloud cr namespace-add obi-infra

# ICRのNamespaceを確認
ibmcloud cr namespaces
```

- ビルド
```
docker build -t prodigy413/status-checker:1.0 .
docker push prodigy413/status-checker:1.0

# イメージビルド
docker build -t jp.icr.io/obi-infra/status-checker:1.0 .

# イメージ確認
docker images

# イメージアップロード
docker push jp.icr.io/obi-infra/status-checker:1.0

# ICRでイメージ確認
ibmcloud cr images --restrict obi-infra
```

### Object Storage作成

- Object Storage作成
  - TerraformコードでObject Storageを作成
```
# 初期化
terraform init

# コードチェック
terraform validate

# 差分チェック
terraform plan

# Object Storage作成
terraform apply

# カギ情報確認
terraform output -json credential | \
jq '{
    "access-key": .["cos_hmac_keys.access_key_id"],
    "secret-key": .["cos_hmac_keys.secret_access_key"]
}'
```

- Secret作成

```
# CronJobマニフェストがあるディレクトリへ移動
cd yaml

# 上記で確認したカギ情報でSecrets作成
oc create secret generic cos-write-access \
  --type ibm/ibmc-s3fs \
  --from-literal=access-key=dde74a897b024438afad35f6b126d613 \
  --from-literal=secret-key=d9ec2b0c7d8906187f8461a39b0c90a7eed64859577e85e8 \
  --dry-run=client \
  -o yaml \
  -n infra \
| oc label --local -f - app=status-checker -o yaml \
| sed '/^[[:space:]]*creationTimestamp: null$/d' \
> object-storage-secrets.yaml

```

### CronJob作成

- CronJob作成

```
# CronJobマニフェストがあるディレクトリへ移動
cd yaml

# Infra用Namespace作成
oc new-project infra

# Namespace移動
oc project infra

# ImagePullSecret作成
oc get secrets all-icr-io -n default -oyaml > all-icr-io.yaml

# 以下削除
- annotations
- creationTimestamp
- resourceVersion
- uid
# namespaceをinfraに変更

# リソースがないことを確認
oc diff -f ./

# CronJob作成
oc apply -f ./

# ImagePullSecret確認
oc get secrets

# CronJobリソース確認
oc get clusterrole,clusterrolebinding,cronjob,sa,secret,pvc -l app=status-checker

# PV確認
oc get pv | grep status-checker-pvc
```

- Job実行確認

```
# CronJob実行確認
oc get pod

# ログ確認
oc logs status-checker-29664622-8kgll
```

- レポート確認

IBM Cloud > [インフラストラクチャー] > [ストレージ] > [Object storage]

[インスタンス] > インスタンス名 > バケット名

## 作業フォルダ

```
