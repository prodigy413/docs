```
CloudFront画面を開き、[Distributions]クリック > 該当CloudFrontを選択
[Logging]タブをクリック > [Add] > [Amazon S3]クリック

[Deliver to]: Amazon S3
[Destination S3 bucket]: xxxxx.s3.amazonaws.comを選択し、後ろに/cloudfront-logs/を追加

Additional Settings

Field selection: デフォルトのまま
Partitioning
/{DistributionId}/{yyyy}/{MM}/{dd}/{HH}

Apache Hive compatibility

[Use a Hive-compatible file name format]: チェックしない（※デフォルト）

[Output format]: W3C（※デフォルト）
[Field delimiter]: \t（※デフォルト）

[Submit]クリック
確認

aws s3 mv s3://xxxxxxxx/ s3://xxxxxxx/xxxxx/test/ \
--recursive \
--exclude "*.gz" \
--include "index.*" \
--dryrun
```
