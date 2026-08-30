variable "acr_name" {
  description = "Globally-unique ACR name (alphanumeric only)."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  description = "ACR SKU (Basic, Standard, Premium). Premium required for geo-replication."
  type        = string
  default     = "Standard"
}

variable "geo_replication_locations" {
  description = "Extra regions to geo-replicate to (Premium SKU only)."
  type        = list(string)
  default     = []
}

variable "aks_kubelet_object_id" {
  description = "Kubelet identity object id granted AcrPull. Null to skip."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
