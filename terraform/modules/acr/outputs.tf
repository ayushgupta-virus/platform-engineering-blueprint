output "acr_id" {
  value = azurerm_container_registry.this.id
}

output "login_server" {
  description = "ACR login server (used as the image registry host)."
  value       = azurerm_container_registry.this.login_server
}

output "acr_name" {
  value = azurerm_container_registry.this.name
}
