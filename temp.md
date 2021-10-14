~~~yaml
resource "aws_ecs_cluster" "ecs_01" {
  name = "${local.product_name}-${local.environment}-ecs-01"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_log_01.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "task_definition_01" {
  family                   = "test"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_taskexec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(yamldecode(file("container.yaml")))
}

resource "aws_ecs_service" "ecs_svc_01" {
  name                   = "${local.product_name}-${local.environment}-ecs-svc-01"
  cluster                = aws_ecs_cluster.ecs_01.id
  task_definition        = aws_ecs_task_definition.task_definition_01.arn
  desired_count          = 1
  enable_execute_command = true
  force_new_deployment   = true
  launch_type            = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_01.arn
    container_name   = "nginx_01"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  platform_version = "1.4.0"
}

~~~

~~~yaml
resource "aws_ecr_repository" "obi_ecr_01" {
  name                 = "${local.product_name}-ecr-${local.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

output "repository_url" {
  value = aws_ecr_repository.obi_ecr_01.repository_url
}
~~~

~~~yaml
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

resource "aws_iam_role" "ecs_taskexec_role" {
  name               = "${local.product_name}-${local.environment}-ecs-taskexec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_taskexec_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_taskexec_role" {
  role       = aws_iam_role.ecs_taskexec_role.name
  policy_arn = data.aws_iam_policy.ecs_taskexec_role.arn
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

~~~

~~~yaml
# ALB01
resource "aws_lb" "alb_01" {
  name               = "${local.product_name}-${local.environment}-alb-01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]

  enable_deletion_protection = local.deletion_protection

  tags = {
    name = "${local.product_name}-${local.environment}-alb-01"
  }
}

resource "aws_lb_target_group" "tg_01" {
  name        = "${local.product_name}-${local.environment}-target-group-01"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_01.id
  target_type = "ip"

  health_check {
    interval            = 300
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_lb_listener" "alb_listener_01" {
  load_balancer_arn = aws_lb.alb_01.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_01.arn
  }
}

# ALB02
#resource "aws_lb" "alb_02" {
#  name               = "${local.product_name}-${local.environment}-alb-02"
#  internal           = false
#  load_balancer_type = "application"
#  security_groups    = [aws_security_group.ecs_sg.id]
#  subnets            = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
#
#  enable_deletion_protection = local.deletion_protection
#
#  tags = {
#    name = "${local.product_name}-${local.environment}-alb-02"
#  }
#}
#
#resource "aws_lb_target_group" "tg_02" {
#  name        = "${local.product_name}-${local.environment}-target-group-02"
#  port        = "80"
#  protocol    = "HTTP"
#  vpc_id      = aws_vpc.vpc_01.id
#  target_type = "ip"
#}
#
#resource "aws_lb_listener" "alb_listener_02" {
#  load_balancer_arn = aws_lb.alb_02.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.tg_02.arn
#  }
#}
#
~~~

~~~yaml
---

- name: "nginx_01"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:nginx01"
  portMappings:
    - containerPort: 80
      hostPort: 80
  linuxParameters:
    initProcessEnabled: true
- name: "mariadb_01"
  image: "844065555252.dkr.ecr.ap-northeast-1.amazonaws.com/greatobi-ecr-dev:mariadb01"
  portMappings:
    - containerPort: 3306
      hostPort: 3306
  linuxParameters:
    initProcessEnabled: true

~~~
