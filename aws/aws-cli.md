### Install aws cli
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install<br>

~~~
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

## Update
sudo ./aws/install --update
~~~

### aws configure
~~~
aws configure
AWS Access Key ID [None]: xxxxxxxx
AWS Secret Access Key [None]: xxxxxxx
Default region name [None]: ap-northeast-1
Default output format [None]: json

## specific profile
aws configure --profile user02

cat ~/.aws/credentials
cat ~/.aws/config

aws s3 ....... --profile user02
~~~

### Install eksctl
https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html

~~~
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
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
aws ecr get-login-password --region ap-northeast-1 | sudo docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com

## image name format should be repository:tag. (ex: obi-repo:1.0 not obi-repo/nginx:1.0)
docker build -t aws_account_id.dkr.ecr.region.amazonaws.com/repository:1.0 .

docker push aws_account_id.dkr.ecr.region.amazonaws.com/repository:1.0

aws ecr describe-repositories

aws ecr describe-images --repository-name amazonlinux

aws ecr list-images --repository-name my-repo

aws ecr batch-delete-image --repository-name my-repo --image-ids imageTag=tag1 imageTag=tag2

aws ecr batch-delete-image --repository-name my-repo --image-ids imageDigest=sha256:4f70ef7a4d29e8c0c302b13e25962d8f7a0bd304EXAMPLE

aws ecr describe-images --repository-name greatobi-ecr-dev --query "imageDetails[].[imageTags, imageSizeInBytes, imageScanStatus.status]" --output table

aws ecs stop-task --cluster xx --task xx > /dev/null

aws ecs update-service --cluster xx --service xx --force-new-deployment > /dev/null

aws ecs wait services-stable --cluster xx --service xx

aws ecs list-tasks --desired-status 'RUNNING' --cluster xx --service xx

aws ecs execute-command --cluster xx --task xx --container xx --interactive --command "bash"
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
## current cloudfront: E2EADWJC134IMV, current.cloudfront.net
## second cloudfront: E7A040MHQTSGY, second.cloudfront.net
## Check which cloudfront is using cname cf.great-obi.com. target Cloudfront(E7A040MHQTSGY) is meaningless
aws cloudfront list-conflicting-aliases --alias cf.great-obi.com --distribution-id E2EADWJC134IMV

{
    "ConflictingAliasesList": {
        "MaxItems": 100,
        "Quantity": 1,
        "Items": [
            {
                "Alias": "cf.great-obi.com",
                "DistributionId": "*******5PBZ4YV",
                "AccountId": "******555252"
            }
        ]
    }
}

### when from current to second ###
## route 53: add record
## change TTL shorter for faster dns info update
_www.example.com TXT <second cloudfront url>
ex) _cf.great-obi.com TXT second.cloudfront.net

## Change cname cf.great-obi.com to Cloudfront(E7A040MHQTSGY)
aws cloudfront associate-alias --alias cf.great-obi.com --target-distribution-id E7A040MHQTSGY

{
    "ConflictingAliasesList": {
        "MaxItems": 100,
        "Quantity": 1,
        "Items": [
            {
                "Alias": "cf.great-obi.com",
                "DistributionId": "******SC2IL6S",
                "AccountId": "******555252"
            }
        ]
    }
}

### when from second to current ###
## route 53: add record
_www.example.com TXT <second cloudfront url>
ex) _cf.great-obi.com TXT current.cloudfront.net

## Change cname cf.great-obi.com to Cloudfront(E2EADWJC134IMV)
aws cloudfront associate-alias --alias cf.great-obi.com --target-distribution-id E2EADWJC134IMV

{
    "ConflictingAliasesList": {
        "MaxItems": 100,
        "Quantity": 1,
        "Items": [
            {
                "Alias": "cf.great-obi.com",
                "DistributionId": "*******5PBZ4YV",
                "AccountId": "******555252"
            }
        ]
    }
}

## get cloudfront distribution id
aws cloudfront list-distributions --query "DistributionList.Items[*].{id:Id,origin:Origins.Items[0].Id}[?origin=='s3-test-bucket']" --output text
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
aws s3api list-buckets --query "Buckets[].Name"
aws s3 rb --force s3://test
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

### Find AZ

~~~
aws ec2 describe-availability-zones --all-availability-zones
aws ec2 describe-availability-zones --region ap-northeast-1
~~~

### Create kubeconfig

- Path: .kube/config

~~~
aws eks update-kubeconfig --region ap-northeast-1 --name my-cluster
~~~

### Check Lists

~~~
aws iam list-roles --query Roles[].[RoleName,Arn] --output table
aws iam list-policies --query Policies[].[PolicyName,Arn] --output table
aws iam list-users --query Users[].[UserName,Arn] --output table
aws ec2 describe-instances
aws ec2 describe-security-groups
aws ec2 describe-subnets
aws ec2 describe-vpcs
aws logs describe-log-groups
aws opensearch list-domain-names
aws rds describe-db-instances
aws cloudfront list-distributions
aws lambda list-functions
aws s3api list-buckets
aws ec2 describe-volumes  --query Volumes[].[VolumeId] --output table
aws ec2 describe-addresses

~~~

### ALB

~~~
aws elbv2 describe-load-balancers --query LoadBalancers[].LoadBalancerName
aws elbv2 describe-load-balancers --query LoadBalancers[].DNSName
aws elbv2 describe-load-balancers --query LoadBalancers[].LoadBalancersArn
aws elbv2 describe-tags --resource-arns xx --query TagDescriptions[].Tags[].Value
~~~

### Security Group

~~~
aws ec2 describe-security-groups --query 'SEcurityGroups[].{Name:GroupName,ID:GroupId}' --output table
~~~
