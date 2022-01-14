~~~
resource "aws_ecs_cluster" "ecs_01" {
  name = "${local.product_name}-${local.environment}-ecs-01"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

    configuration {
      execute_command_configuration {
        logging = "NONE"
      }
    }

  #  configuration {
  #    execute_command_configuration {
  #      logging = "OVERRIDE"
  #      log_configuration {
  #        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_log_01.name
  #      }
  #    }
  #  }
  depends_on = [aws_cloudwatch_log_group.ecs_log_01]
}

resource "aws_ecs_task_definition" "task_definition_01" {
  family                   = "test"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  #  ephemeral_storage {
  #    size_in_gib = 30
  #  }

  execution_role_arn = aws_iam_role.ecs_taskexec_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode(yamldecode(file("container.yaml")))
}

resource "aws_ecs_service" "ecs_svc_01" {
  name                               = "${local.product_name}-${local.environment}-ecs-svc-01"
  cluster                            = aws_ecs_cluster.ecs_01.id
  task_definition                    = aws_ecs_task_definition.task_definition_01.arn
  desired_count                      = 2
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  enable_execute_command             = true
  force_new_deployment               = true
  launch_type                        = "FARGATE"

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
