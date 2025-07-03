locals {
  subnet_map = { for subnet in data.azurerm_subnet.subnets : subnet.name => subnet }
}

module "interface" {
  source       = "../interface"
  project_name = var.project_name
  network_name = var.network_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  resource_group_name = module.interface.resource_group_name
}

data "azurerm_subnet" "subnets" {
  for_each             = toset(data.azurerm_virtual_network.vnet.subnets)
  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
}
