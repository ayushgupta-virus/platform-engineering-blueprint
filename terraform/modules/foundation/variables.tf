variable "project" {
  description = "Short project name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (staging, prod)."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged into the base tag set."
  type        = map(string)
  default     = {}
}
