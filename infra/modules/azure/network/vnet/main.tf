locals {
  location = try(var.vnet_config.location, module.project_config.default_region)

  has_nat_gateway = anytrue([for s in var.vnet_config.subnets : lookup(s, "internet_access", false)])
}

module "project_config" {
  source = "../../../../project-config"
}

resource "azurerm_virtual_network" "vnet" {
  resource_group_name = var.resource_group_name
  name                = var.name
  address_space       = ["${var.vnet_config.vnet_cidr}"]
  location            = local.location
}

module "nat_gateway" {
  count  = local.has_nat_gateway == true ? 1 : 0
  source = "../nat_gateway"

  resource_group_name = var.resource_group_name
  vnet_name           = azurerm_virtual_network.vnet.name
  location            = local.location
}

module "subnet" {
  source   = "../subnet"
  for_each = var.vnet_config.subnets

  resource_group_name = var.resource_group_name
  vnet_name           = azurerm_virtual_network.vnet.name
  name                = each.key
  subnet_config       = each.value
  nat_gateway_id      = try(module.nat_gateway[0].nat_gateway_id, "")
  location            = local.location

  application_gateway_subnet_name = try(var.vnet_config.application_gateway_subnet_name, null)

  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id
}
