### 構成01

![monitoring01](./images/monitoring01.png "monitoring01")

- <b>Prometheus:</b> メトリクスを外部に保存 + アラートはGrafanaが処理するため、Agentモードを利用
- <b>Mimir:</b> メトリクスを長期保存（NCP Object Storage利用）+ アラート機能があるが、未確認
- <b>Grafana:</b> アラート + ダッシュボード + 通知

| Pros | Cons |
|--|--|
| - 各クラスタのPrometheus管理が楽になる。<br>- Grafanaアラートを利用するため、設定管理が楽になる。 | - 管理必要なリソースの増加(Mimir)<br> - ダッシュボード + アラート設定によるGrafanaの負荷問題 |

### 構成02

![monitoring02](./images/monitoring02.png "monitoring02")

- Prometheus: メトリクスを保存 + アラート + 通知
- Grafana: ダッシュボード

| Pros | Cons |
|--|--|
| - 監視とアラートがGrafana1つで可能。 | - 各クラスタごとデータソースとアラート管理が必要<br> - ダッシュボード + アラート設定によるGrafanaの負荷問題 |


### 構成03

![monitoring03](./images/monitoring03.png "monitoring03")

- Prometheus: メトリクスを保存 + アラート + 通知
- 管理ツール：アラート追加/削除
- Grafana: ダッシュボード

| Pros | Cons |
|--|--|
| - パフォーマンスを気にせずアラート設定可能 | 監視とアラートツールが分離<br> - まとめてアラート設定可能なツール作成が必要 |
