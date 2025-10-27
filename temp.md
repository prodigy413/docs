# Logs agentインストール/運用改善案

### 収集対象ログの再検討

- 現在、/var/log/containers 以外に /var/log からもログを収集している（おそらくLogDNA設定をそのまま利用）。
- 大量ログの収集はトラフィックやコストの増加につながるほか、設定項目が増えることで運用負荷も増加<br>
→ 収集対象を確認し、不要なログは除外する。

### コンテナログパス設定の見直し

- 現在、デフォルト設定（/var/log/containers/*.log）を使わず、/var/log/containers/* に変更・追加している（おそらくLogDNA設定をそのまま利用）。
- 収集除外パスに *.gz, *.zip が設定されている（おそらくLogDNA設定をそのまま利用）。※Fluent Bitは圧縮ファイルをチェックしない。<br>
→ 変更不要な設定は、なるべく追加しない方が良いかと。

### SecurityContext削除

- 現行のインストール手順では、agentインストール後にSecurityContextのprivilegedをtrueに変更している。
- agentにはDAC_READ_SEARCHというcapabilityがあり、ファイルのパーミッションに関係なく読み取りが可能。
→ バージョンアップ時に動作確認し、問題なければSecurityContext設定の手順を省略できるかも。

### 認証方法の変更

- 現在はagentインストール時の認証にService IDを使用している。
- Service IDを使う場合、認証用APIキーの保管が必要。<br>
→ Trusted Profileに切り替えることでAPIキー管理を不要にし、インストール手順を簡略化できる。
- 補足：
  - Service ID：IBM Cloud上のアプリケーションやサービスがIBM CloudのAPIにアクセスするためのID。
  - Trusted Profile：IBM CloudリソースにアクセスするためのIDフェデレーションを安全に管理する仕組み。

| 項目   | Service ID    | Trusted Profile    |
| ---- | ------------- | ------------------ |
| 対象   | システム / サービス   | 信頼された環境 / フェデレーション |
| 認証方式 | APIキー（長期）     | 一時トークン（自動発行）       |
| 主な用途 | アプリ・パイプラインの認証 | ワークロード・Podの動的認証    |
| メリット | シンプル・固定ID     | 高セキュリティ・自動化        |
| リスク  | APIキー漏えいの危険   | 設定がやや複雑            |

### Kubernetesフィールド設定の見直し

- [v1.6.1](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-release-notes-agent&locale=en#logs-router-agent-jun2625)以降、デフォルトでKubernetesメタデータフィールドに含まれるのは以下の3項目のみ。
  - pod_name
  - namespace_name
  - container_name
- フィールドの追加・削除も可能。
- 特に要件がなければ、デフォルト設定のままにしてログ量を抑える。
- 参照：[Enabling the Kubernetes filter to enrich logs with Kubernetes metadata](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-helm-kubernetes-filter)
