~~~
AWSTemplateFormatVersion: 2010-09-09
Transform: AWS::Serverless-2016-10-31
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
    Description: S3 bucket name for log.
    Type: String
    Default: obi-prod-bucket-logs

##############################
# Resource
# List:
# - WAF
# - WAF Logging
# - Kinesis
# - Kinesis Role
# - Lambda Edge
# - IAM Role for Lambda Edge
##############################
Resources:
##############################
# WAF
##############################
  WebAcl:
    Type: AWS::WAFv2::WebACL
    Properties: 
      Name: !Sub ${Project}-${Env}-webacl
      Scope: CLOUDFRONT
      DefaultAction:
        Allow: {}
      VisibilityConfig:
        CloudWatchMetricsEnabled: true
        SampledRequestsEnabled: true
        MetricName: !Sub ${Project}-${Env}-webacl
      Rules:
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 0
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
          OverrideAction:
            Count: {}
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            SampledRequestsEnabled: true
            MetricName: AWSManagedRulesCommonRuleSet
        - Name: AWSManagedRulesAmazonIpReputationList
          Priority: 1
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesAmazonIpReputationList
          OverrideAction:
            Count: {}
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            SampledRequestsEnabled: true
            MetricName: AWSManagedRulesAmazonIpReputationList
        - Name: AWSManagedRulesAnonymousIpList
          Priority: 2
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesAnonymousIpList
          OverrideAction:
            Count: {}
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            SampledRequestsEnabled: true
            MetricName: AWSManagedRulesAnonymousIpList
        - Name: AWSManagedRulesKnownBadInputsRuleSet
          Priority: 3
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesKnownBadInputsRuleSet
          OverrideAction:
            Count: {}
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            SampledRequestsEnabled: true
            MetricName: AWSManagedRulesKnownBadInputsRuleSet
        - Name: Custom-IPRequestLimit
          Action:
            Block: {}
          Priority: 4
          Statement:
            RateBasedStatement:
              AggregateKeyType: IP
              Limit: 1000
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            MetricName: Custom-IPRequestLimit
            SampledRequestsEnabled: true
##############################
# WAF Logging
##############################
  LoggingConfiguration:
    Type: AWS::WAFv2::LoggingConfiguration
    Properties:
      ResourceArn: !GetAtt WebAcl.Arn
      LogDestinationConfigs:
        - !GetAtt FirehoseDeliveryStream.Arn
##############################
# Kinesis
##############################
  FirehoseDeliveryStream:
    Type: AWS::KinesisFirehose::DeliveryStream
    Properties:
      DeliveryStreamName: !Sub aws-waf-logs-${Project}-${Env}
      DeliveryStreamType: DirectPut
      S3DestinationConfiguration:
        BucketARN: !Sub arn:aws:s3:::${LogBucket}
        Prefix: waf/
        CompressionFormat: GZIP
        RoleARN: !GetAtt FirehoseRole.Arn
