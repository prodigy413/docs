~~~
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

Resources:
##############################
# Kinesis Role
##############################
  FirehoseRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: KinesisFirehoseServiceRole
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
              #- Effect: Allow
              #  Action:
              #    - glue:GetTable
              #    - glue:GetTableVersion
              #    - glue:GetTableVersions
              #  Resource:
              #    - !Sub arn:aws:glue:{AWS::Region}:${AWS::AccountId}:catalog
              #    - !Sub arn:aws:glue:{AWS::Region}:${AWS::AccountId}:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
              #    - !Sub arn:aws:glue:{AWS::Region}:${AWS::AccountId}:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
              - Effect: Allow
                Action:
                  - s3:AbortMultipartUpload
                  - s3:GetBucketLocation
                  - s3:GetObject
                  - s3:ListBucket
                  - s3:ListBucketMultipartUploads
                  - s3:PutObject
                Resource:
                  - !Sub ${S3Logs.Arn}
                  - !Sub ${S3Logs.Arn}/*
              #- Effect: Allow
              #  Action:
              #    - lambda:InvokeFunction
              #    - lambda:GetFunctionConfiguration
              #  Resource:
              #    - !Sub arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%
              #- Effect: Allow
              #  Action:
              #    - kms:GenerateDataKey
              #    - kms:Decrypt
              #  Resource:
              #    - !Sub arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
              #  Condition:
              #    StringEquals:
              #      kms:ViaService: !Sub s3.${AWS::Region}.amazonaws.com
              #    StringLike:
              #      kms:EncryptionContext:aws:s3:arn:
              #        - arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*
              #        - arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
              #- Effect: Allow
              #  Action:
              #    - kinesis:DescribeStream
              #    - kinesis:GetShardIterator
              #    - kinesis:GetRecords
              #    - kinesis:ListShards
              #  Resource:
              #    - !Sub arn:aws:kinesis:${AWS::Region}:${AWS::AccountId}:stream/%FIREHOSE_STREAM_NAME%
              #- Effect: Allow
              #  Action:
              #    - kms:Decrypt
              #  Resource:
              #    - !Sub arn:aws:kms:${AWS::Region}:${AWS::AccountId}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
              #  Condition:
              #    StringEquals:
              #      kms:ViaService: !Sub kinesis.${AWS::Region}.amazonaws.com
              #    StringLike:
              #      kms:EncryptionContext:aws:kinesis:arn: !Sub arn:aws:kinesis:${AWS::Region}:${AWS::AccountId}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%
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
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          DefaultTTL: 0
          MaxTTL: 0
          MinTTL: 0
        #CustomErrorResponses:
        #  - ErrorCode: 403
        #    ResponsePagePath: /
        #    ResponseCode: 200
        #    ErrorCachingMinTTL: 0
        Restrictions:
          GeoRestriction:
            RestrictionType: none
        ViewerCertificate:
          CloudFrontDefaultCertificate: true
        WebACLId: !GetAtt WebAcl.Arn
        Logging:
          Bucket: !GetAtt S3Logs.DomainName
          IncludeCookies: False
          Prefix: cloudfront
##############################
# S3 Bucket (Site Contents)
##############################
  S3SiteContents:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
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
# S3 Bucket (Site Contents Backup)
##############################
  S3SiteContentsBK:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
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
# S3 Bucket (Logs)
##############################
  S3Logs:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    Properties:
      BucketName: !Sub ${Project}-${Env}-bucket-logs
      AccessControl: LogDeliveryWrite
      VersioningConfiguration:
        Status: Suspended
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
##############################
# S3 Bucket Policy (Site Contents)
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
        BucketARN: !GetAtt S3Logs.Arn
        Prefix: waf/
        CompressionFormat: GZIP
        RoleARN: !GetAtt FirehoseRole.Arn
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
          OutputLocation: !Sub s3://${S3Logs}/athena/

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

~~~
