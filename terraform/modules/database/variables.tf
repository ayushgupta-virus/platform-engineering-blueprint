variable "foundation" {
  description = "Shared config from the foundation module (naming, location, resource group, tags)."
  type = object({
    name_prefix         = string
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
}

variable "vnet_id" {
  description = "VNet id used for the private DNS zone link."
  type        = string
}

variable "db_subnet_id" {
  description = "Delegated subnet id for the flexible server."
  type        = string
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "admin_username" {
  type    = string
  default = "pgadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  description = "Compute SKU, e.g. B_Standard_B1ms (dev) or GP_Standard_D2s_v3 (prod)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_enabled" {
  type    = bool
  default = false
}

