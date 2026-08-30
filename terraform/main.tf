###############################################################################
# Root composition: wires all modules together for one environment.
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

# Admin password for PostgreSQL, generated and stored only in Key Vault/state.
resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "!#$%*-_"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.base_tags
}

# ---- Monitoring (workspaces first: AKS consumes them) ----------------------
module "monitoring" {
  source              = "./modules/monitoring"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  log_retention_days  = var.log_retention_days
  enable_grafana      = var.enable_grafana
  alert_email         = var.alert_email
  slack_webhook_url   = var.slack_webhook_url
  tags                = local.base_tags
}

# ---- Network ---------------------------------------------------------------
module "network" {
  source              = "./modules/network"
  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_cidr           = var.vnet_cidr
  tags                = local.base_tags
}

# ---- AKS -------------------------------------------------------------------
module "aks" {
  source                     = "./modules/aks"
  name_prefix                = local.name_prefix
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  aks_subnet_id              = module.network.aks_subnet_id
  kubernetes_version         = var.kubernetes_version
  system_vm_size             = var.system_vm_size
  app_vm_size                = var.app_vm_size
  app_min_count              = var.app_min_count
  app_max_count              = var.app_max_count
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  monitor_workspace_id       = module.monitoring.monitor_workspace_id
  tags                       = local.base_tags
}

# ---- Workload identity for the app pod (Key Vault CSI access) --------------
resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${local.name_prefix}-app"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.base_tags
}

resource "azurerm_federated_identity_credential" "workload" {
  name                = "fic-${local.name_prefix}-app"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  # Must match the k8s namespace + service account used by the deployment.
  subject = "system:serviceaccount:app:todo-api"
}

# ---- Container registry ----------------------------------------------------
module "acr" {
  source                = "./modules/acr"
  acr_name              = "acr${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.this.name
  location              = var.location
  sku                   = var.acr_sku
  aks_kubelet_object_id = module.aks.kubelet_identity_object_id
  tags                  = local.base_tags
}

# ---- Database --------------------------------------------------------------
module "database" {
  source                       = "./modules/database"
  name_prefix                  = local.name_prefix
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  vnet_id                      = module.network.vnet_id
  db_subnet_id                 = module.network.db_subnet_id
  admin_username               = var.postgres_admin_username
  admin_password               = random_password.postgres.result
  sku_name                     = var.postgres_sku_name
  storage_mb                   = var.postgres_storage_mb
  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup
  high_availability_enabled    = var.postgres_high_availability
  tags                         = local.base_tags
}

# ---- Key Vault (secret management) -----------------------------------------
module "keyvault" {
  source                      = "./modules/keyvault"
  key_vault_name              = "kv-${var.project}-${var.environment}-${random_string.suffix.result}"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  purge_protection_enabled    = var.key_vault_purge_protection
  workload_identity_object_id = azurerm_user_assigned_identity.workload.principal_id
  db_connection_string        = module.database.connection_string
  db_password                 = random_password.postgres.result
  tags                        = local.base_tags
}

# ---- Metric alerts (kept in root to avoid a module cycle) ------------------
resource "azurerm_monitor_metric_alert" "aks_cpu" {
  name                = "alert-aks-cpu-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.aks.cluster_id]
  description         = "AKS node CPU usage is high."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
  tags = local.base_tags
}

resource "azurerm_monitor_metric_alert" "db_storage" {
  name                = "alert-db-storage-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.database.server_id]
  description         = "PostgreSQL storage usage is high."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT30M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
  tags = local.base_tags
}
