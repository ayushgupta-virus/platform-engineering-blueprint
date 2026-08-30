###############################################################################
# Azure Container Registry module.
# The AKS kubelet identity is granted AcrPull so nodes can pull images without
# storing registry credentials (managed-identity based auth).
###############################################################################

resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  # Disable admin user: pulls/pushes use AAD identities, not a shared password.
  admin_enabled = false
  tags          = var.tags

  dynamic "georeplications" {
    for_each = var.geo_replication_locations
    content {
      location = georeplications.value
    }
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                            = var.aks_kubelet_object_id == null ? 0 : 1
  scope                            = azurerm_container_registry.this.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.aks_kubelet_object_id
  skip_service_principal_aad_check = true
}
