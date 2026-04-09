resource "azurerm_role_assignment" "app_storage" {
  count = var.storage_vars != null ? 1 : 0

  scope                = var.storage_vars.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  skip_service_principal_aad_check = var.is_temporary
}
