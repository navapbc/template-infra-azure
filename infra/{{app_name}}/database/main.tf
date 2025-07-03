locals {
  # The prefix key/value pair is used for Terraform Workspaces, which is useful for projects with multiple infrastructure developers.
  # By default, Terraform creates a workspace named “default.” If a non-default workspace is not created this prefix will equal “default”,
  # if you choose not to use workspaces set this value to "dev"
  prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"

  is_temporary = terraform.workspace != "default"

  environment_config = module.app_config.environment_configs[var.environment_name]
  database_config    = local.environment_config.database_config

  name                = "${local.prefix}${local.database_config.cluster_name}"
  resource_group_name = "${local.prefix}${local.database_config.resource_group_name}"

  infra_admin_config = module.project_config.infra_admins[local.environment_config.account_name]
}

terraform {
  required_version = "~>1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.33.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
  }
}

data "external" "account_ids_by_name" {
  program = ["${path.module}/../../../bin/account-ids-by-name"]
}

provider "azurerm" {
  storage_use_azuread = true
  use_oidc            = true

  features {
    postgresql_flexible_server {
      restart_server_on_configuration_value_change = false
    }
  }

  subscription_id = data.external.account_ids_by_name.result[local.environment_config.account_name]
}

module "project_config" {
  source = "../../project-config"
}

module "app_config" {
  source = "../app-config"
}

module "endpoint_refs" {
  source = "../../modules/azure/private-endpoint-dns-refs"
}

data "azurerm_private_dns_zone" "db" {
  name                = module.endpoint_refs.zones["postgresql"]
  resource_group_name = module.network.resource_group_name
}

module "network" {
  source       = "../../modules/network/data"
  project_name = module.project_config.project_name
  network_name = local.environment_config.network_name
}

resource "azurerm_resource_group" "db" {
  name     = local.resource_group_name
  location = module.project_config.default_region
}

module "database" {
  source = "../../modules/database/resources"

  name                = local.name
  resource_group_name = azurerm_resource_group.db.name
  resource_owners     = local.infra_admin_config.object_ids

  role_manager_image_registry_id    = module.app_config.build_repository_config.registry_id
  role_manager_image_registry_url   = module.app_config.build_repository_config.registry_url
  role_manager_image_repository_url = module.app_config.build_repository_config.db_role_manager_repository_url
  role_manager_image_tag            = local.role_manager_image_tag

  subnet_id                   = module.network.subnets["database"].id
  role_manager_subnet_name    = module.network.subnets["apps-private"].name
  network_resource_group_name = module.network.resource_group_name

  dns_zone_id   = data.azurerm_private_dns_zone.db.id
  location      = module.project_config.default_region
  flex_sku_name = "B_Standard_B1ms"
}
