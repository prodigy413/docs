# Kubernetes バージョンアップ

## バージョンアップによるAPIの変更

- 参照リンク<br>[Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide)<br>[CHANGELOG](https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG)

<table>
  <tr>
    <th>k8s Ver</th>
    <th>項目</th>
    <th>バージョンアップ前</th>
    <th>バージョンアップ後</th>
    <th>備考</th>
  </tr>
  <tr>
    <td rowspan="7">1.25</td>
    <td>CronJob</td>
    <td>batch/v1beta1</td>
    <td>batch/v1</td>
    <td>-</td>
  </tr>
  <tr>
    <td>EndpointSlice</td>
    <td>discovery.k8s.io/v1beta1</td>
    <td>discovery.k8s.io/v1</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#endpointslice-v125">Link</a></td>
  </tr>
  <tr>
    <td>Event</td>
    <td>events.k8s.io/v1beta1</td>
    <td>events.k8s.io/v1</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#event-v125">Link</a></td>
  </tr>
  <tr>
    <td>HorizontalPodAutoscaler</td>
    <td>autoscaling/v2beta1</td>
    <td>autoscaling/v2</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#horizontalpodautoscaler-v125">Link</a></td>
  </tr>
  <tr>
    <td>PodDisruptionBudget</td>
    <td>policy/v1beta1</td>
    <td>policy/v1</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#poddisruptionbudget-v125">Link</a></td>
  </tr>
  <tr>
    <td>PodSecurityPolicy</td>
    <td>policy/v1beta1</td>
    <td>使用廃止</td>
    <td>-</td>
  </tr>
  <tr>
    <td>RuntimeClass</td>
    <td>node.k8s.io/v1beta1</td>
    <td>node.k8s.io/v1</td>
    <td>-</td>
  </tr>
  <tr>
    <td rowspan="2">1.26</td>
    <td>Flow control resources</td>
    <td>flowcontrol.apiserver.k8s.io/v1beta1</td>
    <td>flowcontrol.apiserver.k8s.io/v1beta2</td>
    <td>-</td>
  </tr>
  <tr>
    <td>HorizontalPodAutoscaler</td>
    <td>autoscaling/v2beta2</td>
    <td>autoscaling/v2</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#horizontalpodautoscaler-v126">Link</a></td>
  </tr>
  <tr>
    <td>1.27</td>
    <td>CSIStorageCapacity</td>
    <td>storage.k8s.io/v1beta1</td>
    <td>storage.k8s.io/v1</td>
    <td>-</td>
  </tr>
  <tr>
    <td>1.29</td>
    <td>Flow control resources</td>
    <td>flowcontrol.apiserver.k8s.io/v1beta2</td>
    <td>flowcontrol.apiserver.k8s.io/v1<br>flowcontrol.apiserver.k8s.io/v1beta3</td>
    <td>詳細<a href="https://kubernetes.io/docs/reference/using-api/deprecation-guide/#flowcontrol-resources-v129">Link</a></td>
  </tr>
</table>

## IKS(IBM Cloud Kubernetes Service)

IBMサイトで各バージョンごとの対応必要個所を提供している。

> [!NOTE]
> IBMのマネージドサービス関連のアップデートは無視すること。

- [1.25](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_125#prep-up-125)
- [1.26](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_126#prep-up-126)
- [1.27](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_127#prep-up-127)
- [1.28](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_128#prep-up-128)
- [1.29](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_129#prep-up-129)

## Ncloud Kubernetes Service

> [!NOTE]
> NKS上のリソースをバージョンアップするわけではないため、リンクのみ書いておく。

[Ncloud Kubernetes Service のリリースノート](https://guide.ncloud-docs.com/docs/ja/k8s-k8srelease)

# その他のバージョンアップ

## Nginx Ingress Controller

### v1.8.0

- [v1.8.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.8.0)
- 該当ページの`Important Changes:`を参照
  - path typesを検証する。 => [strict-validate-path-type](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#strict-validate-path-type) 参照
  - イメージをAlpine 3.18にアップグレード。
  - プロジェクト名を反映するようにドキュメントを更新する。

### v1.9.0

- [v1.9.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.9.0)
- 該当ページの`Some important updates to consider for testing:`を参照
  - デフォルトでuser snippetsを無効にする。
  - ベースコンテナからcurlを削除する。
  - annotationの検証を実装する。

### v1.10.0
- [v1.10.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.10.0)
- 該当ページの`Breaking changes`を参照
  - このバージョンはchrootイメージをサポートしていません。これは将来のマイナーパッチリリースで修正される予定です。
  - このバージョンではOpentracingとzipkinモジュールが削除され、このリリースではOpentelemetryのみがサポートされています。
  - このバージョンではPodSecurityPolicyのサポートが終了しました。
  - このバージョンでは、GeoIP(レガシー)のサポートが終了しました。GeoIP2のみがサポートされています。

# 作業の流れ

- バージョンアップ対象の洗い出し<br>
まだ現在稼働中のk8s環境を確認していないため、要確認。
- バージョンアップによる変更などを確認し、チェックリスト化
- チェックリストの各項目の対応
- 変更後、テスト
- リリース
