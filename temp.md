~~~
  S3Logs:
    Type: AWS::S3::Bucket
    #DeletionPolicy: Retain
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
      NotificationConfiguration:
        LambdaConfigurations:
          - Event: s3:ObjectCreated:*
            Function: !Ref MoveLogsLambdaArn
            Filter:
              S3Key:
                Rules:
                - Name: prefix
                  Value: cloudfront-source
~~~
