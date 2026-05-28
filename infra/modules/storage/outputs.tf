output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "container_name" {
  value = azurerm_storage_container.documents.name
}

output "eventgrid_system_topic_id" {
  description = "The ID of the Event Grid System Topic for storage events. Use this to create event subscriptions."
  value       = azurerm_eventgrid_system_topic.storage.id
}

output "storage_blob_data_contributor_role_id" {
  description = "The role definition ID for Storage Blob Data Contributor. Use this to create role assignments outside this module."
  value       = data.azurerm_role_definition.storage_blob_data_contributor.id
}
