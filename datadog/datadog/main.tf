locals {
  datadog_api_key = "81361cca1bd36b562f809768c63d9f66"
  datadog_app_key = "d9407221f7031d5d543c62f99d74456cf856abe1"
  account_id      = "844065555252"
}

terraform {
  required_version = "~> 1.0.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.6.0"
    }
  }
}

provider "datadog" {
  api_key = local.datadog_api_key
  app_key = local.datadog_app_key
}
