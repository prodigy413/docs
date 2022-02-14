~~~
#obi-test-log-20220212
#{
#	"Version": "2012-10-17",
#	"Statement": [
#		{
#			"Sid": "policy-01",
#			"Principal": "*",
#			"Effect": "Allow",
#			"Action": ["s3:PutObject"],
#			"Resource": ["arn:aws:s3:::obi-test-log-20220212/*"]
#		}
#	]
#}

#{
#	"Version": "2012-10-17",
#	"Statement": [
#		{
#			"Sid": "policy-01",
#			"Effect": "Allow",
#			"Principal": {"AWS": "arn:aws:iam::844065555252:role/greatobi-dev-ecs-task-role"},
#			"Action": "s3:PutObject",
#			"Resource": "arn:aws:s3:::obi-test-log-20220212/*"
#		}
#	]
#}











data "aws_iam_policy" "ecs_taskexec_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_taskexec_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_role" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:PutParameters"
    ]
    resources = ["arn:aws:ssm:*:*:parameter/datadog-api-key-01"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::obi-test-log-20220212"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:ap-northeast-1:844065555252:log-group:/ecs/nginx:*"]
  }
}

data "aws_iam_policy" "ssm_readonly" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

data "aws_iam_policy" "cloudwatch_agent_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.product_name}-${local.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_taskexec_role.json
}

resource "aws_iam_policy" "ecs_task_role" {
  name   = "${local.product_name}-${local.environment}-ecs-task-role"
  policy = data.aws_iam_policy_document.ecs_task_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_01" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent_policy.arn
}

resource "aws_iam_role" "ecs_taskexec_role" {
  name               = "${local.product_name}-${local.environment}-ecs-taskexec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_taskexec_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_taskexec_role" {
  role       = aws_iam_role.ecs_taskexec_role.name
  policy_arn = data.aws_iam_policy.ecs_taskexec_role.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_02" {
  role       = aws_iam_role.ecs_taskexec_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_readonly" {
  role       = aws_iam_role.ecs_taskexec_role.name
  policy_arn = data.aws_iam_policy.ssm_readonly.arn
}











---

- name: "nginx_01"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:nginx01"
  portMappings:
    - containerPort: 80
      hostPort: 80
#  healthCheck:
#    command: [
#      "CMD-SHELL",
#      "curl -so /dev/null -w %{http_code} http://localhost/test | grep 200 || exit 1"
#    ]
#    interval: 50
#    retries: 2
##    startPeriod: 60
#    startPeriod: 120
#    timeout: 10
#  logConfiguration:
#    logDriver: "awslogs"
#    options:
#      awslogs-group: "/ecs/nginx"
#      awslogs-region: "ap-northeast-1"
#      awslogs-stream-prefix: "ecs"
#  logConfiguration:
#    logDriver: "awsfirelens"
#    options:
#      Name: "cloudwatch"
#      region: "ap-northeast-1"
#      log_group_name: "/ecs/nginx"
#      log_stream_prefix: "obi-"
#      log-driver-buffer-limit: "2097152"
  logConfiguration:
    logDriver: "awsfirelens"
    options: null
    secretOptions: null
#  logConfiguration:
#    logDriver: "awsfirelens"
#    options:
#      Name: "datadog"
#      Host: "http-intake.logs.datadoghq.com"
#      dd_service: "nginx-service"
#      dd_source: "nginx"
#      dd_tags: "env:dev"
#      TLS: "on"
#      provider: "ecs"
#    secretOptions:
#      - name: "apiKey"
#        valueFrom: "arn:aws:ssm:ap-northeast-1:844065555252:parameter/datadog-api-key-01"
#  secrets:
#    - name: "DB_PASSWORD"
#      valueFrom: "arn:aws:ssm:ap-northeast-1:844065555252:parameter/datadog-api-key-01"
  linuxParameters:
    initProcessEnabled: true
#- name: "mariadb_01"
#  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:mariadb01"
#  portMappings:
#    - containerPort: 3306
#      hostPort: 3306
#    - containerPort: 4000
#      hostPort: 4000
##  entryPoint:
##    - sh
##    - -c
##  command:
##    - "touch /tmp/test.txt; sleep infinity"
##    - "touch /tmp/test.txt; flask run --host=0.0.0.0"
##    - "/bin/sh -c \"touch /tmp/test.txt; flask run --host=0.0.0.0\""
#  linuxParameters:
#    initProcessEnabled: true
#- name: "agent_01"
#  image: "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"
#  secrets:
#    - name: "CW_CONFIG_CONTENT"
#      valueFrom: "greatobi-dev-parameter"
#  linuxParameters:
#    initProcessEnabled: true
- name: "log_router"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:fluent-bit-01"
#  image: "public.ecr.aws/aws-observability/aws-for-fluent-bit:2.21.6"
  essential: true
  firelensConfiguration:
    type: "fluentbit"
    options:
      config-file-type: "file"
      config-file-value: "/fluent-bit/etc/custom-log.conf"
  user: "0"
  
  
  
  
  
  
  
  
  #FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:2.22.0
FROM amazon/aws-for-fluent-bit:2.22.0

COPY ./custom-log.conf /fluent-bit/etc/custom-log.conf







[OUTPUT]
    Name   cloudwatch
    Match  **
    region ap-northeast-1
    log_group_name /ecs/nginx
    log_stream_prefix obi-

[OUTPUT]
    Name s3
    Match **
    region ap-northeast-1
    bucket obi-test-log-20220212
    total_file_size 10M
    upload_timeout 10m
    s3_key_format /%Y/%m/%d/$TAG/%H-%M-%S-$UUID.gz
    use_put_object On
    compression gzip







~~~