##############################
# Kinesis Role
##############################
  FirehoseRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: KinesisFirehoseServiceRole
      Description: IAM Role for Kinesis Firehose
      Path: '/'
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - firehose.amazonaws.com
            Action:
              - sts:AssumeRole
      Policies:
        - PolicyName: KinesisFirehoseServicePolicy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - s3:AbortMultipartUpload
                  - s3:GetBucketLocation
                  - s3:GetObject
                  - s3:ListBucket
                  - s3:ListBucketMultipartUploads
                  - s3:PutObject
                Resource:
                  - !Sub arn:aws:s3:::${LogBucket}
                  - !Sub arn:aws:s3:::${LogBucket}/*
##############################
# Lambda Edge
##############################
  LambdaEdge:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub ${Project}-${Env}-lambda-edge
      Description: Update later
      Handler: index.handler
      #Handler: index.lambda_handler
      Runtime: nodejs16.x
      #Runtime: python3.9
      #MemorySize: 128
      #Timeout: 5
      Role: !GetAtt LambdaEdgeRole.Arn
      AutoPublishAlias: stg
      InlineCode: |
        'use strict';

        const path = require('path')

        exports.handler = (event, context, callback) => {
            const { request } = event.Records[0].cf
            const url = request.uri;
            const extension = path.extname(url);

            if(extension && extension.length > 0){
                return callback(null, request);
            }

            const last_character = url.slice(-1);

            if(last_character === "/"){
                request.uri = url + 'index.html';
                return callback(null, request);
            }
  
            const new_url = `${url}/`;

            const redirect = {
                status: '301',
                statusDescription: 'Moved Permanently',
                headers: {
                    location: [{
                        key: 'Location',
                        value: new_url,
                    }],
                },
            };

            return callback(null, redirect);
        };
##############################
# IAM Role for Lambda Edge
##############################
  LambdaEdgeRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: LambdaEdgeRole
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
                - edgelambda.amazonaws.com
            Action: sts:AssumeRole
      Description: IAM Role for Lambda Edge
      Path: /
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

##############################
# Outputs
##############################
Outputs:
  WAFArn:
    Value: !GetAtt WebAcl.Arn
  LambdaEdgeArn:
    Value: !GetAtt LambdaEdge.Arn
  LambdaEdgeVersion:
    Value: !Ref LambdaEdge.Version










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
    Default: arn:aws:lambda:us-east-1:844065555252:function:obi-prod-lambda-edge:13
  WebAcl:
    Description: WAF arn.
    Type: String
    Default: arn:aws:wafv2:us-east-1:844065555252:global/webacl/obi-prod-webacl/026293bf-838b-4ba2-8967-4aeb383df754

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
          LambdaFunctionAssociations:
            - EventType: viewer-request
              LambdaFunctionARN: !Ref LambdaEdgeVersion
          #FunctionAssociations:
          #  - EventType: viewer-request
          #    FunctionARN: !GetAtt ModifyRequestUrlFunction.FunctionMetadata.FunctionARN
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
# Cloudfront Functions Test
##############################
#  ModifyRequestUrlFunction:
#    Type: AWS::CloudFront::Function
#    Properties: 
#      Name: modify-request-url
#      AutoPublish: true
#      FunctionConfig:
#        Comment: test function
#        Runtime: cloudfront-js-1.0
#      FunctionCode: |
#        function handler(event) {
#            var request = event.request;
#            var uri = request.uri;
#        
#            if (uri.endsWith('/')) {
#                request.uri += 'index.html';
#            }
#            else if (!uri.includes('.')) {
#                var response = {
#                    statusCode: 302,
#                    statusDescription: 'Found',
#                    headers:
#                      { "location": { "value": request.uri + '/' }}
#                  }
#                return response;
#            }
#            return request;
#        }
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
      LifecycleConfiguration:
        Rules:
          - Id: !Sub ${Project}-${Env}-lifecycle-rule
            Status: Enabled
            ExpirationInDays: 365
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
  Cloudfront4xxRate:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub ${Project}-${Env}-email-notification
      Subscription:
        - Protocol: email
          Endpoint: xxxxxxxxxxxxxx@xxxxxxx.xxx
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

##############################
# Resource
# List:
# - Codecommit
# - Codebuild
# - IAM Role for Codebuild
# - LogGroup for Codebuild
##############################
Resources:
##############################
# Codecommit
##############################
  Codecommit:
    Type: AWS::CodeCommit::Repository
    Properties:
      RepositoryName: !Sub ${Project}-${Env}-repository
      RepositoryDescription: Repository for Codebuild files
##############################
# Codebuild
##############################
  Codebuild:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: !Sub ${Project}-${Env}-codebuild
      Description: Codebuild for S3 Sync
      Artifacts:
        Type: NO_ARTIFACTS
      Cache:
        Type: NO_CACHE
      Environment:
        Type: LINUX_CONTAINER
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/standard:5.0
        ImagePullCredentialsType: CODEBUILD
      LogsConfig:
        CloudWatchLogs:
          GroupName: /aws/CodeBuild
          Status: ENABLED
          StreamName: !Sub ${Project}-${Env}-codebuild
      ServiceRole: !Ref CodeBuildServiceRole
      Source:
        Type: CODECOMMIT
        Location: !GetAtt Codecommit.CloneUrlHttp
      SourceVersion: refs/heads/main
      TimeoutInMinutes: 10
##############################
# IAM Role for Codebuild
##############################
  CodeBuildServiceRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: CodeBuildServiceRole
      Path: /
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - codebuild.amazonaws.com
            Action:
                - sts:AssumeRole
      Policies:
        - PolicyName: CodeBuildServicePolicy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Resource:
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/CodeBuild
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/CodeBuild:*
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
              - Effect: Allow
                Resource:
                  - !Sub arn:aws:codebuild:${AWS::Region}:${AWS::AccountId}:report-group/*
                Action:
                  - codebuild:CreateReportGroup
                  - codebuild:CreateReport
                  - codebuild:UpdateReport
                  - codebuild:BatchPutTestCases
                  - codebuild:BatchPutCodeCoverages
              - Effect: Allow
                Resource:
                  - !Sub arn:aws:cloudfront::${AWS::AccountId}:distribution/*
                Action:
                  - cloudfront:GetDistributionConfig
                  - cloudfront:CreateInvalidation
              - Effect: Allow
                Resource:
                  - !GetAtt Codecommit.Arn
                Action:
                  - codecommit:GitPull
              - Effect: Allow
                Resource: '*'
                Action:
                  - s3:GetObject
                  - s3:List*
                  - s3:PutObject           
##############################
# LogGroup
##############################
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties: 
      LogGroupName: /aws/CodeBuild
      RetentionInDays: 7

##############################
# Outputs
##############################
Outputs:
  CodecommitArn:
    Value: !GetAtt Codecommit.Arn











AWSTemplateFormatVersion: "2010-09-09"
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

##############################
# Resource
# List:
# - Cognito Domain
# - Cognito Userpool
# - Userpool Client
##############################
Resources:
##############################
# Cognito Domain
#############################
  UserPoolDomain:
    Type: AWS::Cognito::UserPoolDomain
    Properties:
      Domain: !Sub ${Project}-${Env}-domain
      UserPoolId: !Ref UserPool
##############################
# Cognito Userpool
#############################
  UserPool:
    Type: AWS::Cognito::UserPool
    Properties:
      UserPoolName: !Sub ${Project}-${Env}-userpool
      UsernameConfiguration:
        CaseSensitive: True
      MfaConfiguration: 'OFF'
      AdminCreateUserConfig:
        AllowAdminCreateUserOnly: true
##############################
# Userpool Client
#############################
  UserPoolClient:
    Type: AWS::Cognito::UserPoolClient
    Properties:
      ClientName: !Sub ${Project}-${Env}-app
      UserPoolId: !Ref UserPool
      AllowedOAuthFlowsUserPoolClient: true
      AllowedOAuthFlows:
        - code
      AllowedOAuthScopes:
        - email
        - openid
        - phone
      CallbackURLs:
        - http://localhost:3000
      SupportedIdentityProviders:
        - COGNITO

##############################
# Outputs
##############################
#Outputs:
#  S3BucketName:
#    Value: !Ref S3SiteContents











version: 0.2

env:
  variables:
    source_bucket: "obi-prod-bucket-site-contents"
    target_bucket: "obi-prod-bucket-site-contents-bk"
    cloudfront_id: "E189FE8J7W1WHT"

phases:
  pre_build:
    commands:
      - echo Check if Buckets exist.
      - aws s3api head-bucket --bucket ${source_bucket}
      - aws s3api head-bucket --bucket ${target_bucket}
      - echo Check if Cloudfront exists.
      - aws cloudfront get-distribution-config --id ${cloudfront_id} > /dev/null
  build:
    commands:
      - echo Sync Buckets
      - aws s3 sync s3://${source_bucket} s3://${target_bucket}
      - echo Create Invalidation
      - aws cloudfront create-invalidation --distribution-id ${cloudfront_id} --paths "/*"
  post_build:
    commands:
      - echo Task Completed.










# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-events-rule.html
AWSTemplateFormatVersion: 2010-09-09
Description: Obi Cloudformation Test

Resources:
  Codecommit:
    Type: AWS::CodeCommit::Repository
    Properties:
      RepositoryName: test-repository
      RepositoryDescription: Repository for Codebuild files
  Codebuild:
    Type: AWS::CodeBuild::Project
    Properties:
      Name: test-codebuild
      Description: Codebuild for S3 Sync
      Artifacts:
        Type: NO_ARTIFACTS
      Cache:
        Type: NO_CACHE
      Environment:
        Type: LINUX_CONTAINER
        ComputeType: BUILD_GENERAL1_SMALL
        Image: aws/codebuild/standard:5.0
        ImagePullCredentialsType: CODEBUILD
      ServiceRole: !Ref CodeBuildServiceRole
      LogsConfig:
        CloudWatchLogs:
          GroupName: /aws/CodeBuild
          Status: ENABLED
          StreamName: test
      Source:
        Type: CODECOMMIT
        Location: !GetAtt Codecommit.CloneUrlHttp
      SourceVersion: refs/heads/main
      TimeoutInMinutes: 10
  CodeBuildServiceRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: CodeBuildServiceRole
      Path: /
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - codebuild.amazonaws.com
            Action:
                - sts:AssumeRole
      Policies:
        - PolicyName: CodeBuildServicePolicy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Resource:
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/CodeBuild
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/CodeBuild:*
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
              - Effect: Allow
                Resource:
                  - !Sub arn:aws:codebuild:${AWS::Region}:${AWS::AccountId}:report-group/*
                Action:
                  - codebuild:CreateReportGroup
                  - codebuild:CreateReport
                  - codebuild:UpdateReport
                  - codebuild:BatchPutTestCases
                  - codebuild:BatchPutCodeCoverages
              - Effect: Allow
                Resource:
                  - !GetAtt Codecommit.Arn
                Action:
                  - codecommit:GitPull
              - Effect: Allow
                Resource: '*'
                Action:
                  - s3:GetObject
                  - s3:List*
                  - s3:PutObject           
  EventBridge:
    Type: AWS::Events::Rule
    Properties:
      Name: test-eventbridge
      Description: test
      ScheduleExpression: "rate(5 minutes)"
      Targets: 
        - Arn: !GetAtt Codebuild.Arn
          Id: TestTarget
          RoleArn: !GetAtt EventBridgeServiceRole.Arn
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties: 
      LogGroupName: /aws/CodeBuild
      RetentionInDays: 7
  EventBridgeServiceRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: EventBridgeServiceRole
      Path: /
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - events.amazonaws.com
            Action:
                - sts:AssumeRole
      Policies:
        - PolicyName: CodeBuildServicePolicy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Resource:
                  - !GetAtt Codebuild.Arn
                Action:
                  - codebuild:StartBuild
##############################
# Outputs
##############################
Outputs:
  CodecommitArn:
    Value: !GetAtt Codecommit.Arn









AWSTemplateFormatVersion: 2010-09-09
Description: Obi S3 LifeCycle Test

Resources:
  S3SiteContentsBK:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: obi-s3-lifecycle-test
      AccessControl: Private
      VersioningConfiguration:
        Status: Suspended
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
      LifecycleConfiguration:
        Rules:
          - Id: obi-s3-LifeCycle-Rule
            Status: Enabled
            ExpirationInDays: 1


~~~
