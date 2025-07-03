output "tf_state_resource_group_name" {
  value = azurerm_resource_group.tf_state.name
}

output "tf_state_storage_account_name" {
  value = azurerm_storage_account.tf_state.name
}

output "tf_state_storage_container_name" {
  value = azurerm_storage_container.tf_state.name
}

output "tf_state_storage_container_scope" {
  value = azurerm_storage_container.tf_state.resource_manager_id
}
