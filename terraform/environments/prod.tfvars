# Production environment — resilient (general-purpose DB, HA, geo-redundant backup).
environment = "prod"
location    = "eastus"
project     = "platblue"

kubernetes_version = "1.30"
system_vm_size     = "Standard_D4s_v3"
app_vm_size        = "Standard_D4s_v3"
app_min_count      = 2
app_max_count      = 6

postgres_sku_name              = "GP_Standard_D2s_v3"
postgres_storage_mb            = 131072
postgres_backup_retention_days = 30
postgres_geo_redundant_backup  = true
postgres_high_availability     = true

acr_sku = "Premium"

enable_grafana     = true
log_retention_days = 90
alert_email        = "oncall@example.com"

key_vault_purge_protection = true

tags = {
  owner = "platform-team"
}
