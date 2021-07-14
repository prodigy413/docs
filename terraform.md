### Terraform Command
https://www.terraform.io/docs/cli/commands/index.html

### Download Command

https://www.terraform.io/downloads.html

~~~
$ wget https://releases.hashicorp.com/terraform/0.15.3/terraform_0.15.3_linux_amd64.zip

$ unzip terraform_0.15.3_linux_amd64.zip
Archive:  terraform_0.15.3_linux_amd64.zip
  inflating: terraform               

$ rm -rf terraform_0.15.3_linux_amd64.zip 

$ sudo mv terraform /usr/local/bin/

$ terraform version
Terraform v0.15.3
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

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v3.39.0...
- Installed hashicorp/aws v3.39.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
obi@obi:~/test/terraform$ terraform plan
provider.aws.region
  The region where AWS operations will take place. Examples
  are us-east-1, us-west-2, etc.

  Enter a value: ^C

Interrupt received.
Please wait for Terraform to exit or data loss may occur.
Gracefully shutting down...

^C
Two interrupts received. Exiting immediately. Note that data loss may have occurred.

╷
│ Error: operation canceled
│ 
│ 
╵

$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_user.test_user will be created
  + resource "aws_iam_user" "test_user" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "obi"
      + path          = "/"
      + tags          = {
          + "Name" = "Jinhyuk Choi"
        }
      + tags_all      = {
          + "Name" = "Jinhyuk Choi"
        }
      + unique_id     = (known after apply)
    }

  # aws_iam_user_policy_attachment.test-attach will be created
  + resource "aws_iam_user_policy_attachment" "test-attach" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
      + user       = "obi"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_user.test_user will be created
  + resource "aws_iam_user" "test_user" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "obi"
      + path          = "/"
      + tags          = {
          + "Name" = "Jinhyuk Choi"
        }
      + tags_all      = {
          + "Name" = "Jinhyuk Choi"
        }
      + unique_id     = (known after apply)
    }

  # aws_iam_user_policy_attachment.test-attach will be created
  + resource "aws_iam_user_policy_attachment" "test-attach" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
      + user       = "obi"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_user.test_user: Creating...
aws_iam_user.test_user: Creation complete after 2s [id=obi]
aws_iam_user_policy_attachment.test-attach: Creating...
aws_iam_user_policy_attachment.test-attach: Creation complete after 3s [id=obi-20210507135749548500000001]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ terraform destroy
aws_iam_user.test_user: Refreshing state... [id=obi]
aws_iam_user_policy_attachment.test-attach: Refreshing state... [id=obi-20210507135749548500000001]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_iam_user.test_user will be destroyed
  - resource "aws_iam_user" "test_user" {
      - arn           = "arn:aws:iam::844065555252:user/obi" -> null
      - force_destroy = false -> null
      - id            = "obi" -> null
      - name          = "obi" -> null
      - path          = "/" -> null
      - tags          = {
          - "Name" = "Jinhyuk Choi"
        } -> null
      - tags_all      = {
          - "Name" = "Jinhyuk Choi"
        } -> null
      - unique_id     = "AIDA4JBR2IM2A2UDOESUD" -> null
    }

  # aws_iam_user_policy_attachment.test-attach will be destroyed
  - resource "aws_iam_user_policy_attachment" "test-attach" {
      - id         = "obi-20210507135749548500000001" -> null
      - policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" -> null
      - user       = "obi" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_iam_user_policy_attachment.test-attach: Destroying... [id=obi-20210507135749548500000001]
aws_iam_user_policy_attachment.test-attach: Destruction complete after 1s
aws_iam_user.test_user: Destroying... [id=obi]
aws_iam_user.test_user: Destruction complete after 3s

Destroy complete! Resources: 2 destroyed.


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
