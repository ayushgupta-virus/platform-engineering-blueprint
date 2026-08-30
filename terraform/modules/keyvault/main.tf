###############################################################################
# Key Vault module (secret management).
# Stores the database connection secret and lets the AKS workload read it via
# the Secrets Store CSI driver (workload identity / kubelet identity).
###############################################################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = var.foundation.location
  resource_group_name        = var.foundation.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = 7
  # RBAC is preferred over legacy access policies.
  enable_rbac_authorization = true
  tags                      = var.foundation.tags
}

# The identity running Terraform can manage secrets.
resource "azurerm_role_assignment" "deployer_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# The AKS workload identity can read secrets.
resource "azurerm_role_assignment" "workload_reader" {
  count                = var.workload_identity_object_id == null ? 0 : 1
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_object_id
}

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = var.db_connection_string
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.deployer_admin]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.deployer_admin]
}
