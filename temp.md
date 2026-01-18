# Cloudfrontのログ管理

現在のCloudfrontのログ設定の問題点と改善案について記載する。

## 標準ログ設定の比較

Cloudfrontで設定できるログ設定は以下2種類がある。

| 観点 | レガシー（Standard logs legacy） | V2（Standard logs v2） |
| ---- | ------------------------------ | --------------------- |
| 配信先 | S3 | S3 / Cloudwatch Logs / Firehose |
| 出力形式 | W3C | JSON / W3C / Parquetなど |
| S3パス設計 | `prefix/ログファイル名.gz` | `year/month/day/hour`のようなパス設計可能 |
| コスト | 無料 | 無料 |

### 現状

- レガシーを利用しているため、すべてのログが一つのディレクトリに配信されている。
- Athenaを利用したログ分析のため、日付ディレクトリを作成し、ログの移動作業を手動で実施している。
- Lambdaを利用したログ移動の自動化を検討中。

### 改善

- V2を利用し、ディレクトリ構成を以下のように変更する。<br>`<バケット名>/.../年/月/日/時`
- ログの移動や自動化が不要となり、Athenaでそのまま検索可能となる。
- 検索範囲を絞れるため、Athenaの利用コストを削減できる。

## 出力形式

S3に保管するログのデータフォーマット比較。

| 観点 | Parquet | JSON | W3C |
| ---- | ------- | ---- | --- |
| 可読性 | 低 | 中 | 高 |
| Athena/分析コスト | 低 | 中 | 高 |
| S3保管コスト | 低 | 高 | 中 |
| 処理コスト | 有 | 無 | 無 |

- Parquetが最も効率的だが、変換などの処理コストが発生するため、NG
- JSONはデータサイズが大きくなるため、NG
- W3Cは分析コストは高いが、分析頻度が高くないため、OK<br>※レガシーはW3C

## 計画

### ログ設定変更作業の影響

- Cloudfrontサービスに影響はない。
- 新しいログ設定を追加してから既存のログ設定を削除するため、ログ取得漏れは発生しない。

### 開発環境設定

- 標準ログ設定（V2）を追加
- 1日後、レガシーログとV2ログを比較
- 問題なければ、レガシーログ設定を削除（※既存ログは削除しない）

### 本番環境設定

- 標準ログ設定（V2）を追加
- 1日後、レガシーログとV2ログを比較
- 問題なければ、レガシーログ設定を削除（※既存ログは削除しない）



# 2026/01/16

# Athenaログ調査手順

## テーブル作成

<details>
<summary>本番環境</summary>

```sql
CREATE EXTERNAL TABLE `cloudfront_logs`(
`date` string,
`time` string,
`x_edge_location` string,
`sc_bytes` string,
`c_ip` string,
`cs_method` string,
`cs_host` string,
`cs_uri_stem` string,
`sc_status` string,
`cs_referer` string,
`cs_user_agent` string,
`cs_uri_query` string,
`cs_cookie` string,
`x_edge_result_type` string,
`x_edge_request_id` string,
`x_host_header` string,
`cs_protocol` string,
`cs_bytes` string,
`time_taken` string,
`x_forwarded_for` string,
`ssl_protocol` string,
`ssl_cipher` string,
`x_edge_response_result_type` string,
`cs_protocol_version` string,
`fle_status` string,
`fle_encrypted_fields` string,
`c_port` string,
`time_to_first_byte` string,
`x_edge_detailed_result_type` string,
`sc_content_type` string,
`sc_content_len` string,
`sc_range_start` string,
`sc_range_end` string)
PARTITIONED BY(
 distributionid string,
 year int,
 month int,
 day int,
 hour int )
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY '\t'
LOCATION
's3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/'
TBLPROPERTIES (
'skip.header.line.count'='2',
'projection.distributionid.type'='enum',
'projection.distributionid.values'='E29BPSRCHPIPX5',
'projection.day.range'='01,31',
'projection.day.type'='integer',
'projection.day.digits'='2',
'projection.enabled'='true',
'projection.month.range'='01,12',
'projection.month.type'='integer',
'projection.month.digits'='2',
'projection.year.range'='2026,2030',
'projection.year.type'='integer',
'projection.hour.range'='0,23',
'projection.hour.type'='integer',
'projection.hour.digits'='2',
'storage.location.template'='s3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/${distributionid}/${year}/${month}/${day}/${hour}/')
```

