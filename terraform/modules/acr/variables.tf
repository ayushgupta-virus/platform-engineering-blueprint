variable "acr_name" {
  description = "Globally-unique ACR name (alphanumeric only)."
  type        = string
}

variable "foundation" {
  description = "Shared config from the foundation module (naming, location, resource group, tags)."
  type = object({
    name_prefix         = string
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
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
