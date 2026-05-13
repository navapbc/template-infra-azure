# DEPRECATED: This approach of granting storage access from the service module
# is deprecated in favor of using the storage module's principals_with_access variable.
# This allows more flexible and centralized access control management.
#
# Migration: Instead of passing storage_vars to the service module, pass the
# service identity's principal_id to the storage module's principals_with_access variable.
#
# Example in {{app_name}}/service/storage.tf:
#   module "storage" {
#     ...
#     principals_with_access = [{
#       principal_id = module.service.service_user_identity_id
#       description  = "App service managed identity"
#     }]
#   }
#
# This file will be removed in a future version once all implementations migrate.
resource "azurerm_role_assignment" "app_storage" {
  count = var.storage_vars != null ? 1 : 0

  scope                = var.storage_vars.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  skip_service_principal_aad_check = var.is_temporary
}
