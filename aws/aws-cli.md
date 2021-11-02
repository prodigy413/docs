### aws configure
~~~
aws configure
AWS Access Key ID [None]: xxxxxxxx
AWS Secret Access Key [None]: xxxxxxx
Default region name [None]: ap-northeast-1
Default output format [None]: json
~~~

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

### ECS
- Config metrics manually<br>
https://qiita.com/herohit-tool/items/1b1851f7f4f6748c9372<br>
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html<br>

~~~
aws ecs describe-tasks --cluster greatobi-dev-ecs-01 --tasks 0bdc927a1f864135bd5353614c8e35d7
~~~

### Docker Registry HTTP API V2
https://docs.docker.com/registry/spec/api/#pulling-an-image

~~~
TOKEN=$(aws ecr get-authorization-token --output text --query 'authorizationData[].authorizationToken')
curl -i -H "Authorization: Basic $TOKEN" https://aws_account_id.dkr.ecr.region.amazonaws.com/v2/repository/tags/list
~~~

### Cloudfront associate-alias
https://levelup.gitconnected.com/gradual-deployment-of-web-apps-with-cloudfront-s3-lambda-and-cookies-ce17473afabe<br>
https://d1.awsstatic.com/whitepapers/Building%20Static%20Websites%20on%20AWS.pdf<br>
https://stackoverflow.com/questions/60030262/s3-static-website-w-bluegreen-deployment<br>
https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html

~~~
## Check which cloudfront is using cname cf.great-obi.com. target Cloudfront(E7A040MHQTSGY) is meaningless
aws cloudfront list-conflicting-aliases --alias cf.great-obi.com --distribution-id E2EADWJC134IMV

## Change cname cf.great-obi.com to Cloudfront(E7A040MHQTSGY)
aws cloudfront associate-alias --alias cf.great-obi.com --target-distribution-id E7A040MHQTSGY
~~~

### S3
~~~
aws s3 rm s3://test-path --recursive
aws s3 rm s3://test-path/directory --recursive
aws s3api list-object-versions --bucket test-path
aws s3api list-objects --bucket test-path
aws s3 ls --recursive s3://test-path --summarize
aws s3 sync s3://source s3://target
aws s3 sync s3://source s3://target --exact-timestamps => sync compares size, so if size is same it won't sync. need to compare timestamps
~~~

### Install the Session Manager plugin for the AWS CLI
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-debian<br>

~~~
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb

### Check plugin
session-manager-plugin

The Session Manager plugin is installed successfully. Use the AWS CLI to start a session.
~~~

- Remove versioned s3
~~~python
import boto3

s3 = boto3.resource('s3')
bucket = s3.Bucket('your-bucket-name')
bucket.object_versions.all().delete()

# if you want to remove bucket
#bucket.delete()
~~~
