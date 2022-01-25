~~~
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget
resource "aws_budgets_budget" "obi" {
  name         = "obi-budget"
  budget_type  = "COST"
  limit_amount = "4"
  limit_unit   = "USD"
  #  time_period_end   = "2030-12-31_00:00"
  time_period_start = "2022-01-01_00:00"
  time_unit         = "MONTHLY"

  #  cost_filter {
  #    name = "Service"
  #    values = [
  #      "Amazon Elastic Compute Cloud - Compute",
  #    ]
  #  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["zerozero413@gmail.com"]
  }
}
~~~
