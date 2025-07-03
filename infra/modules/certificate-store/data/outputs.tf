output "cert_vault_id" {
  value = data.azurerm_key_vault.certs.id
}

output "cert_vault_uri" {
  value = data.azurerm_key_vault.certs.vault_uri
}

output "cert_vault_name" {
  value = module.cert_interface.cert_vault_name
}

output "cert_vault_location" {
  value = module.cert_interface.cert_vault_location
}

output "cert_vault_resource_group_name" {
  value = module.cert_interface.cert_vault_resource_group_name
}
