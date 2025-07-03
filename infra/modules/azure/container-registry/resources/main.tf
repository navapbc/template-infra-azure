resource "azurerm_container_registry" "registry" {
  # this must be globally unique
  name = var.name

  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  data_endpoint_enabled         = true
  quarantine_policy_enabled     = false
  retention_policy_in_days      = 7
  trust_policy_enabled          = true
  anonymous_pull_enabled        = false
  zone_redundancy_enabled       = true

  # Disabled for now. Can enable if deemed necessary.
  # Needs to be in a different location than registry location.
  # georeplications {
  #   location                = "East US"
  #   zone_redundancy_enabled = true
  #   tags                    = {}
  # }
  # checkov:skip=CKV_AZURE_165:Skip ensure geo-replicated container registries to match multi-region container deployments

  # TODO: See if we want to quarantine images (seem like it's not well supported)
  # and if we want to disable public networking (can we still push from github actions)
  # checkov:skip=CKV_AZURE_166:Skip ensure container image quarantine, scan, and mark images verified
  # checkov:skip=CKV_AZURE_139:Skip ensure ACR set to disable public networking
}
