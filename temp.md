```
# Sealed Secrets

## 概要

- Sealed Secretsは、kubernetesのSecretを暗号化して扱うためのツール。
- Secretは`Base64エンコード（容易にデコード可能）`のため、Sealed Secretsで暗号化して中身が漏れにくくする。

## 動作イメージ

### 暗号化

- (1): 対象Secretに対してkubesealコマンド実行
- (2): Sealed Secretsコントローラーが公開鍵を利用してSecretを暗号化
- (3): 暗号化したSecretでSealed Secretsファイルを作成

### 復号化

- (1): 対象Sealed Secretsファイルをクラスタに適用
- (2): Sealed Secretsコントローラーが秘密鍵を利用してSealed Secretsを復号化
- (3): 複合化したデータを利用してSecretリソース作成

## 運用

### 鍵の更新

Sealed Secretsコントローラーが利用する鍵はデフォルトで30日ごと自動更新されるが、本環境では暗号化のメイン目的はSecretファイルをGithubに保管する + 運用負荷を減らすため、自動更新機能はは無効にする。

### スコープ

- Secretを暗号化した後、Secretの名前やNamespaceを変更可能/禁止などの設定が可能
- 設定可能なスコープ

| スコープ | Secret名変更 | Namespace変更 |
| -- | -- | -- |
| strict (default) | 不可 | 不可 |
| namespace-wide | 可能 | 不可 |
| cluster-wide | 可能 | 可能 |

- 本環境では基本`strict`にし、複数のPodやNamespaceで利用必要な場合のみ他のスコープを利用する。

### 障害対応

- 初期インストール後、鍵をバックアップし、以下に保管する。
  - S3バケット：secret/sealed-secrets/
- 障害などによりSealed Secretsが利用できなくなった場合はSealed Secretsを再インストールする。
  - 再インストール時、Sealed Secrets全体を削除すると該当CRリソース（SealedSecrets）がすべて削除されるため、全体削除は禁止
  - やむを得ず削除が必要な場合はコントローラーのみ削除する。

## インストール

- Kubeseal
  - ローカル環境でSecretの暗号化などに利用するコマンドツール
  - 各自[Releases](https://github.com/bitnami-labs/sealed-secrets/releases)から圧縮ファイルをダウンロードしてインストールする。
    - 対象ファイル：`kubeseal-<version>-linux-amd64.tar.gz`
- コントローラー
  - クラスタの中に存在し、実際暗号化/複合化を実行するリソース
  - インストール方法は2つ（マニフェスト/Helm）あるが、マニフェストの保管が不要なHelm方式を利用する。

```
# リポジトリ追加
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# リポジトリ更新
helm repo update

# 最新チャートバージョン確認
helm search repo sealed-secrets/sealed-secrets --versions

# インストール
# STG/本番環境のバージョンを合わせるため、チャートバージョン指定
# コントローラー名指定（kubesealコマンドが参照するデフォルト名指定）
# 鍵の更新を無効
helm install sealed-secrets sealed-secrets/sealed-secrets \
  -n kube-system \
  --version 2.18.0 \
  --set-string fullnameOverride=sealed-secrets-controller \
  --set-string keyrenewperiod="0"

# 確認
helm ls -n kube-system

oc get deploy,pod,cm,secret,sa -n kube-system | grep -i sealed-secrets
```

- 鍵のバックアップ

```
oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml >main.key
```

## 暗号化

```
# SecretからSealedSecretsを作成
kubeseal -f secret.yaml -w sealedsecret.yaml

# SealedSecretsに問題ないことを確認
cat sealedsecret.yaml | kubeseal --validate

# スコープを変更する場合（デフォルトは「strict」）
kubeseal --scope cluster-wide -f secret.yaml -w sealedsecret.yaml
kubeseal --scope namespace-wide -f secret.yaml -w sealedsecret.yaml
```

# VerUp

- 最新バージョンのみサポートするため、常にバージョンアップするよりはOpenshiftのバージョンアップに合わせて実施。
- リリスノートを確認し、影響調査 > 必要な対応を実施
- バージョンアップ
```
# 事前確認
helm ls -n kube-system

oc get deploy,pod,cm,secret,sa -n kube-system | grep -i sealed-secrets

# リポジトリ追加
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# リポジトリ更新
helm repo update

# 最新チャートバージョン確認
helm search repo sealed-secrets/sealed-secrets --versions

# インストール
# STG/本番環境のバージョンを合わせるため、チャートバージョン指定
# コントローラー名指定（kubesealコマンドが参照するデフォルト名指定）
# 鍵の更新を無効
helm upgrade sealed-secrets sealed-secrets/sealed-secrets \
  -n kube-system \
  --version 2.18.0 \
  --set-string fullnameOverride=sealed-secrets-controller \
  --set-string keyrenewperiod="0"

# 鍵のリストア（バージョンアップしても鍵は消えないが、念の為）
oc apply -f main.key -n kube-system

oc delete pod -n kube-system -l app.kubernetes.io/name=sealed-secrets

# 確認
helm ls -n kube-system

oc get deploy,pod,cm,secret,sa -n kube-system | grep -i sealed-secrets
```

### テスト仕様書

- 鍵を消して新規SealedSecretsを適用するとどうなる？
- 鍵を消してバックアップ鍵を適用してコントローラーを再起動せずに新規SealedSecretsを適用するとどうなる？
- コントローラーを消してHelm upgradeをすると既存Secretsに影響はないか。

---

- SealedSecrets作成
- SealedSecrets適用/Podで参照できること
- SealedSecrets削除
- 鍵のバックアップ/リストア
- CRD削除：適用済みのCRとSecretがどうなるか確認
- スコープテスト



## Link

- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Supported Versions](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#supported-versions)
- [Release Notes 01](https://github.com/bitnami-labs/sealed-secrets/releases)
- [Release Notes 02](https://github.com/bitnami-labs/sealed-secrets/blob/main/RELEASE-NOTES.md)
- [Compatibility with Kubernetes versions](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#compatibility-with-kubernetes-versions)
- [Sealed Secrets Helm](https://github.com/bitnami-labs/sealed-secrets/tree/main/helm/sealed-secrets)

```
