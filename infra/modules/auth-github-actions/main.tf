data "azurerm_subscription" "current" {}

locals {
  subscription_roles = toset([
    "Contributor", # control plane access to most things, but can't assign roles (like Owner)
    # TODO could replace these both with "Key Vault Administrator"?
    "Key Vault Secrets Officer",               # read/write the actual service secrets data/objects
    "Key Vault Certificates Officer",          # read/write certificate secrets data/objects
    "Role Based Access Control Administrator", # read/create service and DB user groups (almost like Owner role)
  ])

}

resource "azuread_application_registration" "github_actions" {
  display_name = var.name
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application_registration.github_actions.client_id
  owners    = var.resource_owners
}

data "azuread_application_published_app_ids" "well_known" {}
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

resource "azuread_application_api_access" "github_actions_msgraph" {
  application_id = azuread_application_registration.github_actions.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"],
  ]
}

# If your user(s) has the "Global Administrator" or "Privileged Role Administrator"
# role, you can uncomment this for automated admin consent to above API
# permissions. Otherwise you will need to have someone with those roles approve
# the permissions in the Azure portal for the registered application.
#
# resource "azuread_app_role_assignment" "github_actions_msgraph_group_read" {
#   app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"]
#   principal_object_id = azuread_service_principal.github_actions.object_id
#   resource_object_id  = data.azuread_service_principal.msgraph.object_id
# }

# TODO: alt naming
# display_name = "oidc-github-credentials"
# description = "OIDC credentials for Github Actions"
resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application_registration.github_actions.id
  display_name   = "github"
  description    = "GitHub Actions Service Principal"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.code_repository}"

  # checkov:skip=CKV_AZURE_249:GH needs to be scoped to the repo
}

resource "azurerm_role_assignment" "ghaction_tfstate" {
  role_definition_name = "Storage Blob Data Contributor"
  description          = "Allow read/write to terraform state"

  principal_id = azuread_service_principal.github_actions.object_id
  scope        = var.tf_state_storage_container_scope
}

resource "azurerm_role_assignment" "subscription_roles" {
  for_each = local.subscription_roles

  role_definition_name = each.key

  principal_id = azuread_service_principal.github_actions.object_id
  scope        = data.azurerm_subscription.current.id
}
