output "resource_group_name" {
  description = "Name of the shared resource group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region of the resource group."
  value       = azurerm_resource_group.this.location
}

output "name_prefix" {
  description = "Common prefix (project-environment) for resource names."
  value       = local.name_prefix
}

output "name_suffix" {
  description = "Random suffix for globally-unique resource names."
  value       = random_string.suffix.result
}

output "tags" {
  description = "Base tag set applied to every resource."
  value       = local.base_tags
}

# Bundled common config consumed by every resource-specific module.
output "config" {
  description = "Shared foundation config (naming, location, resource group, tags)."
  value = {
    name_prefix         = local.name_prefix
    location            = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    tags                = local.base_tags
  }
}
