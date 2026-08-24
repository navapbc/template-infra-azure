output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnets" {
  value = { for subnet in module.subnet : subnet.name => subnet }
}
