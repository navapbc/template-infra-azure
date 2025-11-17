locals {
  shared_account_name    = module.project_config.network_configs[module.app_config.shared_network_name].account_name
  shared_subscription_id = data.external.account_ids_by_name.result[local.shared_account_name]

  # this would typically be either the current subscription or the shared
  # subscription, but make specific provider block for flexibility
  domain_subscription_id = data.external.account_ids_by_name.result[local.hosted_zone_account_names_in_network[0]]
}

terraform {
  required_version = "~>1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.53.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
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

  resource_providers_to_register = ["Microsoft.App"]

  subscription_id = data.external.account_ids_by_name.result[local.network_config.account_name]
}

provider "azurerm" {
  alias = "shared"

  features {}
  storage_use_azuread = true

  subscription_id = local.shared_subscription_id
}

provider "azurerm" {
  alias = "domain"

  features {}
  storage_use_azuread = true

  subscription_id = local.domain_subscription_id
}

provider "acme" {
  # if you wish to switch servers, be sure to destroy the existing resources
  # first, then update `server_url` and recreate
  #
  # https://github.com/vancluever/terraform-provider-acme/issues/88
  server_url = try(local.domain_config.acme_server_url, "https://acme-staging-v02.api.letsencrypt.org/directory")
}
