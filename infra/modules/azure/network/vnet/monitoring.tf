data "azurerm_subscription" "current" {}

locals {
  network_watcher_storage_bucket_name_unique = "${data.azurerm_subscription.current.subscription_id}-${local.location}-${var.name}"

  # this matches the automatically generated name by Azure
  network_watcher_resource_group_name = "NetworkWatcherRG"
}

# Azure Network Watcher is limited to one instance per Subscription and region.
#
# By default it is automatically created when the first virtual network in a
# Subscription+region is created, unless the Subscription has a policy set to
# disable this behavior. If your Subscription does have the automatic creation
# disabled, you'll need to tweak things in here, depending on whether you will
# create/manage the resource here, or simply need to use different lookup
# parameters.
data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_${local.location}"
  resource_group_name = local.network_watcher_resource_group_name

  # you have to attempt to create a vnet first for Azure to create
  # the NW though, so for Subscription setup you need to manually create then
  # delete the Vnet before proceeding with setup?
  #
  # Technically we only depend on the _first_ vnet in this Subscription+region being created,
  depends_on = [azurerm_virtual_network.vnet]
}


# > The azurerm_network_watcher_flow_log creates a new storage lifecyle
# > management rule that overwrites existing rules. Please make sure to use a
# > storage_account with no existing management rules, until the issue is fixed.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/4.26.0/docs/resources/network_watcher_flow_log
resource "azurerm_storage_account" "nw" {
  # this must be globally unique
  name                = substr("vnetnw${md5(local.network_watcher_storage_bucket_name_unique)}", 0, 24)
  resource_group_name = local.network_watcher_resource_group_name
  location            = local.location

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  # checkov:skip=CKV_AZURE_206:Use cheapest storage unless your project requires greater redundancy for these logs

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  default_to_oauth_authentication = true
  local_user_enabled              = false
  shared_access_key_enabled       = true # this is how Network Watcher connects
  # checkov:skip=CKV2_AZURE_40:Shared Key authorization is required by Network Watcher

  sas_policy {
    expiration_period = "01.12:00:00"
  }

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  # checkov:skip=CKV_AZURE_59:TODO disable public access
  # checkov:skip=CKV2_AZURE_33:TODO disable public access

  # TODO: can we lock this down better?
  # network_rules {
  #   default_action = "Deny"
  #   bypass         = ["AzureServices"]
  #   # virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  # }

  blob_properties {
    # minor protection from accidental deletions
    delete_retention_policy {
      days = 7
    }
  }

  # checkov:skip=CKV_AZURE_33:Logging is set up via Azure Monitor
  # checkov:skip=CKV2_AZURE_1:TODO use customer managed key for all encryption needs
}

module "storage_monitor" {
  source = "../../monitor/storage"

  name                       = azurerm_storage_account.nw.name
  target_resource_id         = azurerm_storage_account.nw.id
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id
}

resource "azurerm_network_watcher_flow_log" "vnet" {
  network_watcher_name = data.azurerm_network_watcher.nw.name
  resource_group_name  = local.network_watcher_resource_group_name
  name                 = "flow-log-${azurerm_virtual_network.vnet.name}"

  target_resource_id = azurerm_virtual_network.vnet.id
  storage_account_id = azurerm_storage_account.nw.id
  enabled            = true

  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_workspace_id
    workspace_region      = var.log_analytics_workspace_location
    workspace_resource_id = var.log_analytics_workspace_resource_id
    interval_in_minutes   = 10
  }
}
