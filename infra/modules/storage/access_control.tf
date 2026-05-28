# Access control for storage account
# Assigns Storage Blob Data Contributor role to specified principals
# Similar pattern to AWS template's storage access policy

resource "azurerm_role_assignment" "storage_access" {
  for_each = { for idx, principal in var.principals_with_access : idx => principal }

  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.principal_id
  description          = each.value.description

  # ABAC conditions for fine-grained access control
  # See: https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-format
  condition         = each.value.condition
  condition_version = each.value.condition_version

  skip_service_principal_aad_check = var.is_temporary
}

# Fetch the built-in role definition ID for Storage Blob Data Contributor
# This allows other modules to create their own role assignments if needed
data "azurerm_role_definition" "storage_blob_data_contributor" {
  name = "Storage Blob Data Contributor"
}
