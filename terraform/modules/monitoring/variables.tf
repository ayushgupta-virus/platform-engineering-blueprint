variable "foundation" {
  description = "Shared config from the foundation module (naming, location, resource group, tags)."
  type = object({
    name_prefix         = string
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
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

