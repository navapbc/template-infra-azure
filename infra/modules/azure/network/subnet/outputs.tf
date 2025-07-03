output "name" {
  value = azurerm_subnet.subnet.name
}

output "id" {
  value = azurerm_subnet.subnet.id
}

output "container_app_environment_id" {
  value = try(azurerm_container_app_environment.env[0].id, null)
}
