variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "system_min_count" {
  type    = number
  default = 1
}

variable "system_max_count" {
  type    = number
  default = 3
}

variable "app_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "app_min_count" {
  type    = number
  default = 1
}

variable "app_max_count" {
  type    = number
  default = 4
}

variable "service_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.0.0.10"
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "monitor_workspace_id" {
  description = "Azure Monitor (managed Prometheus) workspace id."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
