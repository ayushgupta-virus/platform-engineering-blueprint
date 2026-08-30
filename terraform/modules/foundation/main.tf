###############################################################################
# Foundation: shared config every other module consumes.
#
# Owns the naming convention, base tags, resource group and the random suffix
# used for globally-unique names. Keeping these in one place means individual
# modules only declare resource-specific configuration.
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"

  base_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags
  )
}

# Random suffix for globally-unique names (ACR, Key Vault).
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.base_tags
}
