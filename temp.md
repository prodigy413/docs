# partition projectionを利用したCloudFrontログのathenaテーブル作成例 (w3c形式)
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
'projection.distributionid.values'='E36RKEF5XP2P3H',
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


select *
from cloudfront_logs
where year = 2026 and month = 1 and day = 12
limit 100;

select *
from cloudfront_logs
where distributionid = 'E36RKEF5XP2P3H' and  year = 2026 and month = 1 and day = 12
limit 100;


パスを以下のように日付ではなく全体にするとテーブルを作るとき、時間がかかったりコストがもっと発生したりしませんか。
..........
LOCATION
's3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/'
..........
'storage.location.template'='s3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/${distributionid}/${year}/${month}/${day}/${hour}/')



select *
from cloudfront_logs
where distributionid = 'E36RKEF5XP2P3H' and  year = 2026 and month = 1 and day = 12 and "time" BETWEEN '9:00:00' AND '9:30:00'
limit 100;


select *
from cloudfront_logs
where distributionid = 'E36RKEF5XP2P3H' 
    and  year = 2026 and month = 1 and day = 12 and hour = 9
    and cast(split_part("time", ':', 2) as integer) = 15
limit 100;

select *
from cloudfront_logs
where distributionid = 'E36RKEF5XP2P3H' 
    and  year = 2026 and month = 1 and day = 12 and hour = 9
    and cast(split_part("time", ':', 2) as integer) between 10 and 40
limit 100;



CREATE EXTERNAL TABLE IF NOT EXISTS cloudfront_standard_logs (
  `date` DATE,
  time STRING,
  x_edge_location STRING,
  sc_bytes BIGINT,
  c_ip STRING,
  cs_method STRING,
  cs_host STRING,
  cs_uri_stem STRING,
  sc_status INT,
  cs_referrer STRING,
  cs_user_agent STRING,
  cs_uri_query STRING,
  cs_cookie STRING,
  x_edge_result_type STRING,
  x_edge_request_id STRING,
  x_host_header STRING,
  cs_protocol STRING,
  cs_bytes BIGINT,
  time_taken FLOAT,
  x_forwarded_for STRING,
  ssl_protocol STRING,
  ssl_cipher STRING,
  x_edge_response_result_type STRING,
  cs_protocol_version STRING,
  fle_status STRING,
  fle_encrypted_fields INT,
  c_port INT,
  time_to_first_byte FLOAT,
  x_edge_detailed_result_type STRING,
  sc_content_type STRING,
  sc_content_len BIGINT,
  sc_range_start BIGINT,
  sc_range_end BIGINT
)
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY '\t'
LOCATION 's3://obi-test-bucket-for-logs-20260112/AWSLogs/844065555252/CloudFront/2026/01/12/'
TBLPROPERTIES ( 'skip.header.line.count'='2' )




SELECT *
FROM cloudfront_standard_logs
WHERE "time" BETWEEN '14:24:00' AND '14:46:00'
LIMIT 100;






CREATE EXTERNAL TABLE IF NOT EXISTS cloudfront_standard_logs (
  `date` DATE,
  time STRING,
  x_edge_location STRING,
  sc_bytes BIGINT,
  c_ip STRING,
  cs_method STRING,
  cs_host STRING,
  cs_uri_stem STRING,
  sc_status INT,
  cs_referrer STRING,
  cs_user_agent STRING,
  cs_uri_query STRING,
  cs_cookie STRING,
  x_edge_result_type STRING,
  x_edge_request_id STRING,
  x_host_header STRING,
  cs_protocol STRING,
  cs_bytes BIGINT,
  time_taken FLOAT,
  x_forwarded_for STRING,
  ssl_protocol STRING,
  ssl_cipher STRING,
  x_edge_response_result_type STRING,
  cs_protocol_version STRING,
  fle_status STRING,
  fle_encrypted_fields INT,
  c_port INT,
  time_to_first_byte FLOAT,
  x_edge_detailed_result_type STRING,
  sc_content_type STRING,
  sc_content_len BIGINT,
  sc_range_start BIGINT,
  sc_range_end BIGINT
)
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY '\t'
LOCATION 's3://obi-test-bucket-for-logs-20260109/EXV7XF97UCMT5/2026/01/11/'
TBLPROPERTIES ( 'skip.header.line.count'='2' )




