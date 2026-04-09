resource "azurerm_storage_account" "storage" {
  name                       = var.storage_account_name
  resource_group_name        = var.resource_group_name
  location                   = var.resource_group_location
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

  identity {
    type = "SystemAssigned"
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

  # checkov:skip=CKV_AZURE_33:Logging is set up via Azure Monitor
}

resource "azurerm_storage_container" "documents" {
  name               = var.container_name
  storage_account_id = azurerm_storage_account.storage.id

  # checkov:skip=CKV2_AZURE_21:Logging is set up via Azure Monitor
}

module "storage_monitor" {
  source = "../azure/monitor/storage"
  enable = var.monitor_config.enabled

  name                       = azurerm_storage_account.storage.name
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.monitor_config.log_analytics_workspace_id
}
