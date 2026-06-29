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
