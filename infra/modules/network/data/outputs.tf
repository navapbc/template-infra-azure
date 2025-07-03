output "vnet" {
  description = "Vnet Object"
  value       = data.azurerm_virtual_network.vnet
}

output "subnets" {
  description = "Subnet list"
  value       = local.subnet_map
}

output "resource_group_name" {
  value = module.interface.resource_group_name
}
