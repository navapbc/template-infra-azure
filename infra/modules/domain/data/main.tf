terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm, azurerm.domain]
    }
  }
}

data "azurerm_dns_zone" "zone" {
  provider = azurerm.domain

  count = var.hosted_zone != null ? 1 : 0

  name                = var.hosted_zone
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_certificate" "cert" {
  count = var.cert_name != null ? 1 : 0

  name         = replace(replace(var.cert_name, ".", "-"), "*", "wildcard")
  key_vault_id = var.cert_vault_id
}