SELECT *
FROM cloudfront_standard_logs
WHERE "time" BETWEEN '14:24:00' AND '14:46:00'
LIMIT 100;







# json
CREATE EXTERNAL TABLE `cloudfront_logs_pp`(
  `date` string, 
  `time` string, 
  `x-edge-location` string, 
  `sc-bytes` string, 
  `c-ip` string, 
  `cs-method` string, 
  `cs(host)` string, 
  `cs-uri-stem` string, 
  `sc-status` string, 
  `cs(referer)` string, 
  `cs(user-agent)` string, 
  `cs-uri-query` string, 
  `cs(cookie)` string, 
  `x-edge-result-type` string, 
  `x-edge-request-id` string, 
  `x-host-header` string, 
  `cs-protocol` string, 
  `cs-bytes` string, 
  `time-taken` string, 
  `x-forwarded-for` string, 
  `ssl-protocol` string, 
  `ssl-cipher` string, 
  `x-edge-response-result-type` string, 
  `cs-protocol-version` string, 
  `fle-status` string, 
  `fle-encrypted-fields` string, 
  `c-port` string, 
  `time-to-first-byte` string, 
  `x-edge-detailed-result-type` string, 
  `sc-content-type` string, 
  `sc-content-len` string, 
  `sc-range-start` string, 
  `sc-range-end` string)
  PARTITIONED BY(
         distributionid string,
         year int,
         month int,
         day int,
         hour int )
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES ( 
  'paths'='c-ip,c-port,cs(Cookie),cs(Host),cs(Referer),cs(User-Agent),cs-bytes,cs-method,cs-protocol,cs-protocol-version,cs-uri-query,cs-uri-stem,date,fle-encrypted-fields,fle-status,sc-bytes,sc-content-len,sc-content-type,sc-range-end,sc-range-start,sc-status,ssl-cipher,ssl-protocol,time,time-taken,time-to-first-byte,x-edge-detailed-result-type,x-edge-location,x-edge-request-id,x-edge-response-result-type,x-edge-result-type,x-forwarded-for,x-host-header') 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://obi-test-bucket-for-logs-20260109/AWSLogs/844065555252/CloudFront/'
TBLPROPERTIES (
  'projection.distributionid.type'='enum',
  'projection.distributionid.values'='EK05C6WDTM85Q',
  'projection.day.range'='01,31', 
  'projection.day.type'='integer', 
  'projection.day.digits'='2', 
  'projection.enabled'='true', 
  'projection.month.range'='01,12', 
  'projection.month.type'='integer', 
  'projection.month.digits'='2', 
  'projection.year.range'='2025,2026', 
  'projection.year.type'='integer', 
  'projection.hour.range'='00,23',
  'projection.hour.type'='integer',
  'projection.hour.digits'='2',
  'storage.location.template'='s3://obi-test-bucket-for-logs-20260109/AWSLogs/844065555252/CloudFront/${distributionid}/${year}/${month}/${day}/')




# parquet
CREATE EXTERNAL TABLE `cloudfront_logs_parquet_pp`(
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
 day int
 )
ROW FORMAT SERDE 
'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
's3://obi-test-bucket-for-logs-20260109/AWSLogs/844065555252/CloudFront/'
TBLPROPERTIES (
'projection.distributionid.type'='enum',
'projection.distributionid.values'='EK05C6WDTM85Q',
'projection.day.range'='01,31',
'projection.day.type'='integer',
'projection.day.digits'='2',
'projection.enabled'='true',
'projection.month.range'='01,12',
'projection.month.type'='integer',
'projection.month.digits'='2',
'projection.year.range'='2025,2026',
'projection.year.type'='integer',
'projection.hour.range'='01,12',
'projection.hour.type'='integer',
'projection.hour.digits'='2',
'storage.location.template'='s3://obi-test-bucket-for-logs-20260109/AWSLogs/844065555252/CloudFront/${distributionid}/${year}/${month}/${day}/')


select *
from cloudfront_logs_parquet_pp
where distributionid = 'EK05C6WDTM85Q' and year = 2026 and month = 1 and day = 9
limit 100;
