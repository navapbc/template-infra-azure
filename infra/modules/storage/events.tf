# Event Grid System Topic for storage account events
# This enables event-driven architecture by publishing storage events (blob created, deleted, etc.)
# to Event Grid. Subscribers can then subscribe to these events.
# Azure analog of aws_s3_bucket_notification with eventbridge = true in AWS template.
resource "azurerm_eventgrid_system_topic" "storage" {
  name                   = "${var.name}-storage-events"
  resource_group_name    = var.resource_group_name
  location               = var.resource_group_location
  source_arm_resource_id = azurerm_storage_account.storage.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

# Forward storage account logs and metrics to Azure Monitor / Log Analytics.
module "storage_monitor" {
  source = "../azure/monitor/storage"
  enable = var.monitor_config.enabled

  name                       = azurerm_storage_account.storage.name
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.monitor_config.log_analytics_workspace_id
}
