~~~
AWSTemplateFormatVersion: 2010-09-09
Description: Obi Cloudformation Test

##############################
# Parameters
##############################
Parameters:
  Project:
    Description: Project name.
    Type: String
    AllowedPattern: "[a-zA-Z0-9]*"
    Default: obi
  Env:
    Description: Environment name.
    Type: String
    AllowedValues: [prod, stg]
    Default: prod
  LogBucket:
    Description: S3 bucket arn for log.
    Type: String
    Default: obi-prod-bucket-logs
  LambdaEdge:
    Description: Lambda Edge name.
    Type: String
    Default: obi-prod-lambda-edge
  LambdaEdgeVersion:
    Description: Lambda edge arn + version for cloudfront.
    Type: String
    Default: arn:aws:lambda:us-east-1:844065555252:function:obi-prod-lambda-edge:6
  WebAcl:
    Description: WAF arn.
    Type: String
    Default: arn:aws:wafv2:us-east-1:844065555252:global/webacl/obi-prod-webacl/eeeac508-c826-41ac-96d9-d2f1612a79ef

##############################
# Resource
# List:
# - Cloudfront
# - Cloudfront Origin Access Identity
# - Cache Policy for Cloudfront
# - S3 Bucket for Site Contents
# - S3 Bucket Policy for Site Contents
# - S3 Bucket for Site Contents backup
# - Cloudwatch Alarm
# - SNS for Cloudwatch Alarm Notification
# - LogGroup for LambdaEdge Logging
##############################
Resources:
##############################
# Cloudfront Origin Access Identity
#############################
  OriginAccessIdentity:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: !Sub ${S3SiteContents}
##############################
# Cloudfront Distribution
##############################
  Distribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
          - Id: S3Origin
            DomainName: !Sub ${S3SiteContents}.s3.amazonaws.com
            S3OriginConfig:
              OriginAccessIdentity: !Sub origin-access-identity/cloudfront/${OriginAccessIdentity}
        Enabled: true
        Comment: !Sub ${S3SiteContents}
        DefaultRootObject: index.html
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: True
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          CachePolicyId: !Ref CachePolicy
          #LambdaFunctionAssociations:
          #  - EventType: viewer-request
          #    LambdaFunctionARN: !Ref LambdaEdgeVersion
        Restrictions:
          GeoRestriction:
            RestrictionType: none
        ViewerCertificate:
          CloudFrontDefaultCertificate: true
        WebACLId: !Sub ${WebAcl}
        Logging:
          Bucket: !Sub ${LogBucket}.s3.amazonaws.com
          IncludeCookies: False
          Prefix: cloudfront-source
##############################
# Cache Policy for Cloudfront
##############################
  CachePolicy:
    Type: AWS::CloudFront::CachePolicy
    Properties:
      CachePolicyConfig:
        Name: !Sub ${Project}-${Env}-cache-policy
        Comment: Cache Policy for Cloudfront Caching
        DefaultTTL: 86400
        MaxTTL: 31536000
        MinTTL: 1
        ParametersInCacheKeyAndForwardedToOrigin:
          CookiesConfig:
            CookieBehavior: none
          EnableAcceptEncodingBrotli: true
          EnableAcceptEncodingGzip: true
          HeadersConfig:
            HeaderBehavior: none
          QueryStringsConfig:
            QueryStringBehavior: none
