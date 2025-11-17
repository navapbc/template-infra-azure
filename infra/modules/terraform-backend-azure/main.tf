data "azurerm_subscription" "current" {}

resource "azurerm_storage_account" "tf_state" {
  name                       = var.storage_account_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  account_kind               = "StorageV2"
  account_tier               = "Standard"
  account_replication_type   = "GRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  local_user_enabled              = false

  allow_nested_items_to_be_public = false
  # public_network_access_enabled = false
  # checkov:skip=CKV_AZURE_59:TODO disable public access
  # checkov:skip=CKV2_AZURE_33:TODO disable public access

  # the TF state shouldn't ever use these types of objects, but for thoroughness
  queue_encryption_key_type = var.use_customer_managed_encryption_key ? "Account" : "Service"
  table_encryption_key_type = var.use_customer_managed_encryption_key ? "Account" : "Service"

  identity {
    type         = var.use_customer_managed_encryption_key ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.use_customer_managed_encryption_key ? [azurerm_user_assigned_identity.tf_state[0].id] : []
  }

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 90
    last_access_time_enabled      = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  lifecycle {
    ignore_changes = [customer_managed_key]
  }

  # checkov:skip=CKV_AZURE_33:Logging is set up via Azure Monitor
}

resource "azurerm_storage_container" "tf_state" {
  name               = var.storage_container_name
  storage_account_id = azurerm_storage_account.tf_state.id

  # checkov:skip=CKV2_AZURE_21:Logging is set up via Azure Monitor
}

module "storage_monitor" {
  source = "../azure/monitor/storage"
  enable = var.monitor_config.enabled

  name                       = azurerm_storage_account.tf_state.name
  target_resource_id         = azurerm_storage_account.tf_state.id
  log_analytics_workspace_id = var.monitor_config.log_analytics_workspace_id
}

resource "azurerm_key_vault" "tf_state" {
  count = var.use_customer_managed_encryption_key ? 1 : 0

  name                = var.storage_account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_subscription.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  purge_protection_enabled = true

  # TODO: disable public access
  # public_network_access_enabled = false
  # checkov:skip=CKV_AZURE_189:TODO disable public access
  # checkov:skip=CKV_AZURE_109:TODO disable public access
  # checkov:skip=CKV2_AZURE_32:TODO disable public access
}

resource "azurerm_key_vault_key" "tf_state" {
  count = var.use_customer_managed_encryption_key ? 1 : 0

  name         = "tf-state"
  key_vault_id = azurerm_key_vault.tf_state[0].id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P1Y"
    notify_before_expiry = "P29D"
  }

  # checkov:skip=CKV_AZURE_112:HSM backed keys may be desired, but defaulting to a regular key
  # checkov:skip=CKV_AZURE_40:Key is auto-rotated with no ultimate expiration date
}

resource "azurerm_user_assigned_identity" "tf_state" {
  count = var.use_customer_managed_encryption_key ? 1 : 0

  name                = "${var.storage_account_name}-uai"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "tf_state_key" {
  count = var.use_customer_managed_encryption_key ? 1 : 0

  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.tf_state[0].principal_id
  scope                = azurerm_key_vault.tf_state[0].id
}

resource "azurerm_storage_account_customer_managed_key" "tf_state" {
  count = var.use_customer_managed_encryption_key ? 1 : 0

  storage_account_id        = azurerm_storage_account.tf_state.id
  key_vault_id              = azurerm_key_vault.tf_state[0].id
  key_name                  = azurerm_key_vault_key.tf_state[0].name
  user_assigned_identity_id = azurerm_user_assigned_identity.tf_state[0].id
}
