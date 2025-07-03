data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "app_cr" {
  scope                = var.image_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  skip_service_principal_aad_check = var.is_temporary
}

resource "azurerm_role_assignment" "app_secrets" {
  for_each             = local.secrets
  scope                = each.value.resource_versionless_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  skip_service_principal_aad_check = var.is_temporary
}

resource "azurerm_role_assignment" "migrator_cr" {
  scope                = var.image_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.migrator.principal_id

  skip_service_principal_aad_check = var.is_temporary
}

resource "azurerm_role_assignment" "migrator_secrets" {
  for_each             = local.secrets
  scope                = each.value.resource_versionless_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.migrator.principal_id

  skip_service_principal_aad_check = var.is_temporary
}