##############################
# S3 Bucket for Site Contents
##############################
  S3SiteContents:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub ${Project}-${Env}-bucket-site-contents
      AccessControl: Private
      VersioningConfiguration:
        Status: Suspended
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
##############################
# S3 Bucket Policy for Site Contents
##############################
  BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Sub ${S3SiteContents}
      PolicyDocument:
        Statement:
          Action:
            - s3:GetObject
          Effect: Allow
          Resource:
            - !Sub arn:aws:s3:::${S3SiteContents}/*
          Principal:
            AWS: !Sub arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${OriginAccessIdentity}
##############################
# S3 Bucket for Site Contents backup
##############################
  S3SiteContentsBK:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub ${Project}-${Env}-bucket-site-contents-bk
      AccessControl: Private
      VersioningConfiguration:
        Status: Suspended
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
##############################
# Cloudwatch Alarm
##############################
  CloudwatchAlarm01:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub ${Project}-${Env}-alarm-4xx-error
      AlarmDescription: Alarm for cloudfront 4xx Error
      AlarmActions:
        - !Ref Cloudfront4xxRate
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: Region
          Value: Global
        - Name: DistributionId
          Value: !GetAtt Distribution.Id
      MetricName: 4xxErrorRate
      Namespace: AWS/CloudFront
      EvaluationPeriods: 1
      Period: 300
      Statistic: Average
      Threshold: 5
##############################
# SNS for Cloudwatch Alarm Notification
##############################
# Accese policy is created in SNS automatically, means will be deleted when deleting SNS. no need to create manually.
  Cloudfront4xxRate:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub ${Project}-${Env}-email-notification
      Subscription:
        - Protocol: email
          Endpoint: zerozero413@gmail.com
##############################
# LogGroup for LambdaEdge Logging
##############################
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties: 
      LogGroupName:
        !Join
          - ''
          - - '/aws/lambda/us-east-1.'
            - !Ref LambdaEdge
      RetentionInDays: 7

##############################
# Outputs
##############################
Outputs:
  S3BucketName:
    Value: !Ref S3SiteContents
  WebsiteURL:
    Value: !GetAtt S3SiteContents.WebsiteURL
  DistributionID:
    Value: !Ref Distribution
  CloudfrontDomainName:
    Value: !GetAtt Distribution.DomainName











AWSTemplateFormatVersion: 2010-09-09
Description: Obi Cloudformation Test

##############################
# Parameters
##############################
Parameters:
  Project:
    Description: Project name.
    Type: String
    AllowedPattern: "[a-zA-Z0-9]*"
    Default: obi
  Env:
    Description: Environment name.
    Type: String
    AllowedValues: [prod, stg]
    Default: prod
  LogBucket:
    Description: S3 bucket arn for log.
    Type: String
    Default: obi-prod-bucket-logs
  NewKeyPrefix: 
    Type: String
    Default: 'cloudfront-source/'
    AllowedPattern: '[A-Za-z0-9\-]+/'
    Description: >
        Prefix of new access log files that are written by Amazon CloudFront.
        Including the trailing slash.
  GzKeyPrefix: 
    Type: String
    Default: 'cloudfront/'
    AllowedPattern: '[A-Za-z0-9\-]+/'
    Description: >
        Prefix of gzip'ed access log files that are moved to the Apache Hive
        like style. Including the trailing slash.

##############################
# Resource
# List:
# - Athena
# - S3 Bucket for Athena Query result location
# - Glue Database
# - Glue Table
# - Lambda for Moving Accesslogs Files
# - Lambda Permission
# - IAM Role for Lambda
# - LogGroup for Lambda Logging
##############################
Resources:
##############################
# Athena
##############################
  AthenaWorkGroup:
    Type: AWS::Athena::WorkGroup
    Properties:
      Name: !Sub ${Project}-${Env}-athena
      State: ENABLED
      WorkGroupConfiguration:
        EnforceWorkGroupConfiguration: true
        PublishCloudWatchMetricsEnabled: true
        ResultConfiguration:
          OutputLocation: !Sub s3://${S3AthenaQueryResult}/athena/
##############################
# S3 Bucket for Athena Query result location
##############################
  S3AthenaQueryResult:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub ${Project}-${Env}-bucket-athena-query-result
      AccessControl: Private
      VersioningConfiguration:
        Status: Suspended
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
##############################
# Glue Database
##############################
  GlueDatabase:
    Type: AWS::Glue::Database
    Properties: 
      CatalogId: !Ref AWS::AccountId
      DatabaseInput:
        Name: !Sub ${Project}_${Env}_cloudfront_accesslog
##############################
# Glue Table
##############################
  GlueTable:
    Type: AWS::Glue::Table
    Properties:
      CatalogId: !Ref AWS::AccountId
      DatabaseName: !Ref GlueDatabase
      TableInput:
        Name: !Sub ${Project}_${Env}_cloudfront_accesslog
        Description: 'Creating table test'
        TableType: EXTERNAL_TABLE
        Parameters:
          skip.header.line.count": 2
          projection.enabled: true
          projection.dt.type: date
          projection.dt.range: "2022-04-01-01,NOW"
          projection.dt.format: yyyy-MM-dd-HH
          projection.dt.interval: 1
          projection.dt.interval.unit: HOURS
          #storage.location.template: 
          #  !Join
          #    - ''
          #    - - !Sub s3://${LogBucket}/partitioned-gz/
          #      - '${dt}'
        PartitionKeys:
        - Name: dt
          Type: string
        #- Name: year
        #  Type: string
        #- Name: month
        #  Type: string
        #- Name: day
        #  Type: string
        #- Name: hour
        #  Type: string
        StorageDescriptor:
          OutputFormat: org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat
          Columns:
          - Name: date
            Type: date
          - Name: time
            Type: string
          - Name: location
            Type: string
          - Name: bytes
            Type: bigint
          - Name: request_ip
            Type: string
          - Name: method
            Type: string
          - Name: host
            Type: string
          - Name: uri
            Type: string
          - Name: status
            Type: int
          - Name: referrer
            Type: string
          - Name: user_agent
            Type: string
          - Name: query_string
            Type: string
          - Name: cookie
            Type: string
          - Name: result_type
            Type: string
          - Name: request_id
            Type: string
          - Name: host_header
            Type: string
          - Name: request_protocol
            Type: string
          - Name: request_bytes
            Type: bigint
          - Name: time_taken
            Type: float
          - Name: xforwarded_for
            Type: string
          - Name: ssl_protocol
            Type: string
          - Name: ssl_cipher
            Type: string
          - Name: response_result_type
            Type: string
          - Name: http_version
            Type: string
          - Name: fle_status
            Type: string
          - Name: fle_encrypted_fields
            Type: int
          - Name: c_port
            Type: int
          - Name: time_to_first_byte
            Type: float
          - Name: x_edge_detailed_result_type
            Type: string
          - Name: sc_content_type
            Type: string
          - Name: sc_content_len
            Type: bigint
          - Name: sc_range_start
            Type: bigint
          - Name: sc_range_end
            Type: bigint
          InputFormat: org.apache.hadoop.mapred.TextInputFormat
          Location: !Sub s3://${LogBucket}/${GzKeyPrefix}
          SerdeInfo:
            Parameters:
              field.delim: "\t"
              serialization.format: "\t"
            SerializationLibrary: org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe
##############################
# Lambda for Moving Accesslogs Files
##############################
  MoveAccessLogs:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub ${Project}-${Env}-move-accesslogs
      Code:
        ZipFile: |
          const aws = require('aws-sdk');
          const s3 = new aws.S3({ apiVersion: '2006-03-01' });

          const targetKeyPrefix = process.env.TARGET_KEY_PREFIX;

          const datePattern = '[^\\d](\\d{4})-(\\d{2})-(\\d{2})-(\\d{2})[^\\d]';
          const filenamePattern = '[^/]+$';

          exports.handler = async (event, context, callback) => {
            const moves = event.Records.map(record => {
              const bucket = record.s3.bucket.name;
              const sourceKey = record.s3.object.key;

              const sourceRegex = new RegExp(datePattern, 'g');
              const match = sourceRegex.exec(sourceKey);
              if (match == null) {
                console.log(`Object key ${sourceKey} does not look like an access log file, so it will not be moved.`);
              } else {
                const [, year, month, day, hour] = match;

                const filenameRegex = new RegExp(filenamePattern, 'g');
                const filename = filenameRegex.exec(sourceKey)[0];

                //const targetKey = `${targetKeyPrefix}year=${year}/month=${month}/day=${day}/hour=${hour}/${filename}`;
                const targetKey = `${targetKeyPrefix}dt=${year}-${month}-${day}-${hour}/${filename}`;
                console.log(`Copying ${sourceKey} to ${targetKey}.`);

                const copyParams = {
                  CopySource: bucket + '/' + sourceKey,
                  Bucket: bucket,
                  Key: targetKey
                };
                const copy = s3.copyObject(copyParams).promise();

                const deleteParams = { Bucket: bucket, Key: sourceKey };

                return copy.then(function () {
                  console.log(`Copied. Now deleting ${sourceKey}.`);
                  const del = s3.deleteObject(deleteParams).promise();
                  console.log(`Deleted ${sourceKey}.`);
                  return del;
                }, function (reason) {
                  const error = new Error(`Error while copying ${sourceKey}: ${reason}`);
                  callback(error);
                });

              }
            });
            await Promise.all(moves);
          };
      Description: Function to move access logs.
      Environment: 
        Variables: 
          TARGET_KEY_PREFIX: !Ref GzKeyPrefix
      Handler: index.handler
      Role: !GetAtt LambdaRole.Arn
      Runtime: nodejs14.x
      Timeout: 30
##############################
# Lambda Permission
##############################
  LambdaPermission:
    Type: AWS::Lambda::Permission
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !Ref MoveAccessLogs
      Principal: s3.amazonaws.com
      SourceArn: !Sub arn:aws:s3:::${LogBucket}
      SourceAccount: !Ref AWS::AccountId
##############################
# IAM Role for Lambda
##############################
  LambdaRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: MoveLogsLambdaRole
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action: sts:AssumeRole
      Description: String
      Path: /
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: MoveLogsLambdaPolicy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Resource: !Sub arn:aws:s3:::${LogBucket}/${NewKeyPrefix}*
                Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:DeleteObject
              - Resource: !Sub arn:aws:s3:::${LogBucket}/${GzKeyPrefix}*
                Effect: Allow
                Action:
                  - s3:PutObject
##############################
# LogGroup
##############################
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties: 
      LogGroupName:  !Sub /aws/lambda/${MoveAccessLogs}
      RetentionInDays: 7

~~~
