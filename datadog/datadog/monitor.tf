resource "datadog_monitor" "monitor_01" {
  name = "Backend Down"
  type = "metric alert"
  message = "Service Down: {{servicename}} {{#is_alert}}@leonheart413@yahoo.co.jp{{/is_alert}}"

  query = "min(last_10m):avg:ecs.containerinsights.RunningTaskCount{servicename:greatobi-dev-ecs-svc-01} < 2"
  require_full_window = false
  priority = 1
  monitor_thresholds {
    critical = 2
  }

#  monitor_threshold_windows {
#    trigger_window = "last_5m"
#  }
}
