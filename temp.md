```
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // 特定のファイル（test.txt）へのアクセス時のみ判定
    if (uri === '/sp/appl/test.txt') {
        // 切り替え基準日を指定 (例: 2026年3月1日 00:00:00 UTC)
        var targetDate = new Date('2026-02-21T09:00:00Z'); // 18:00:00 JST
        var now = new Date();

        var content = now >= targetDate ? "1" : "0";

        // オリジンへ行かずに直接レスポンスを返す
        return {
            statusCode: 200,
            statusDescription: 'OK',
            headers: {
                'content-type': { value: 'text/plain; charset=UTF-8' },
                'cache-control': { value: 'no-cache, no-store, must-revalidate' } 
            },
            body: content
        };
    }

    // 他のファイルはそのままオリジンへ
    return request;
}



{
  "response": {
    "statusCode": 200,
    "statusDescription": "OK",
    "headers": {
      "cache-control": {
        "value": "no-cache, no-store, must-revalidate"
      },
      "content-type": {
        "value": "text/plain; charset=UTF-8"
      }
    },
    "cookies": {},
    "body": {
      "encoding": "text",
      "data": "0"
    }
  }
}


{
  "response": {
    "statusCode": 200,
    "statusDescription": "OK",
    "headers": {
      "cache-control": {
        "value": "no-cache, no-store, must-revalidate"
      },
      "content-type": {
        "value": "text/plain; charset=UTF-8"
      }
    },
    "cookies": {},
    "body": {
      "encoding": "text",
      "data": "1"
    }
  }
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
