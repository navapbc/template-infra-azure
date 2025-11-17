data "azurerm_subscription" "current" {}

module "cert_interface" {
  source = "../interface"

  project_config = var.project_config
  account_name   = var.account_name
}

resource "azurerm_key_vault" "certs" {
  # this must be globally unique
  name                = module.cert_interface.cert_vault_name
  location            = module.cert_interface.cert_vault_location
  resource_group_name = module.cert_interface.cert_vault_resource_group_name
  tenant_id           = data.azurerm_subscription.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

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

resource "azurerm_monitor_diagnostic_setting" "tf_state" {
  count = var.monitor_config.enabled ? 1 : 0

  name                       = module.cert_interface.cert_vault_name
  target_resource_id         = azurerm_key_vault.certs.id
  log_analytics_workspace_id = var.monitor_config.log_analytics_workspace_id

  enabled_log {
    category_group = "audit" # or "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
