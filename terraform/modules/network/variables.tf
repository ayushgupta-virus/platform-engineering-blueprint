variable "name_prefix" {
  description = "Prefix applied to network resource names."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the network resources."
  type        = string
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

variable "tags" {
  description = "Tags applied to all network resources."
  type        = map(string)
  default     = {}
}
