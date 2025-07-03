output "host" {
  value = data.azurerm_postgresql_flexible_server.db.fqdn
}

output "port" {
  value = 5432
}

output "db_name" {
  value = module.interface.db_name
}

output "schema_name" {
  value = module.interface.schema_name
}

output "app_username" {
  value = module.interface.app_username
}

output "app_object_id" {
  value = data.azuread_group.db_app.object_id
}

output "migrator_username" {
  value = module.interface.migrator_username
}

output "migrator_object_id" {
  value = data.azuread_group.db_migrator.object_id
}
