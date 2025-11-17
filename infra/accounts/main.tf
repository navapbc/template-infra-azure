locals {
  subscription_id = var.account_id != null ? var.account_id : data.external.account_ids_by_name.result[var.account_name]

  shared_account_name = module.project_config.shared_account_name
  # When initially creating the "shared" account, we won't be able to lookup the
  # account id by backend file name (because the backend file doesn't exist
  # yet), so assume the current subscription is the shared one (since it should
  # be created first), which should be set by other means like the
  # ARM_SUBSCRIPTION_ID env var.
  shared_subscription_id = try(data.external.account_ids_by_name.result[local.shared_account_name], local.subscription_id)

  # These must match the name of the resources created while bootstrapping the account in set-up-current-account
  tf_state_resource_group_name = "${module.project_config.project_name}-tf"
  # This must be unique across the entire Azure service, not just within the resource group.
  tf_state_storage_account_id_str  = join("-", [local.subscription_id, local.tf_state_resource_group_name])
  tf_state_storage_account_id_hash = md5(local.tf_state_storage_account_id_str)
  tf_state_storage_account_name    = substr("tfst${local.tf_state_storage_account_id_hash}", 0, 24)

  # Choose the region where this infrastructure should be deployed.
  region = module.project_config.default_region

  # Set project tags that will be used to tag all resources. 
  tags = merge(module.project_config.default_tags, {
    description = "Backend resources required for terraform state management and GitHub authentication."
  })

  # To ease initial account setup, fallback to an owner list of just the current
  # user. Outside of the initial account setup, you should an `infra_admins` in
  # the project config for the account.
  infra_admin_config = try(module.project_config.infra_admins[var.account_name], { object_ids : [data.azurerm_client_config.current.object_id] })
}

data "azurerm_client_config" "current" {}

terraform {
  required_version = "~>1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.53.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

data "external" "account_ids_by_name" {
  program = ["${path.module}/../../bin/account-ids-by-name"]
}

provider "azurerm" {
  features {}
  storage_use_azuread = true

  subscription_id = local.subscription_id
}

provider "azurerm" {
  alias = "shared"

  features {}
  storage_use_azuread = true

  subscription_id = local.shared_subscription_id
}

module "project_config" {
  source = "../project-config"
}

resource "azurerm_resource_group" "subscription" {
  name     = module.project_config.project_name
  location = local.region
}

resource "azurerm_log_analytics_workspace" "subscription_logs" {
  name                = "subscription-logs"
  location            = local.region
  resource_group_name = azurerm_resource_group.subscription.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_resource_group" "tf_state" {
  name     = var.tf_state_resource_group_name_override != null ? var.tf_state_resource_group_name_override : local.tf_state_resource_group_name
  location = local.region
}

module "backend" {
  source               = "../modules/terraform-backend-azure"
  location             = azurerm_resource_group.tf_state.location
  resource_group_name  = azurerm_resource_group.tf_state.name
  storage_account_name = var.tf_state_storage_account_name_override != null ? var.tf_state_storage_account_name_override : local.tf_state_storage_account_name

  use_customer_managed_encryption_key = var.tf_state_use_customer_managed_encryption_key

  monitor_config = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.subscription_logs.id
  }
}

module "auth_github_actions" {
  source = "../modules/auth-github-actions"
  name   = "${module.project_config.project_name}-${var.account_name}-github-oidc"

  code_repository                  = module.project_config.code_repository
  tf_state_storage_container_scope = module.backend.tf_state_storage_container_scope

  resource_owners = local.infra_admin_config.object_ids
}

resource "azurerm_dns_zone" "shared_zone" {
  count = module.project_config.shared_hosted_zone != null && local.is_shared_subscription ? 1 : 0

  name                = module.project_config.shared_hosted_zone
  resource_group_name = azurerm_resource_group.subscription.name
}

module "certificate_store" {
  source = "../modules/certificate-store/resources"

  project_config = module.project_config
  account_name   = var.account_name

  monitor_config = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.subscription_logs.id
  }
}
