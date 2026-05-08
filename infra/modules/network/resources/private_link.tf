locals {
  use_private_endpoints = try(var.network_config.network.private_endpoints_subnet_name, null) != null

  azure_service_integrations = setunion(
    local.use_private_endpoints ? ["acr", "keyvault"] : [],

    var.has_database ? ["postgresql"] : [],
  )
}

module "endpoint_refs" {
  source = "../../azure/private-endpoint-dns-refs"
}

resource "azurerm_private_dns_zone" "service_zone" {
  for_each = local.azure_service_integrations

  name                = module.endpoint_refs.zones[each.key]
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  for_each = azurerm_private_dns_zone.service_zone

  name                  = "${var.resource_group_name}-dnslink-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name

  virtual_network_id = module.vnet.vnet_id

}

module "container_registry_endpoint" {
  source = "../../../modules/azure/network/private-endpoint"

  enable              = local.use_private_endpoints
  subnet_id           = local.use_private_endpoints ? module.vnet.subnets[var.network_config.network.private_endpoints_subnet_name].id : null
  resource_id         = var.container_registry_id
  resource_group_name = var.resource_group_name
}
