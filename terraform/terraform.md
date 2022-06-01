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

### Download Command
https://www.terraform.io/downloads.html

~~~
$ wget https://releases.hashicorp.com/terraform/1.0.2/terraform_1.0.2_linux_amd64.zip

$ unzip terraform_1.0.2_linux_amd64.zip
Archive:  terraform_1.0.2_linux_amd64.zip
  inflating: terraform               

$ rm -rf terraform_1.0.2_linux_amd64.zip

$ sudo mv terraform /usr/local/bin/

$ terraform version
Terraform v1.0.2
on linux_amd64

~~~

 - AWS samples
~~~tf
provider "aws" {
  region  = "ap-northeast-1"
}

resource "aws_iam_user" "test_user" {
  name = "obi"
  #path = "/system/"

  tags = {
    Name = "Jinhyuk Choi"
  }
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.test_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
~~~

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
