variable "environment" {
  description = "Deployment environment (staging, prod)."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "project" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "platblue"
}

# ---- Network ---------------------------------------------------------------
variable "vnet_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

# ---- AKS -------------------------------------------------------------------
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
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

# ---- Database --------------------------------------------------------------
variable "postgres_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type    = number
  default = 32768
}

variable "postgres_admin_username" {
  type    = string
  default = "pgadmin"
}

variable "postgres_backup_retention_days" {
  type    = number
  default = 7
}

variable "postgres_geo_redundant_backup" {
  type    = bool
  default = false
}

variable "postgres_high_availability" {
  type    = bool
  default = false
}

# ---- Container registry ----------------------------------------------------
variable "acr_sku" {
  type    = string
  default = "Standard"
}

# ---- Monitoring ------------------------------------------------------------
variable "enable_grafana" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "slack_webhook_url" {
  type      = string
  default   = ""
  sensitive = true
}

# ---- Security --------------------------------------------------------------
variable "key_vault_purge_protection" {
  type    = bool
  default = false
}

variable "tags" {
  description = "Base tags applied to every resource."
  type        = map(string)
  default     = {}
}
