output "app_username" {
  value = azuread_group.db_app.display_name
}

output "app_object_id" {
  value = azuread_group.db_app.object_id
}

output "migrator_username" {
  value = azuread_group.db_migrator.display_name
}

output "migrator_object_id" {
  value = azuread_group.db_migrator.object_id
}

output "role_manager_job_name" {
  value = azurerm_container_app_job.db_role_manager.name
}
