module "interface" {
  source              = "../interface"
  name                = var.name
  resource_group_name = var.resource_group_name
}

data "azurerm_postgresql_flexible_server" "db" {
  name                = var.name
  resource_group_name = var.resource_group_name
}

data "azuread_group" "db_app" {
  display_name = module.interface.app_username
}

data "azuread_group" "db_migrator" {
  display_name = module.interface.migrator_username
}
