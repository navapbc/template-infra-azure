output "db_resource_group_name" {
  value = azurerm_resource_group.db.name
}

output "role_manager_job_name" {
  value = module.database.role_manager_job_name
}
