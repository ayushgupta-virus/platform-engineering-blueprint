variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_grafana" {
  description = "Provision Azure Managed Grafana (adds cost)."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alert notifications."
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for failure notifications."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
