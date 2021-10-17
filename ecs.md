### awslogs
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html

### ECS Container access config
https://docs.aws.amazon.com/AmazonECS/latest/userguide/ecs-exec.html<br>
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-debian

~~~
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
~~~

~~~yaml
---

- name: "nginx_01"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:nginx01"
  portMappings:
    - containerPort: 80
      hostPort: 80
  logConfiguration:
    logDriver: "awslogs"
    options:
      awslogs-group: "/ecs/nginx"
      awslogs-region: "ap-northeast-1"
#        - awslogs-region: "us-east-1"
      awslogs-stream-prefix: "ecs"
  linuxParameters:
    initProcessEnabled: true
- name: "mariadb_01"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:mariadb01"
  portMappings:
    - containerPort: 3306
      hostPort: 3306
    - containerPort: 4000
      hostPort: 4000
#  entryPoint:
#    - sh
#    - -c
#  command:
#    - "touch /tmp/test.txt; sleep infinity"
#    - "touch /tmp/test.txt; flask run --host=0.0.0.0"
#    - "/bin/sh -c \"touch /tmp/test.txt; flask run --host=0.0.0.0\""
  linuxParameters:
    initProcessEnabled: true
~~~
