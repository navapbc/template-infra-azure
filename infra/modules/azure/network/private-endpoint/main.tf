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

  target_resource_info     = var.enable ? provider::azurerm::parse_resource_id(var.resource_id) : null
  target_resource_type     = try(local.target_resource_info["resource_type"], null)
  target_resource_name     = try(local.target_resource_info["resource_name"], null)
  target_resource_provider = try(local.target_resource_info["resource_provider"], null)

  subresource_names = var.subresource_names != null ? var.subresource_names : try(local.default_service_subresource_names[local.target_resource_type], [])

  subnet_info    = var.enable ? provider::azurerm::parse_resource_id(var.subnet_id) : null
  subnet_rg_name = try(local.subnet_info["resource_group_name"], null)

  private_endpoint_name     = var.name != null ? var.name : try(substr(local.target_resource_info["resource_name"], 0, 64), null)
  private_endpoint_rg_name  = var.resource_group_name != null ? var.resource_group_name : local.subnet_rg_name
  private_endpoint_location = local.subnet_rg_name != null ? data.azurerm_resource_group.subnet_rg[0].location : null

  dns_zone_name = var.dns_zone_key != null ? module.endpoint_refs.zones[var.dns_zone_key] : try(module.endpoint_refs.zones_by_provider[local.target_resource_provider], module.endpoint_refs.zones_by_type[local.target_resource_type], null)
}

module "endpoint_refs" {
  source = "../../private-endpoint-dns-refs"
}

data "azurerm_resource_group" "subnet_rg" {
  count = local.subnet_rg_name != null ? 1 : 0

  name = local.subnet_rg_name
}

data "azurerm_private_dns_zone" "service_zone" {
  count = local.subnet_rg_name != null ? 1 : 0

  name                = local.dns_zone_name
  resource_group_name = local.subnet_rg_name
}

resource "azurerm_private_endpoint" "service" {
  count = var.enable ? 1 : 0

  name                = local.private_endpoint_name
  location            = local.private_endpoint_location
  resource_group_name = local.private_endpoint_rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = local.target_resource_name
    private_connection_resource_id = var.resource_id
    subresource_names              = local.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = local.target_resource_name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.service_zone[0].id]
  }
}
