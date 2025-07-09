output "domain_name" {
  value = var.domain_name
}

# TODO: rename hosted_zone_resource_group_name?
output "resource_group_name" {
  value = var.hosted_zone != null ? data.azurerm_dns_zone.zone[0].resource_group_name : null
}

output "hosted_zone_id" {
  value = var.hosted_zone != null ? data.azurerm_dns_zone.zone[0].id : null
}

output "hosted_zone_name" {
  value = var.hosted_zone != null ? data.azurerm_dns_zone.zone[0].name : null
}

output "network_zone_name" {
  value = var.hosted_zone
}

output "certificate_secret_id" {
  # versionless to support automatic rotation
  value = var.cert_name != null ? data.azurerm_key_vault_certificate.cert[0].versionless_secret_id : null
}
