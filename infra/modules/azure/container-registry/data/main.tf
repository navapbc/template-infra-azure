terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

data "azurerm_container_registry" "registry" {
  name                = var.name
  resource_group_name = var.resource_group_name
}
