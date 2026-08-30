###############################################################################
# Monitoring & logging module.
#  - Log Analytics Workspace: centralized logs (app/system/access) + Container
#    Insights infrastructure metrics.
#  - Azure Monitor Workspace: managed Prometheus for application metrics.
#  - Azure Managed Grafana: dashboards.
#  - Action group + metric alerts: notify on failures.
###############################################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Managed Prometheus metrics store for application metrics (request rate,
# error rate, latency) scraped from the app's /metrics endpoint.
resource "azurerm_monitor_workspace" "prometheus" {
  name                = "amw-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Managed Grafana instance for dashboards.
resource "azurerm_dashboard_grafana" "this" {
  count                             = var.enable_grafana ? 1 : 0
  name                              = "graf-${var.name_prefix}"
  resource_group_name               = var.resource_group_name
  location                          = var.location
  grafana_major_version             = 10
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  tags = var.tags
}

# Let Grafana read metrics from the Azure Monitor (Prometheus) workspace.
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count                = var.enable_grafana ? 1 : 0
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
}

# ---- Alerting --------------------------------------------------------------
resource "azurerm_monitor_action_group" "notify" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "platalert"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email == "" ? [] : [var.alert_email]
    content {
      name          = "oncall-email"
      email_address = email_receiver.value
    }
  }

  # Slack (or any chat) via incoming webhook. The URL is sensitive, so it is
  # kept out of for_each (which cannot take a sensitive value) and referenced
  # directly inside the block instead.
  dynamic "webhook_receiver" {
    for_each = nonsensitive(var.slack_webhook_url) == "" ? [] : ["slack"]
    content {
      name                    = "slack"
      service_uri             = var.slack_webhook_url
      use_common_alert_schema = true
    }
  }
}

# NOTE: Metric alerts that reference the AKS cluster and PostgreSQL server live
# in the root module (terraform/main.tf) to avoid a module dependency cycle
# (this module produces the workspaces the AKS module consumes).
