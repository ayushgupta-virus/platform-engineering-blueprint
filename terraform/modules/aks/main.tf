###############################################################################
# AKS module — private-node Kubernetes cluster that hosts the application.
#  - System + user node pools live in the private AKS subnet.
#  - Container Insights (oms_agent) ships infra metrics + logs to Log Analytics.
#  - Managed Prometheus (monitor_metrics + DCR) scrapes application metrics.
#  - Workload Identity + OIDC enabled for Key Vault CSI secret access.
###############################################################################

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.foundation.name_prefix}"
  location            = var.foundation.location
  resource_group_name = var.foundation.resource_group_name
  dns_prefix          = "aks-${var.foundation.name_prefix}"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "rg-${var.foundation.name_prefix}-aks-nodes"

  # Enable OIDC + workload identity for pod-level Azure AD auth (Key Vault CSI).
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_vm_size
    vnet_subnet_id               = var.aks_subnet_id
    orchestrator_version         = var.kubernetes_version
    enable_auto_scaling          = true
    min_count                    = var.system_min_count
    max_count                    = var.system_max_count
    max_pods                     = 50
    os_disk_size_gb              = 64
    only_critical_addons_enabled = true
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # Container Insights -> Log Analytics (infra metrics + centralized logs).
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Managed Prometheus addon (application metrics).
  monitor_metrics {}

  tags = var.foundation.tags

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}

# Dedicated user node pool for application workloads.
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.app_vm_size
  vnet_subnet_id        = var.aks_subnet_id
  orchestrator_version  = var.kubernetes_version
  enable_auto_scaling   = true
  min_count             = var.app_min_count
  max_count             = var.app_max_count
  max_pods              = 50
  os_disk_size_gb       = 64
  node_labels = {
    "workload" = "application"
  }
  tags = var.foundation.tags
}

# ---- Managed Prometheus data collection wiring -----------------------------
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                = "dce-${var.foundation.name_prefix}"
  resource_group_name = var.foundation.resource_group_name
  location            = var.foundation.location
  kind                = "Linux"
  tags                = var.foundation.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "dcr-prom-${var.foundation.name_prefix}"
  resource_group_name         = var.foundation.resource_group_name
  location                    = var.foundation.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  kind                        = "Linux"
  tags                        = var.foundation.tags

  destinations {
    monitor_account {
      monitor_account_id = var.monitor_workspace_id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "dcra-prom-${var.foundation.name_prefix}"
  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}
