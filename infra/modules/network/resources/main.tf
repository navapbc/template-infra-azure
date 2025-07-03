module "vnet" {
  source              = "../../azure/network/vnet"
  name                = var.network_name
  resource_group_name = var.resource_group_name
  vnet_config         = var.network_config.network

  log_analytics_workspace_resource_id  = var.log_analytics_workspace_resource_id
  log_analytics_workspace_workspace_id = var.log_analytics_workspace_workspace_id
  log_analytics_workspace_location     = var.log_analytics_workspace_location
}
