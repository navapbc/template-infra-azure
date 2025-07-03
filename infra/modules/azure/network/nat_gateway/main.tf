data "azurerm_location" "location" {
  location = var.location
}

locals {
  logical_zones = coalesce([for zone in data.azurerm_location.location.zone_mappings : zone.logical_zone], [])
}

resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "${var.vnet_name}-nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = local.logical_zones

  lifecycle {
    prevent_destroy = false
  }
}

# TODO: at the moment we create a single NAT Gateway for the Virtual Network, in
# AWS we create a different one for each availability zone. Do we want to do
# that here? We'll have to create unique subnets for each zone though, and put
# zonal resources into the right subnet.
#
# https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview#availability-zones
# https://learn.microsoft.com/en-us/azure/nat-gateway/nat-availability-zones
resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = var.vnet_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}
