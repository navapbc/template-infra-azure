terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm, azurerm.domain]
    }

    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}

locals {
  dns_zone = var.manage_dns ? (var.create_dns_zone ? azurerm_dns_zone.zone[0] : data.azurerm_dns_zone.zone[0]) : null
}

# Create a hosted zone for the domain.
# Individual address records will be created in the service layer by the services that
# need them (e.g. the load balancer or CDN).
# If DNS is managed elsewhere then this resource will not be created.
resource "azurerm_dns_zone" "zone" {
  provider = azurerm.domain

  count               = var.manage_dns && var.create_dns_zone ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
}

data "azurerm_dns_zone" "zone" {
  provider = azurerm.domain

  count = var.manage_dns && !var.create_dns_zone ? 1 : 0
  name  = var.name
}
