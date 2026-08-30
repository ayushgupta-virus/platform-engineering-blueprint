###############################################################################
# Azure Database for PostgreSQL — Flexible Server (the "RDS for PostgreSQL").
# Deployed with VNet integration (private access) into the delegated subnet.
# Backups: automated daily + point-in-time restore; optional geo-redundancy.
###############################################################################

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.foundation.name_prefix}.private.postgres.database.azure.com"
  resource_group_name = var.foundation.resource_group_name
  tags                = var.foundation.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdz-link-${var.foundation.name_prefix}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = var.foundation.resource_group_name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.foundation.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "psql-${var.foundation.name_prefix}"
  resource_group_name = var.foundation.resource_group_name
  location            = var.foundation.location
  version             = var.postgres_version

  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  # Private (VNet-integrated) access only — no public endpoint.
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  # Backup / DR strategy.
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.high_availability_enabled ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  tags = var.foundation.tags

  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Enforce TLS in transit.
resource "azurerm_postgresql_flexible_server_configuration" "require_ssl" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "ON"
}
