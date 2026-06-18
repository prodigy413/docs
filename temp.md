```
data "ibm_resource_group" "rg" {
  name = local.resource_group_name
}




resource "ibm_resource_instance" "cos" {
  name              = local.instance_name
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.rg.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = local.bucket_name
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = "jp-tok"
  storage_class        = "standard"

  force_delete = true
}

resource "ibm_cos_bucket_lifecycle_configuration" "lifecycle" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location

  lifecycle_rule {
    rule_id = "expire-after-30-days"
    status  = "enable"

    filter {}

    expiration {
      days = 30
    }
  }
}

resource "ibm_resource_key" "cos_credential" {
  name                 = "${local.instance_name}-credential"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id

  parameters = {
    HMAC = true
  }
}





locals {
  resource_group_name = "test"
  instance_name       = "obi-test-object-storage-01"
  bucket_name         = "obi-test-bucket-01"
}

```
