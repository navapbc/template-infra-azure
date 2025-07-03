locals {
  is_shared_subscription = var.account_name == local.shared_account_name
  container_registry_id  = local.is_shared_subscription ? module.container_registry_resource[0].container_registry_id : module.container_registry_data[0].container_registry_id
}

module "container_registry_interface" {
  source = "../modules/azure/container-registry/interface"

  project_config = module.project_config
}

module "container_registry_resource" {
  count = local.is_shared_subscription ? 1 : 0

  source = "../modules/azure/container-registry/resources"

  name = module.container_registry_interface.container_registry_name

  # For consistency with the data block below, we'll use the interface value,
  # but we could use the resource group directly, like:
  #
  # resource_group_name           = azurerm_resource_group.subscription.name
  resource_group_name = module.container_registry_interface.container_registry_resource_group_name
  location            = azurerm_resource_group.subscription.location
}

module "container_registry_data" {
  count = !local.is_shared_subscription ? 1 : 0

  source = "../modules/azure/container-registry/data"
  providers = {
    azurerm = azurerm.shared
  }

  name                = module.container_registry_interface.container_registry_name
  resource_group_name = module.container_registry_interface.container_registry_resource_group_name
}

# Container Registry permissions for Github Actions
resource "azurerm_role_assignment" "container_registry_permissions" {
  count = !local.is_shared_subscription ? 1 : 0

  role_definition_name = "Contributor"
  description          = "Allow reading and writing to container registry"

  principal_id = module.auth_github_actions.object_id
  scope        = local.container_registry_id
}
