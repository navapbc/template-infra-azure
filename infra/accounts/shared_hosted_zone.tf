locals {
  has_shared_hosted_zone = module.project_config.shared_hosted_zone != null
  shared_hosted_zone_id  = local.has_shared_hosted_zone ? (local.is_shared_subscription ? azurerm_dns_zone.shared_zone[0].id : data.azurerm_dns_zone.shared_zone[0].id) : null
}

resource "azurerm_dns_zone" "shared_zone" {
  count = local.has_shared_hosted_zone && local.is_shared_subscription ? 1 : 0

  name                = module.project_config.shared_hosted_zone
  resource_group_name = azurerm_resource_group.subscription.name
}

data "azurerm_dns_zone" "shared_zone" {
  count = local.has_shared_hosted_zone && !local.is_shared_subscription ? 1 : 0

  provider = azurerm.shared

  name                = module.project_config.shared_hosted_zone
  resource_group_name = module.project_config.project_name
}

resource "azurerm_role_assignment" "shared_zone" {
  count = local.has_shared_hosted_zone && !local.is_shared_subscription ? 1 : 0

  role_definition_name = "DNS Zone Contributor"

  principal_id = module.auth_github_actions.object_id
  scope        = data.azurerm_dns_zone.shared_zone[0].id
}
