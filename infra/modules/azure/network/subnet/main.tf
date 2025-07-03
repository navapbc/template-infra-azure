locals {
  enable_nat_gateway = lookup(var.subnet_config, "internet_access", false)
}

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["${var.subnet_config.subnet_cidr}"]
  service_endpoints    = try(var.subnet_config.service_endpoints, [])

  # mark the subnet as private by default, egress to the internet should be
  # through the NAT Gateway or other explicit configuration
  #
  # https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
  default_outbound_access_enabled = false

  # TODO: need this?
  # private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  private_endpoint_network_policies = "Enabled"

  # When configuring Azure Private Link service this must be set to `false` in
  # the subnet since Private Link Service does not support network policies like
  # user-defined Routes and Network Security Groups.
  private_link_service_network_policies_enabled = true

  dynamic "delegation" {
    for_each = try(var.subnet_config.service_delegation, [])

    content {
      name = "delegation"
      service_delegation {
        name = delegation.value

      }
    }
  }

  lifecycle {
    ignore_changes = [
      delegation[0].service_delegation[0].actions
    ]
  }
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_public_subnet_association" {
  count          = local.enable_nat_gateway == true ? 1 : 0
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = var.nat_gateway_id
}