</details>
<details>
<summary>開発/研修環境</summary>

```sql
CREATE EXTERNAL TABLE `cloudfront_logs`(
`date` string,
`time` string,
`x_edge_location` string,
`sc_bytes` string,
`c_ip` string,
`cs_method` string,
`cs_host` string,
`cs_uri_stem` string,
`sc_status` string,
`cs_referer` string,
`cs_user_agent` string,
`cs_uri_query` string,
`cs_cookie` string,
`x_edge_result_type` string,
`x_edge_request_id` string,
`x_host_header` string,
`cs_protocol` string,
`cs_bytes` string,
`time_taken` string,
`x_forwarded_for` string,
`ssl_protocol` string,
`ssl_cipher` string,
`x_edge_response_result_type` string,
`cs_protocol_version` string,
`fle_status` string,
`fle_encrypted_fields` string,
`c_port` string,
`time_to_first_byte` string,
`x_edge_detailed_result_type` string,
`sc_content_type` string,
`sc_content_len` string,
`sc_range_start` string,
`sc_range_end` string)
PARTITIONED BY(
 distributionid string,
 year int,
 month int,
 day int,
 hour int )
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY '\t'
LOCATION
's3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/'
TBLPROPERTIES (
'skip.header.line.count'='2',
'projection.distributionid.type'='injected',
'projection.day.range'='01,31',
'projection.day.type'='integer',
'projection.day.digits'='2',
'projection.enabled'='true',
'projection.month.range'='01,12',
'projection.month.type'='integer',
'projection.month.digits'='2',
'projection.year.range'='2026,2030',
'projection.year.type'='integer',
'projection.hour.range'='0,23',
'projection.hour.type'='integer',
'projection.hour.digits'='2',
'storage.location.template'='s3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/${distributionid}/${year}/${month}/${day}/${hour}/')
```

</details>

## テーブル削除

使用後はテーブルを削除する
```sql
DROP TABLE `cloudfront_logs`;
```

## 検索クエリ

### 説明

- ログのタイムゾーンはUTCのため、検索時には注意
- 開発/研修環境用バケットにはCloudfrontが複数存在するため、`distributionid`指定が必要。<br>例）
```sql
-- 本番
SELECT *
FROM cloudfront_logs
WHERE year = 2026
  AND month = 12
  AND day = 12
LIMIT 100;

-- 開発/研修環境
SELECT *
FROM cloudfront_logs
WHERE distributionid = 'E36RKEF5XP2P3H'
  AND year = 2026
  AND month = 12
  AND day = 12
LIMIT 100;
```

### サンプル

- 範囲：2026年1月16日
```sql
SELECT *
FROM cloudfront_logs
WHERE year = 2026
  AND month = 1
  AND day = 16
LIMIT 1000;
```

- 範囲：2026年1月16日12時（JST）
```sql
SELECT *
FROM cloudfront_logs
WHERE year = 2026
  AND month = 1
  AND day = 16
  AND hour = 3
LIMIT 1000;
```

- 範囲：2026年1月16日12時10分から40分（JST）
```sql
SELECT *
FROM cloudfront_logs
WHERE year = 2026
  AND month = 1
  AND day = 16
  AND hour = 3
  AND time >= '03:10:00'
  AND time <= '03:40:00'
LIMIT 1000;
```

- 範囲：2026年1月16日12時10分から14時40分（JST）
```sql
SELECT *
FROM cloudfront_logs
WHERE year = 2026
  AND month = 1
  AND day = 16
  AND hour BETWEEN 3 AND 5
  AND time >= '03:10:00'
  AND time <= '05:40:00'
LIMIT 1000;
```
