~~~
  user_data                   = <<EOF
  #!/bin/bash
  sudo systemctl stop amazon-cloudwatch-agent
  EOF

variable "user_data" {
  description = ""
  type        = string
  default     = null
}

  user_data                   = var.user_data
~~~
