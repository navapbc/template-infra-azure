locals {
  storage_config       = local.environment_config.storage_config
  storage_account_name = substr("${local.prefix}${local.storage_config.account_name}", 0, 24)
}

data "azurerm_log_analytics_workspace" "logs" {
  count = module.app_config.has_blob_storage && !local.is_temporary ? 1 : 0

  name                = "subscription-logs"
  resource_group_name = module.network.resource_group_name
}

module "storage" {
  count  = module.app_config.has_blob_storage ? 1 : 0
  source = "../../modules/storage"

  name                    = local.storage_account_name
  resource_group_name     = local.is_temporary ? local.resource_group_name : azurerm_resource_group.service[0].name
  resource_group_location = local.location
  container_name          = local.storage_config.container_name
  is_temporary            = local.is_temporary

  monitor_config = {
    enabled                    = !local.is_temporary
    log_analytics_workspace_id = !local.is_temporary ? data.azurerm_log_analytics_workspace.logs[0].id : ""
  }

  # Grant storage access to service identities
  # This replaces the role assignment previously done in modules/service/storage_access.tf
  principals_with_access = [
    {
      principal_id = module.service.service_user_identity_id
      description  = "App service managed identity"
    }
  ]
}

module "storage_endpoint" {
  source = "../../modules/azure/network/private-endpoint"

  enable            = module.app_config.has_blob_storage && !local.is_temporary && local.private_endpoints_subnet != null
  subnet_id         = local.private_endpoints_subnet != null ? local.private_endpoints_subnet.id : null
  resource_id       = module.app_config.has_blob_storage ? module.storage[0].storage_account_id : ""
  dns_zone_key      = "blob"
  subresource_names = ["blob"]
}
