module "cert_interface" {
  source = "../interface"

  project_config = var.project_config
  account_name   = var.account_name
}

data "azurerm_key_vault" "certs" {
  name                = module.cert_interface.cert_vault_name
  resource_group_name = module.cert_interface.cert_vault_resource_group_name
}
