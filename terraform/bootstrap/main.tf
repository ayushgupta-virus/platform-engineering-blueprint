###############################################################################
# One-time bootstrap: creates the Azure Storage backend used for Terraform
# remote state. Run this BEFORE the main configuration.
#
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# Then note the outputs and use them for `terraform init -backend-config=...`
# in the parent directory.
###############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # Bootstrap uses local state (chicken-and-egg: it creates the remote backend).
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-tfstate"
}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    purpose = "terraform-state"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "sttfstate${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    purpose = "terraform-state"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "backend_config_hint" {
  value = <<-EOT
    terraform init \
      -backend-config="resource_group_name=${azurerm_resource_group.tfstate.name}" \
      -backend-config="storage_account_name=${azurerm_storage_account.tfstate.name}" \
      -backend-config="container_name=${azurerm_storage_container.tfstate.name}" \
      -backend-config="key=platform/<env>.tfstate"
  EOT
}
