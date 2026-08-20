output "id" {
  value = one(azurerm_private_endpoint.service[*].id)
}
