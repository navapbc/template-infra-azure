# TODO: export relevant info
locals {
  create_container_app_env = try(contains(var.subnet_config.service_delegation, "Microsoft.App/environments"), false)
}

resource "azurerm_container_app_environment" "env" {
  count = local.create_container_app_env ? 1 : 0

  # TODO: ideally this would maybe be "${var.name}-app-env" or something, but
  # getting the value to other child modules is the hard part, just using the
  # subnet name is a little easier
  name                       = replace(var.name, "_", "-")
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  infrastructure_subnet_id           = azurerm_subnet.subnet.id
  infrastructure_resource_group_name = "${var.resource_group_name}-${var.name}-az-infra"
  zone_redundancy_enabled            = true

  # if not wanting internet access, then do not allocate a public IP address for
  # ingress
  internal_load_balancer_enabled = !local.enable_nat_gateway

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}
