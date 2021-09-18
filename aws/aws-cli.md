### User
~~~
$ aws iam create-user --user-name test
$ aws iam list-users --query Users[].[UserName,Arn] --output table

## Get current user info
$ aws sts get-caller-identity
~~~

### Group
~~~
$ aws iam create-qroup --group-name test
$ aws iam list-groups --query Groups[].GroupName --output table
$ aws iam add-user-to-group --user-name test --group-name test
~~~

### Policy

 - test_policy.json
~~~json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "iam:GenerateCredentialReport",
              "iam:GenerateServiceLastAccessedDetails",
              "iam:Get*",
              "iam:List*",
              "iam:SimulateCustomPolicy",
              "iam:SimulatePrincipalPolicy"
          ],
          "Resource": "*"
      }
  ]
}
~~~

~~~
$ aws iam put-user-policy --user-name test --policy-name test_policy --policy-document file://test_policy.json

$ aws iam get-user-policy --user-name test --policy-name test_policy
{
    "UserName": "test",
    "PolicyName": "test_policy",
    "PolicyDocument": {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:GenerateCredentialReport",
                    "iam:GenerateServiceLastAccessedDetails",
                    "iam:Get*",
                    "iam:List*",
                    "iam:SimulateCustomPolicy",
                    "iam:SimulatePrincipalPolicy"
                ],
                "Resource": "*"
            }
        ]
    }
}

$ aws iam delete-user-policy --user-name test --policy-name test_policy
~~~

### Instance
~~~
$ aws ec2 describe-instances

$ aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" --query "Reservations[].Instances[].Tags"

$ aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" --query "Reservations[].Instances[].InstanceId"
~~~

### Vpc
~~~
$ aws ec2 describe-vpcs

$ aws ec2 describe-vpcs --query "Vpcs[].VpcId"
~~~

### Log Group
- Reference<br>
https://dev.classmethod.jp/articles/operate-cloudwatch-log-group-using-cli-for-beginners/

~~~
$ aws logs describe-log-groups --query "logGroups[].logGroupName"
~~~

### Check service support
~~~
### Determine which Availability Zones support your instance type
$ aws ec2 describe-instance-type-offerings --location-type availability-zone  --filters Name=instance-type,Values=t3.micro --region ap-northeast-1 --output table
~~~

### ECR
https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html

~~~
## You should set username AWS not your IAM user.
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com

## image name format should be repository:tag. (ex: obi-repo:1.0 not obi-repo/nginx:1.0)
docker build -t aws_account_id.dkr.ecr.region.amazonaws.com/repository:1.0 .

docker push aws_account_id.dkr.ecr.region.amazonaws.com/repository:1.0

aws ecr describe-repositories

aws ecr describe-images --repository-name amazonlinux

aws ecr list-images --repository-name my-repo

aws ecr batch-delete-image --repository-name my-repo --image-ids imageTag=tag1 imageTag=tag2

aws ecr batch-delete-image --repository-name my-repo --image-ids imageDigest=sha256:4f70ef7a4d29e8c0c302b13e25962d8f7a0bd304EXAMPLE

aws ecr describe-images --repository-name greatobi-ecr-dev --query "imageDetails[].[imageTags, imageSizeInBytes, imageScanStatus.status]" --output table
~~~
