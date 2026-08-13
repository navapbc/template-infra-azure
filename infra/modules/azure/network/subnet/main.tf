locals {
  enable_nat_gateway = lookup(var.subnet_config, "internet_access", false)
}

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["${var.subnet_config.subnet_cidr}"]

  # mark the subnet as private by default, egress to the internet should be
  # through the NAT Gateway or other explicit configuration
  #
  # https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
  default_outbound_access_enabled = false

  private_endpoint_network_policies = "Enabled"

  # When configuring Azure Private Link service this must be set to `false` in
  # the subnet since Private Link Service does not support network policies like
  # user-defined Routes and Network Security Groups.
  private_link_service_network_policies_enabled = true

  # Some Azure Policies strictly require Network Security Group (and/or Route
  # Table) associations to be explicitly specified within the Subnet
  # creation/update payload itself, rather than being attached later via
  # separate association resources.
  #
  # This is otherwise managed by the
  # `azurerm_subnet_network_security_group_association.subnet` resource
  network_security_group_id_wo         = var.use_inline_nsg_association ? azurerm_network_security_group.subnet.id : null
  network_security_group_id_wo_version = var.use_inline_nsg_association ? parseint(substr(sha256(azurerm_network_security_group.subnet.id), 0, 7), 16) : null

  dynamic "service_endpoint" {
    for_each = try(var.subnet_config.service_endpoints, [])

    content {
      service = service_endpoint.value
    }
  }

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
