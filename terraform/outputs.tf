output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = var.location
}

# ---- AKS -------------------------------------------------------------------
output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_get_credentials_command" {
  description = "Command to fetch kubeconfig for this cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name}"
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

# ---- Container registry ----------------------------------------------------
output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_name" {
  value = module.acr.acr_name
}

# ---- Database --------------------------------------------------------------
output "postgres_fqdn" {
  value = module.database.fqdn
}

output "postgres_database_name" {
  value = module.database.database_name
}

# ---- Security --------------------------------------------------------------
output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "workload_identity_client_id" {
  description = "Client id used by the app's Kubernetes service account (workload identity)."
  value       = azurerm_user_assigned_identity.workload.client_id
}

# ---- Monitoring ------------------------------------------------------------
output "log_analytics_workspace_name" {
  value = module.monitoring.log_analytics_workspace_name
}

output "grafana_endpoint" {
  value = module.monitoring.grafana_endpoint
}

output "prometheus_query_endpoint" {
  value = module.monitoring.prometheus_query_endpoint
}
