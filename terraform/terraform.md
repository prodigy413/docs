### Udemy github link
https://github.com/stacksimplify/terraform-on-aws-ec2

### Terraform Command
https://www.terraform.io/docs/cli/commands/index.html

### Terraform providers & modules page
https://registry.terraform.io/

### Best practices
https://www.terraform-best-practices.com/

### Terraform Github actions sample
https://learn.hashicorp.com/tutorials/terraform/github-actions

### Terraform log configuration
https://www.suse.com/support/kb/doc/?id=000020022

~~~
$ terraform init

$ terraform plan

$ terraform apply

$ terraform destroy

### Get current configurations

Usage: terraform show [options] [file]

$ terraform show

$ terraform show -json

$ terraform show -json | jq

### Add auto yes flag
$ terraform apply -auto-approve

### Create with variable file
$ terraform plan -var-file="../1_variables/terraform.tfvars" -out file_for_apply
$ terraform apply -auto-approve "file_for_apply"

### Destroy with variable file
$ terraform plan -var-file="../1_variables/terraform.tfvars" -destroy -out file_for_apply
$ terraform apply -auto-approve "file_for_apply"
~~~

### Index function
https://www.terraform.io/docs/language/functions/index_function.html

### Comments

~~~
# comment-1

// comment-2

/*
comment-3
*/
~~~

### Use json files
https://beyondjapan.com/blog/2020/04/fargate-supported-efs/

### IAM
- Create User/Group<br>
https://qiita.com/ldr/items/427f6cf7ed14f4187cd2

### Terraform Blogs
https://y-ohgi.com/introduction-terraform/<br>

### Directory structure sample
https://www.m3tech.blog/entry/2020/07/27/150000

### Terraform AWS Cloud Control Provider
https://www.hashicorp.com/blog/announcing-terraform-aws-cloud-control-provider-tech-preview

### Terraform Templates
https://htnosm.hatenablog.com/entry/2018/05/04/090000

### etc
https://htnosm.hatenablog.com/entry/2017/04/10/090000

### VS Code terraform fmt
https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform<br>

~~~
### settings.json
{
    "[terraform]": {
        "editor.formatOnSave": true
    }
}
~~~

### Terraform Console / Terminal

<https://www.terraform.io/cli/commands/console>

~~~
terraform console
echo 'split(",", "foo,bar,baz")' | terraform console
exit
~~~

### Terraform: Error acquiring the state lock: ConditionalCheckFailedException

~~~
terraform force-unlock xxxxxxx-xxxxxxx-xxxxxxxxx
terraform force-unlock -force xxxxxxx-xxxxxxx-xxxxxxxxx
terraform plan -lock=false
~~~

### Debug

<https://www.terraform.io/internals/debugging>

~~~
export TF_LOG=TRACE
~~~


### Remove resource from state

<https://www.terraform.io/cli/commands/state/rm>

~~~
terraform state rm -dry-run aws_cloudfront_origin_access_identity.cloud_front_01
terraform state rm aws_cloudfront_origin_access_identity.cloud_front_01
~~~

### Change resource name of state

<https://www.terraform.io/cli/commands/state/mv>

~~~
terraform state mv -dry-run aws_cloudfront_origin_access_identity.test module.oai.aws_cloudfront_origin_access_identity.cloud_front_01[0]
terraform state mv -dry-run aws_s3_bucket_policy.policy_01 module.oai.aws_s3_bucket_policy.policy_01[0]
~~~

### Remove all lines starting with visual code

~~~
^.*(word1|word2|word3).*\n
~~~
