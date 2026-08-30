variable "key_vault_name" {
  description = "Globally-unique Key Vault name."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (recommended for prod)."
  type        = bool
  default     = false
}

variable "workload_identity_object_id" {
  description = "Object id of the AKS workload identity granted read access."
  type        = string
  default     = null
}

variable "db_connection_string" {
  description = "PostgreSQL connection string stored as a secret."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL administrator password stored as a secret."
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
