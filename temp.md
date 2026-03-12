```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "cloudfront:*",
            "Resource": "arn:aws:cloudfront::123456789012:distribution/EDFDVBD632BHDS"
        },
        {
            "Effect": "Allow",
            "Action": "cloudfront:ListDistributions",
            "Resource": "*"
        }
    ]
}




{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:DescribeFunction",
                "cloudfront:UpdateFunction",
                "cloudfront:PublishFunction",
                "cloudfront:DeleteFunction",
                "cloudfront:TestFunction"
            ],
            "Resource": "arn:aws:cloudfront::123456789012:function/MyCustomFunction"
        },
        {
            "Effect": "Allow",
            "Action": "cloudfront:ListFunctions",
            "Resource": "*"
        }
    ]
}





{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SpecificDistributionFullLikeAccess",
      "Effect": "Allow",
      "Action": [
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:CreateInvalidation",
        "cloudfront:ListInvalidations",
        "cloudfront:CreateMonitoringSubscription",
        "cloudfront:DeleteMonitoringSubscription",
        "cloudfront:AllowVendedLogDeliveryForResource",
        "cloudfront:TagResource",
        "cloudfront:UntagResource"
      ],
      "Resource": "arn:aws:cloudfront::<AWSアカウントID>:distribution/<DistributionId>"
    }
  ]
}





{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SpecificFunctionFullLikeAccess",
      "Effect": "Allow",
      "Action": [
        "cloudfront:GetFunction",
        "cloudfront:DescribeFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:DeleteFunction",
        "cloudfront:PublishFunction",
        "cloudfront:TestFunction"
      ],
      "Resource": "arn:aws:cloudfront::<AWSアカウントID>:function/<FunctionName>"
    }
  ]
}
```

```terraform
# aws s3api get-bucket-acl --bucket obi-test-bucket-20260209 --query "Owner.ID" --output text
# aws s3api list-buckets --query "Owner.ID" --output text

resource "aws_s3_bucket_acl" "example" {
  acl    = null
  bucket = "bucket"
  region = "ap-northeast-1"
  access_control_policy {
    grant {
      permission = "FULL_CONTROL"
      grantee {
        email_address = null
        id            = "ididididididid"
        type          = "CanonicalUser"
        uri           = null
      }
    }
    owner {
      id = "ididididididid"
    }
  }
}

resource "aws_s3_bucket_request_payment_configuration" "example" {
  bucket = "bucket"
  payer  = "BucketOwner"
  region = "ap-northeast-1"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = "bucket"
  region = "ap-northeast-1"
  rule {
    blocked_encryption_types = []
    bucket_key_enabled       = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = null
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = "bucket"
  ignore_public_acls      = true
  region                  = "ap-northeast-1"
  restrict_public_buckets = true
  skip_destroy            = null
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = "bucket"
  region = "ap-northeast-1"
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = "bucket"
  mfa    = null
  region = "ap-northeast-1"
  versioning_configuration {
    status = "Disabled"
  }
}

```
