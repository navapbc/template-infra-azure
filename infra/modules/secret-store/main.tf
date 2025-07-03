data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                = var.vault_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  enable_rbac_authorization = true

  # note these can only be configured once, you'll need to recreate the resource
  # if wanting to change in the future, defaults listed here
  #
  # soft_delete_retention_days = 90
  # purge_protection_enabled = false
  #
  # checkov:skip=CKV_AZURE_110:TODO decide if we want to force purge protection by default
  # checkov:skip=CKV_AZURE_42:TODO decide if we want to force purge protection by default

  # TODO: disable public access
  # public_network_access_enabled = false
  # checkov:skip=CKV_AZURE_189:TODO disable public access
  # checkov:skip=CKV_AZURE_109:TODO disable public access
  # checkov:skip=CKV2_AZURE_32:TODO disable public access
}
