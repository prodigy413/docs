~~~tf
resource "aws_db_instance" "rds_01" {
  engine         = "mariadb"
  engine_version = "10.4.13"
  identifier     = "${local.product_name}-db-${local.environment}-01"
  instance_class = "db.t2.micro"
  name           = "${local.product_name}db01"

  allocated_storage = 10
  #max_allocated_storage = 100
  #storage_type          = "gp2"
  #storage_encrypted     = true

  enabled_cloudwatch_logs_exports = ["general"]

  vpc_security_group_ids = [aws_security_group.allow_db_access.id]
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.subnet_db_01.name

  username = "admin"
  password = data.aws_ssm_parameter.db_pw_01.value

  parameter_group_name = aws_db_parameter_group.db_parameter_01.name
  skip_final_snapshot  = true

  depends_on = [
    aws_cloudwatch_log_group.log_01,
    aws_db_parameter_group.db_parameter_01
  ]
}

resource "aws_db_parameter_group" "db_parameter_01" {
  name   = "db-01-parameger-group-${local.environment}-01"
  family = "mariadb10.4"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  parameter {
    name  = "general_log"
    value = 1
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  #  parameter {
  #    apply_method = "pending-reboot"
  #    name  = "binlog_format"
  #    value = "ROW"
  #  }
  #
  #  parameter {
  #    apply_method = "pending-reboot"
  #    name  = "binlog_row_image"
  #    value = "full"
  #  }
  #
  #  parameter {
  #    apply_method = "pending-reboot"
  #    name  = "binlog_checksum"
  #    value = "NONE"
  #  }
  #
  # log query history
  #parameter {
  #  name  = "general_log"
  #  value = "1"
  #}
}

resource "aws_db_subnet_group" "subnet_db_01" {
  name       = "test-db"
  subnet_ids = values(aws_subnet.subnet_01)[*].id
}

output "db_pw_01" {
  value     = data.aws_ssm_parameter.db_pw_01.value
  sensitive = true
}
~~~
