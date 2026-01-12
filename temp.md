# Terraformを利用したAWS設定ダウンロード

## Cloudfrontの例

### 各リソースのimport方法を確認

- [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#import)
- [aws_cloudfront_origin_access_control](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control#import)

### Terraform コード作成

- 各リソースのID確認
```
aws cloudfront list-distributions --query "DistributionList.Items[].[Id,Comment]"
aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[].[Name,Id]"
```

- main.tf
```yaml
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
```

- import.tf
```yaml
import {
  to = aws_cloudfront_distribution.test
  id = "E3LAAE8FQJZYO3"
}

import {
  to = aws_cloudfront_origin_access_control.test
  id = "EPSS9VYXOAJ01"
}
```

### 設定ダウンロード

```
# 初期化
terraform init

# 設定ダウンロード
terraform plan -generate-config-out=cloudfront.tf

# stateファイルにダウンロード（リソースをTerraform管理対象にする）
terraform apply
```
