### Udemy github link
https://github.com/stacksimplify/terraform-on-aws-ec2

### Terraform Command
https://www.terraform.io/docs/cli/commands/index.html

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
terraform apply -auto-approve
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
