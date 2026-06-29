# Forward storage account logs and metrics to Azure Monitor / Log Analytics.
# This sends diagnostic data to Log Analytics for monitoring, alerting, and compliance.
module "storage_monitor" {
  source = "../azure/monitor/storage"
  enable = var.monitor_config.enabled

  name                       = azurerm_storage_account.storage.name
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.monitor_config.log_analytics_workspace_id
}
