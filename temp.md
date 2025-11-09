# 2025/11/10 For Work

今回logs agentのバージョンアップに伴ってインターネットチームに少し相談したいことがありますが、ここで話して大丈夫でしょうか。<br>
logs agentのバージョンアップするついでにログ関連設定を少し改善したいところがありましてそれについて説明します。<br>

### コンテナログパス設定の変更

- コンテナログのパス設定を「手動」から「デフォルト」へ変更

| 現在 | 変更後 |
| ------------- | ------------------ |
| path: /var/log/containers/\*<br>exclude_path: /var/log/at/*, *.gz, *.zip | path: /var/log/containers/\*.log<br>exclude_path: /var/log/at/* |
| → 手動追加 | → デフォルトのため、設定不要 |

- コンテナログはデフォルトで`*.log`というファイル名で保存されるため、手動設定は不要
- Fluent bitは圧縮ファイルを収集対象にしない

### コンテナログ以外、対象ログの見直し

- 現在のログパス（コンテナログ以外）
  - /var/log/*
  - /var/log/audit/*
  - /var/log/calico/cni/*
  - /var/log/rhsm/*
- 必要なログに対象を絞ることで、Logsのコスト削減 / 運用負担を軽減

### kubernetesデータフィールドのデフォルト項目変更

- v1.6.1以降、kubernetesデータフィールドに含まれるデフォルトの項目は以下の３つ

| 現在 | 変更後 |
| ------------- | ------------------ |
| pod_name<br>namespace_name<br>container_name<br>pod_ip<br>pod_id<br>container_hash<br>container_image<br>docker_id<br>host | pod_name<br>namespace_name<br>container_name |

- デフォルトでは必須フィールドのみ保持
- 手動でフィールドの追加/削除可能
- 削除されたフィールドはk8sクラスタ内部で利用される情報であり、障害対応時の活用可能性は低め
- 問題なければフィールド数を減らしてLogsのコスト削減
