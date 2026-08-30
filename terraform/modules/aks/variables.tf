variable "foundation" {
  description = "Shared config from the foundation module (naming, location, resource group, tags)."
  type = object({
    name_prefix         = string
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
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

