~~~
# This role is needed for vpc based es
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

data "aws_iam_policy_document" "policy_01" {
  statement {
    sid       = "${local.product_name}-${local.environment}-opensearch-01"
    effect    = "Allow"
    actions   = ["es:*"]
    resources = ["arn:aws:ap-northeast-1:844065555252:domain/${local.product_name}-es-${local.environment}-01/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
  statement {
    sid       = "${local.product_name}-${local.environment}-opensearch-log"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents", "logs:PutLogEventsBatch", "logs:CreateLogStream"]
    resources = ["arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/OpenSearchService/domains/${local.product_name}-es-${local.environment}-01/*"]
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

# Elsaticsearch configuration
resource "aws_elasticsearch_domain" "elasticsearch_01" {
  domain_name           = "${local.product_name}-es-${local.environment}-01"
  elasticsearch_version = "OpenSearch_1.0"

  #vpc_options {
  #  subnet_ids         = [values(aws_subnet.subnet_01)[0].id]
  #  security_group_ids = [aws_security_group.allow_https.id]
  #}

  cluster_config {
    #instance_type = "t2.micro.elasticsearch"
    instance_type = "t3.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  access_policies = data.aws_iam_policy_document.policy_01.json

  #  access_policies = <<POLICY
  #{
  #  "Version": "2012-10-17",
  #  "Statement": [
  #    {
  #      "Effect": "Allow",
  #      "Principal": {
  #        "AWS": [
  #          "*"
  #        ]
  #      },
  #      "Action": [
  #        "es:*"
  #      ],
  #      "Resource": "arn:aws:${var.aws_region}:844065555252:domain/${local.product_name}-es-${local.environment}-01*"
  #    }
  #  ]
  #}
  #POLICY

  #  access_policies = <<POLICY
  #{
  #  "Version": "2012-10-17",
  #  "Statement": [
  #    {
  #      "Effect": "Allow",
  #      "Principal": "*",
  #      "Action": "es:*",
  #      "Resource": "arn:aws:${var.aws_region}:844065555252:domain/${local.product_name}-es-${local.environment}-01*"
  #    }
  #  ]
  #}
  #POLICY

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.os_log_01.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  depends_on = [aws_cloudwatch_log_group.os_log_01]

  tags = {
    Domain = "${local.product_name}-es-${local.environment}-01"
  }
}

output "opensearch_name" {
  value = aws_elasticsearch_domain.elasticsearch_01.domain_name
}

output "opensearch_url" {
  value = aws_elasticsearch_domain.elasticsearch_01.endpoint
}


#/aws/OpenSearchService/domains/greatobi-es-dev-01/search-logs
#/aws/OpenSearchService/domains/greatobi-es-dev-01/index-logs
#/aws/OpenSearchService/domains/greatobi-es-dev-01/application-logs
#/aws/OpenSearchService/domains/greatobi-es-dev-01/audit-logs

#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "es.amazonaws.com"
#      },
#      "Action": [
#        "logs:PutLogEvents",
#        "logs:CreateLogStream"
#      ],
#      "Resource": "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/OpenSearchService/domains/greatobi-es-dev-01/search-logs:*"
#    }
#  ]
#}
#
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "es.amazonaws.com"
#      },
#      "Action": [
#        "logs:PutLogEvents",
#        "logs:CreateLogStream"
#      ],
#      "Resource": "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/OpenSearchService/domains/greatobi-es-dev-01/index-logs:*"
#    }
#  ]
#}
#
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "es.amazonaws.com"
#      },
#      "Action": [
#        "logs:PutLogEvents",
#        "logs:CreateLogStream"
#      ],
#      "Resource": "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/OpenSearchService/domains/greatobi-es-dev-01/application-logs:*"
#    }
#  ]
#}
#
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "es.amazonaws.com"
#      },
#      "Action": [
#        "logs:PutLogEvents",
#        "logs:CreateLogStream"
#      ],
#      "Resource": "arn:aws:logs:ap-northeast-1:844065555252:log-group:/aws/OpenSearchService/domains/greatobi-es-dev-01/audit-logs:*"
#    }
#  ]
#}
~~~
