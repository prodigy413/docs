### Udemy github link
https://github.com/stacksimplify/terraform-on-aws-ec2

### Terraform Command
https://www.terraform.io/docs/cli/commands/index.html

### Terraform providers & modules page
https://registry.terraform.io/

### Best practices
https://www.terraform-best-practices.com/

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

### IAM
- Create User/Group<br>
https://qiita.com/ldr/items/427f6cf7ed14f4187cd2

### Terraform Blogs
https://y-ohgi.com/introduction-terraform/<br>

### Directory structure sample
https://www.m3tech.blog/entry/2020/07/27/150000
