~~~yaml
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
}
~~~

~~~yaml
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
#      log_group_name: "firelens-nginx"
#      log_stream_prefix: "obi-"
#      log-driver-buffer-limit: "2097152"
  logConfiguration:
    logDriver: "awsfirelens"
    options:
      Name: "datadog"
      Host: "http-intake.logs.datadoghq.com"
#      apiKey: "81361cca1bd36b562f809768c63d9f66"
      dd_service: "nginx-service"
      dd_source: "nginx"
      dd_tags: "env:dev"
      TLS: "on"
      provider: "ecs"
    secretOptions:
      - name: "apiKey"
        valueFrom: "arn:aws:ssm:ap-northeast-1:844065555252:parameter/datadog-api-key-01"
  linuxParameters:
    initProcessEnabled: true
- name: "firelens-01"
  image: "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
  essential: true
  firelensConfiguration:
    type: "fluentbit"

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
~~~
