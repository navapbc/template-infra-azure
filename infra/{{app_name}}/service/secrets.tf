locals {
  # this must be globally unique
  vault_name                = substr("${local.service_config.service_name}-${local.location}-${module.project_config.project_unique_id}", 0, 24)
  vault_resource_group_name = "${local.service_config.service_name}-secrets"

  key_vault_id = local.is_temporary ? data.azurerm_key_vault.vault[0].id : module.secret_store[0].key_vault_id
}

data "azurerm_key_vault" "vault" {
  count = local.is_temporary ? 1 : 0

  name                = local.vault_name
  resource_group_name = local.vault_resource_group_name
}

resource "azurerm_resource_group" "secrets" {
  count = local.is_temporary ? 0 : 1

  name     = local.vault_resource_group_name
  location = local.location
}

module "secret_store" {
  count = local.is_temporary ? 0 : 1

  source = "../../modules/secret-store"

  vault_name              = local.vault_name
  resource_group_location = azurerm_resource_group.secrets[0].location
  resource_group_name     = azurerm_resource_group.secrets[0].name
}

module "secrets" {
  for_each = local.service_config.secrets

  source = "../../modules/secret"

  # When generating secrets and storing them in parameter store, append the
  # terraform workspace to the secret store path if the environment is temporary
  # to avoid conflicts with existing environments.
  # Don't do this for secrets that are managed manually since the temporary
  # environments will need to share those secrets.
  secret_name = (each.value.manage_method == "generated" && local.is_temporary ?
    "${each.value.secret_name}-${terraform.workspace}" :
    each.value.secret_name
  )

  key_vault_id = local.key_vault_id

  manage_method = each.value.manage_method
}

module "secrets_endpoint" {
  source = "../../modules/azure/network/private-endpoint"

  enable      = !local.is_temporary && local.private_endpoints_subnet != null
  subnet_id   = local.private_endpoints_subnet != null ? local.private_endpoints_subnet.id : null
  resource_id = local.key_vault_id
}
