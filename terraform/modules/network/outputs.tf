output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "public_subnet_id" {
  description = "ID of the public / ingress subnet."
  value       = azurerm_subnet.public.id
}

output "aks_subnet_id" {
  description = "ID of the private AKS subnet."
  value       = azurerm_subnet.aks.id
}

output "db_subnet_id" {
  description = "ID of the delegated database subnet."
  value       = azurerm_subnet.db.id
}
