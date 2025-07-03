locals {
  is_db_subnet = try(contains(var.subnet_config.service_delegation, "Microsoft.DBforPostgreSQL/flexibleServers"), false)
}

resource "azurerm_network_security_group" "subnet" {
  name                = "nsg-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.subnet.id
}

# Effectively re-apply the default DenyAllOutBound rule without the default exceptions
# https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#default-security-rules
resource "azurerm_network_security_rule" "deny_outbound" {
  count = local.enable_nat_gateway == false ? 1 : 0

  name                        = "deny-all-outbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

# Effectively re-apply the default DenyAllInBound rule without the default exceptions
# https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#default-security-rules
#
# Note this only applies to traffic in the Virtual Network, ingress for Azure
# Container App Environments that have public access enabled does not go through
# the Virtual Network.
resource "azurerm_network_security_rule" "deny_inbound" {
  count = local.enable_nat_gateway == false ? 1 : 0

  name                        = "deny-all-inbound"
  priority                    = 4095
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

# Effectively re-apply the default AllowAzureLoadBalancerInBound rule without the default exceptions
# https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#default-security-rules
resource "azurerm_network_security_rule" "allow_azure_load_balancer" {
  count = local.enable_nat_gateway == true || local.create_container_app_env ? 1 : 0

  name                        = "allow-azure-load-balancer"
  priority                    = 4094
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "*"
  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_vnet_outbound" {
  count = var.name != var.application_gateway_subnet_name ? 1 : 0

  name      = "allow-vnet-outbound"
  priority  = 4093
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = "VirtualNetwork"
  source_port_range     = "*"

  # TODO: this could be just conditional on `outbound_peer_cidrs`? defaulting to "VirtualNetwork"
  # destination_address_prefixes = var.subnet_config.outbound_peer_cidrs
  destination_address_prefix = "VirtualNetwork"
  destination_port_range     = "*"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_vnet_inbound" {
  name      = "allow-vnet-inbound"
  priority  = 4092
  direction = "Inbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = "VirtualNetwork"
  source_port_range     = "*"

  destination_address_prefix = "VirtualNetwork"
  destination_port_range     = "*"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_entra_outbound" {
  count = local.create_container_app_env || local.is_db_subnet ? 1 : 0

  name      = "allow-entra-outbound"
  priority  = 4000
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = var.subnet_config.subnet_cidr
  source_port_range     = "*"

  destination_address_prefix = "AzureActiveDirectory"
  destination_port_range     = "*"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_acr_outbound" {
  count = try(contains(var.subnet_config.service_endpoints, "Microsoft.ContainerRegistry"), false) ? 1 : 0

  name      = "allow-acr-outbound"
  priority  = 4001
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = var.subnet_config.subnet_cidr
  source_port_range     = "*"

  destination_port_range     = "*"
  destination_address_prefix = "AzureContainerRegistry"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_key_vault_outbound" {
  count = try(contains(var.subnet_config.service_endpoints, "Microsoft.KeyVault"), false) ? 1 : 0

  name      = "allow-key-vault-outbound"
  priority  = 4004
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = var.subnet_config.subnet_cidr
  source_port_range     = "*"

  destination_address_prefix = "AzureKeyVault"
  destination_port_range     = "*"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_gateway_manager_inbound" {
  count = var.name == var.application_gateway_subnet_name ? 1 : 0

  name                        = "allow-gateway-manager-inbound"
  description                 = "Allow traffic from GatewayManager. This port range is required for Azure infrastructure communication (e.g., Application Gateway V2 SKUs)."
  priority                    = 4005
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_public_http_inbound" {
  count = var.name == var.application_gateway_subnet_name ? 1 : 0

  name      = "allow-public-http-inbound"
  priority  = 4006
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix = "*"
  source_port_range     = "*"

  destination_address_prefix = var.subnet_config.subnet_cidr
  destination_port_ranges    = [80, 443]

  # checkov:skip=CKV_AZURE_160: We allow port 80 from the internet so the gateway can redirect to port 443

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

resource "azurerm_network_security_rule" "allow_limited_vnet_outbound" {
  count = var.name == var.application_gateway_subnet_name ? 1 : 0

  name      = "allow-limited-vnet-outbound"
  priority  = 4008
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = "*"
  source_port_range     = "*"

  destination_address_prefixes = var.subnet_config.outbound_peer_cidrs
  destination_port_ranges      = [80, 443]

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}

# TODO: this is basically just so `az login` in example app bin/db-migrate will
# work, not sure it's required for anything else
#
# https://github.com/Azure/azure-cli/issues/12441
# https://github.com/Azure/azure-cli/issues/30723
#
# Could maybe work around:
# https://github.com/Azure/azure-cli/blob/9071ce05dbb74fbf13503c913ef4abf3d08a0c51/doc/use_cli_in_airgapped_clouds.md?plain=1#L56
resource "azurerm_network_security_rule" "allow_resource_manager_outbound" {
  count = local.create_container_app_env ? 1 : 0

  name      = "allow-resource-manager-outbound"
  priority  = 4020
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix = var.subnet_config.subnet_cidr
  source_port_range     = "*"

  destination_address_prefix = "AzureResourceManager"
  destination_port_range     = "*"

  resource_group_name         = azurerm_network_security_group.subnet.resource_group_name
  network_security_group_name = azurerm_network_security_group.subnet.name
}
