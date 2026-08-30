output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "monitor_workspace_id" {
  description = "Azure Monitor (managed Prometheus) workspace id."
  value       = azurerm_monitor_workspace.prometheus.id
}

output "prometheus_query_endpoint" {
  value = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "grafana_endpoint" {
  value = var.enable_grafana ? azurerm_dashboard_grafana.this[0].endpoint : null
}

output "action_group_id" {
  value = azurerm_monitor_action_group.notify.id
}
