# Checkov will fail to parse this file due to the use of provider defined
# functions (`parse_resource_id`)
#
# https://github.com/bridgecrewio/checkov/issues/6866
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  default_service_subresource_names = {
    "registries" : ["registry"]
    "vaults" : ["vault"]
  }

  parsed_resource_info = provider::azurerm::parse_resource_id(var.resource_id)
  resource_type        = local.parsed_resource_info["resource_type"]

  subresource_names = var.subresource_names != null ? var.subresource_names : try(local.default_service_subresource_names[local.resource_type], [])

  resource_name       = var.resource_name != null ? var.resource_name : local.parsed_resource_info["resource_name"]
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : local.parsed_resource_info["resource_group_name"]
  resource_location   = var.resource_location != null ? var.resource_location : data.azurerm_resource_group.rg[0].location

  dns_zone_name = var.dns_zone_key != null ? module.endpoint_refs.zones[var.dns_zone_key] : module.endpoint_refs.zones_by_resource_type[local.resource_type]

  parsed_subnet_info = var.enable ? provider::azurerm::parse_resource_id(var.subnet_id) : null
}

module "endpoint_refs" {
  source = "../../private-endpoint-dns-refs"
}

data "azurerm_resource_group" "rg" {
  count = var.resource_location == null ? 1 : 0

  name = local.parsed_resource_info["resource_group_name"]
}

data "azurerm_private_dns_zone" "service_zone" {
  count = var.enable ? 1 : 0

  name                = local.dns_zone_name
  resource_group_name = local.parsed_subnet_info["resource_group_name"]
}

resource "azurerm_private_endpoint" "service" {
  count = var.enable ? 1 : 0

  name                = local.resource_name
  location            = local.resource_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = local.resource_name
    private_connection_resource_id = var.resource_id
    subresource_names              = local.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = local.resource_name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.service_zone[0].id]
  }
}
