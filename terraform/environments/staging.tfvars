# Staging environment — cost-optimized (burstable DB, single-zone, no geo backup).
environment = "staging"
location    = "eastus"
project     = "platblue"

kubernetes_version = "1.30"
system_vm_size     = "Standard_D2s_v3"
app_vm_size        = "Standard_D2s_v3"
app_min_count      = 1
app_max_count      = 3

postgres_sku_name              = "B_Standard_B1ms"
postgres_storage_mb            = 32768
postgres_backup_retention_days = 7
postgres_geo_redundant_backup  = false
postgres_high_availability     = false

acr_sku = "Standard"

enable_grafana     = true
log_retention_days = 30
alert_email        = "oncall@example.com"

key_vault_purge_protection = false

tags = {
  owner = "platform-team"
}
