現在IBM CloudのClassic環境でOpenshiftを運用中だが、Classic環境ではOpenshiftのサポートが終了する噂があり、時期コンテナ基盤の選定を検討している。

## IBM Cloud VPC ROKS (Red Hat OpenShift on IBM Cloud)

現代のIBM Cloudにおける推奨構成です。

### メリット:

- 既存Openshift上の設定をそのまま利用可能。
- IBM Cloud VPCの最新機能を活用できる。

### デメリット:

- 既存Cloud基盤設定を利用できないため、VPCなど設計・構築が必要。
- OpenShiftのライセンス料が含まれるため、IKSと比較して高価。

## IBM Cloud Classic IKS (IBM Kubernetes Service)

IBM Cloudの従来型インフラ上で動く標準Kubernetesです。

### メリット:

- Classicインフラ上の既存ネットワークや資産を活用しやすい。> 移行コストが低い。
- OpenShiftようなライセンスが不要なため、費用が抑えられる。
- Openshiftに比べて設計・運用の自由度が圧倒的に高い。

### デメリット:

- IBMの投資はVPC側にシフトしていて、新機能の対応が遅れる、または非対応になる傾向。
- 構築負荷: Ingressなどの基本コンポーネントを最初からセットアップする必要がある。

## AWS ROSA HCP (Red Hat OpenShift Service on AWS - Hosted Control Plane)

AWS上で提供される、Red HatとAWSの共同マネージドOpenShiftです。

### メリット:

- 既存Openshift上の設定をそのまま利用可能。
- Red HatのSREが24時間365日体制でクラスタを監視・運用。
- AWSの豊富なサービスと強力に連携可能。
- 豊富なサポートとナレッジを活用可能。
- コードを利用したインフラ構築・運用が可能。

### デメリット:

- ゼロベースの設計と構築が必要。
- OpenShiftのライセンス料と運用料などが含まれるため、EKSと比較して高価。

## AWS EKS (Elastic Kubernetes Service)

クラウド市場で最も広く使われているマネージドK8sです。

### メリット:

- OpenShiftようなライセンスが不要なため、費用が抑えられる。
- Openshiftに比べて設計・運用の自由度が圧倒的に高い。
- AWSの豊富なサービスと強力に連携可能。
- 豊富なサポートとナレッジを活用可能。
- コードを利用したインフラ構築・運用が可能。

### デメリット:

- ゼロベースの設計と構築が必要。
- 構築負荷: Ingressなどの基本コンポーネントを最初からセットアップする必要がある。
