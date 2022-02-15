~~~
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
  environment:
    - name: "TEST"
      value: "haha"
    - name: "S3_BUCKET"
      value: "obi-test-log-20220215"  
  user: "0"
  
  
  
  
  
  
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
    bucket ${S3_BUCKET}
    total_file_size 10M
    upload_timeout 10m
    s3_key_format /%Y/%m/%d/$TAG/%H-%M-%S-$UUID.gz
    use_put_object On
    compression gzip
~~~
