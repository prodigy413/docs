- [Installing the agent on Red Hat OpenShift](https://www.ibm.com/docs/en/instana-observability/1.0.305?topic=openshift-installing-agent-red-hat)
- [Release notes for Instana agent Helm chart](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-helm-chart)
- [Release notes for Instana agent operator](https://www.ibm.com/docs/en/instana-observability/1.0.309?topic=agent-operator)
- [helm-charts](https://github.com/instana/helm-charts/tree/main/instana-agent)
- [instana_v1_extended_instanaagent.yaml(For operator)](https://github.com/instana/instana-agent-operator/blob/main/config/samples/instana_v1_extended_instanaagent.yaml)

## Openshift

### Image

```
curl https://icr.io/v2/instana/agent/tags/list | jq
```

- Check

```
$ oc -n instana-agent get ds,deploy,svc,cm,secret
NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR    AGE
daemonset.apps/instana-agent   1         1         1       1            1           instana=enable   3m42s

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/instana-agent-controller-manager   1/1     1            1           3m46s
deployment.apps/instana-agent-k8sensor             3/3     3            3           3m41s

NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                 AGE
service/instana-agent            ClusterIP   172.21.57.172   <none>        42699/TCP,4317/TCP,55680/TCP,4318/TCP   3m42s
service/instana-agent-headless   ClusterIP   None            <none>        42699/TCP,4317/TCP,55680/TCP,4318/TCP   3m42s

NAME                                 DATA   AGE
configmap/instana-agent-dependents   1      3m42s
configmap/instana-agent-k8sensor     1      3m41s
configmap/instana-agent-namespaces   1      3m41s
configmap/kube-root-ca.crt           1      4m20s
configmap/manager-config             1      3m46s
configmap/openshift-service-ca.crt   1      4m20s

NAME                                            TYPE                      DATA   AGE
secret/builder-dockercfg-dcfw7                  kubernetes.io/dockercfg   1      4m20s
secret/default-dockercfg-ptlqt                  kubernetes.io/dockercfg   1      4m20s
secret/deployer-dockercfg-d8mv8                 kubernetes.io/dockercfg   1      4m20s
secret/instana-agent                            Opaque                    2      3m41s
secret/instana-agent-config                     Opaque                    5      3m42s
secret/instana-agent-dockercfg-9hdzh            kubernetes.io/dockercfg   1      3m41s
secret/instana-agent-k8sensor-dockercfg-2tslf   kubernetes.io/dockercfg   1      3m41s
secret/instana-agent-operator-dockercfg-4rw2g   kubernetes.io/dockercfg   1      3m46s
secret/sh.helm.release.v1.instana-agent.v1      helm.sh/release.v1        1      3m46s


$ oc get pods -n instana-agent -l app.kubernetes.io/component=instana-agent \
  -o custom-columns="POD:.metadata.name,IMAGE:.spec.containers[*].image,NODESELECTOR:.spec.nodeSelector"
POD                   IMAGE                          NODESELECTOR
instana-agent-mk2zp   icr.io/instana/agent:1.309.1   map[instana:enable]
instana-agent-xq2bf   icr.io/instana/agent:1.309.1   map[instana:enable]
```

### Operator

```
oc apply -f https://github.com/instana/instana-agent-operator/releases/latest/download/instana-agent-operator.yaml
oc apply -f https://github.com/instana/instana-agent-operator/releases/download/v2.2.3/instana-agent-operator.yaml
```

- instana-agent.yaml

```
apiVersion: instana.io/v1
kind: InstanaAgent
metadata:
  name: instana-agent
  namespace: instana-agent
spec:
  zone:
    name: test-zone
  cluster:
      name: test-cluster
  agent:
    key: xxxxxxx
    downloadKey: xxxxx
    endpointHost: xxxxxxx
    endpointPort: "443"
    image:
      #name: ""
      tag: "1.309.1"
    pod:
      nodeSelector:
        instana: enable
      requests:
        cpu: "0.5"
        memory: "512Mi"
      limits:
        cpu: "1.5"
        memory: "1Gi"
    env:
      INSTANA_AGENT_PROXY_HOST: "172.21.145.240"
      INSTANA_AGENT_PROXY_PORT: "3128"
      INSTANA_AGENT_PROXY_PROTOCOL: "http"
    configuration_yaml: |
      com.instana.ignore:
        arguments:
          - '/opt/batch/properties/batch.prop'
          - '/opt/batch/properties/if.prop'
          - 'com.mobit.redis2ssh.LogTransfer'
```

- values.yaml

```
agent:
  key: EbuMpFEaRIm_3jCTZ_a9ag
  endpointHost: ingress-blue-saas.instana.io
  endpointPort: 443
  image:
    tag: 1.309.1
  pod:
    nodeSelector:
      instana: enable
  env:
    INSTANA_AGENT_PROXY_HOST: "172.21.145.240"
    INSTANA_AGENT_PROXY_PORT: 3128
    INSTANA_AGENT_PROXY_PROTOCOL: "http"
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: 0.5
      memory: "1Gi"
cluster:
  name: test-cluster
zone:
  name: test-zone
```

# Lambda

<https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html>

# SCCWP

# パターンA：経営層・マネジメント向けサマリ構成

1. 本資料の目的
2. IBM Cloud Security and Compliance Center（SCC）の概要
3. Security and Compliance Center Workload Protection（SCCWP）の概要
4. SCCからSCCWPへの移行が必要な背景
   - SCCの提供終了とIBMの公式アナウンス概要
5. SCCとSCCWPの機能比較
   - CSPM機能の継承／拡張
   - 追加されるワークロード保護・脅威検知など
6. 当社IBM Cloud環境の現状整理
   - SCCでスキャン対象にしているリソース
   - 使用中のフレームワーク／ポリシー
7. 移行方針とスコープ
   - 対象アカウント／リソース範囲
   - 移行しない対象（廃止予定など）
8. 移行ロードマップ
   - 準備フェーズ
   - 検証フェーズ
   - 本番移行フェーズ
9. リスク・影響評価と対策
   - スキャン停止期間の影響
   - 誤検知／ポリシー差異のリスク
10. 移行後の運用イメージ
    - 運用体制・ロール分担（SCCWP＋IAM）
11. まとめ・決定事項／ToDo

# パターンB：技術メンバー向け詳細構成（手順・アーキ中心）

1. 目的と前提
   - 資料の対象読者
   - 対象アカウント・リージョン
2. SCCとSCCWPのアーキテクチャ概要
   - SCCの構成とデータフロー（現状）
   - SCCWPのアーキ・コンポーネント（コンソール、エージェント、ポスチャモジュール等）
3. 機能マッピング
   - SCCのCSPM機能とSCCWPポスチャ（CSPM）の対応関係
   - 追加されるEDR／CWPPなどの機能
4. SCCWPインスタンス設計
   - リソースグループ／リージョン
   - サービスプラン選定のポイント
   - マルチアカウント・マルチクラウド対応方針
5. IAM設計・アクセス制御
   - 必要なIAMロールとポリシー設計（プラットフォーム権限／サービス権限）
   - チーム定義とデータアクセス制御
6. エージェント／データソース構成
   - Kubernetes / OpenShift / VSI / PowerVS など対象プラットフォームと対応状況
   - 導入方式（Helm, Operator, スクリプトなど）
7. ポリシーとフレームワークの移行
   - SCCの既存ポリシー棚卸し
   - SCCWPでの標準フレームワーク（FS Cloud, DORA, PCI, CIS など）の活用方針
   - カスタムポリシー移行手順
8. スキャン設定・アラート設計
   - スキャンスケジュール／対象スコープ
   - 通知連携（メール、Webhook、SIEMなど）
9. 移行ステップ詳細
   - ① SCCWPインスタンス構築
   - ② ポリシー・フレームワーク設定
   - ③ テストアカウントでのスキャン検証
   - ④ 本番アカウントへの適用
   - ⑤ SCC側スキャン停止とインスタンス削除方針
10. 運用・保守設計
    - バージョンアップ／エージェント更新ポリシー
    - 監査対応・レポート出力方法
11. 今後の拡張案
    - マルチクラウド拡張
    - 他サービス（例：DSBなど）との連携


# パターンC：コンプライアンス／ガバナンス中心構成

1. 背景：クラウドセキュリティ姿勢管理（CSPM）の重要性
   - 規制要件・社内セキュリティポリシーとの関係
2. IBM Cloud SCCの役割（これまで）
   - 利用中のフレームワーク（例：FS Cloud, PCI 等）
   - 運用上の課題（あれば）
3. SCCWPへの移行方針
   - IBM公式方針とSCCの役割変更
   - 当社としての移行の目的（可視性向上、運用負荷軽減など）
4. SCCWPのコンプライアンス機能概要
   - マルチクラウド／ハイブリッドへの対応
   - 各種標準フレームワーク（FS Cloud, DORA, CIS, NIST 等）
5. 当社コンプライアンス要件とマッピング
   - 社内セキュリティ基準とSCCWPコントロールの対応表
   - 必要なカスタムポリシー
6. 運用プロセスの再設計
   - ポリシー策定・承認プロセス
   - 違反検知時のエスカレーションフロー
   - 定期レポートと経営報告
7. 移行プロジェクト計画
   - ステークホルダーと役割
   - マイルストーン（設計・PoC・本番展開・SCC廃止）
8. リスク評価とコントロール
   - 移行期間中の二重運用
   - ポリシー差異による検知漏れ・誤検知
9. 監査・証跡管理
   - 監査ログ・レポートの取得方法
   - 監査対応時の説明資料に使える画面・レポート例
10. まとめ
    - 移行により期待されるコンプライアンス強化ポイント
    - 今後の課題とフォローアップ
