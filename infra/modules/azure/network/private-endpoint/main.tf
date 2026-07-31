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

  target_resource_info     = provider::azurerm::parse_resource_id(var.resource_id)
  target_resource_type     = local.target_resource_info["resource_type"]
  target_resource_name     = local.target_resource_info["resource_name"]
  target_resource_provider = local.target_resource_info["resource_provider"]

  subresource_names = var.subresource_names != null ? var.subresource_names : try(local.default_service_subresource_names[local.target_resource_type], [])

  subnet_info    = provider::azurerm::parse_resource_id(var.subnet_id)
  subnet_rg_name = local.subnet_info["resource_group_name"]

  private_endpoint_name     = var.name != null ? var.name : substr(local.target_resource_info["resource_name"], 0, 64)
  private_endpoint_rg_name  = var.resource_group_name != null ? var.resource_group_name : local.subnet_rg_name
  private_endpoint_location = data.azurerm_resource_group.subnet_rg.location

  dns_zone_name = var.dns_zone_key != null ? module.endpoint_refs.zones[var.dns_zone_key] : try(module.endpoint_refs.zones_by_provider[local.target_resource_provider], module.endpoint_refs.zones_by_type[local.target_resource_type])
}

module "endpoint_refs" {
  source = "../../private-endpoint-dns-refs"
}

data "azurerm_resource_group" "subnet_rg" {
  name = local.subnet_rg_name
}

data "azurerm_private_dns_zone" "service_zone" {
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
    private_dns_zone_ids = [data.azurerm_private_dns_zone.service_zone.id]
  }
}
