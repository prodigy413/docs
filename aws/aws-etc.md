### Download & install cloudwatch agent
- Link:<br>
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-cloudwatch-agent-commandline.html<br>
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-commandline-fleet.html

- Policy:<br>
https://qiita.com/hayao_k/items/d983177510b3b3a69561

~~~
$ wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
$ sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
$ sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s
$ sudo systemctl status amazon-cloudwatch-agent.service
$ cat /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log
~~~

### Check console login address
AWS Console - [IAM] - [Dashboard] - Sign-in URL for IAM users in this account<br>
My test lab: https://844065555252.signin.aws.amazon.com/console

### Fargate
- Fargate platform version<br>
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
- Container Definition<br>
https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html

### Restricting access to Systems Manager parameters using IAM policies
https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-access.html

### Assigning parameter policies
https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-policies.html

### AWS Lambda & Good aws site - DENET
https://blog.denet.co.jp/lambda-python-zip/

### VPC Limitations
https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html
