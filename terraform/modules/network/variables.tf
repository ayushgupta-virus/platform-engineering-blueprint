variable "foundation" {
  description = "Shared config from the foundation module (naming, location, resource group, tags)."
  type = object({
    name_prefix         = string
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
}

variable "vnet_cidr" {
  description = "Address space for the virtual network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public / ingress subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "aks_subnet_cidr" {
  description = "CIDR for the private AKS node subnet."
  type        = string
  default     = "10.20.16.0/20"
}

variable "db_subnet_cidr" {
  description = "CIDR for the delegated PostgreSQL subnet."
  type        = string
  default     = "10.20.32.0/24"
}
