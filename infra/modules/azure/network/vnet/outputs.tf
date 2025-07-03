output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnets" {
  # value = module.subnet
  value = { for subnet in module.subnet : subnet.name => subnet }
}
