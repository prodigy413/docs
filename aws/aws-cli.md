### User
~~~
$ aws iam create-user --user-name test
$ aws iam list-users --query Users[].[UserName,Arn] --output table

## Get current user info
$ aws sts get-caller-identity
{
    "UserId": "AIDA4JBR2IM2EH45XBK67",
    "Account": "844065555252",
    "Arn": "arn:aws:iam::844065555252:user/test"
}

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

