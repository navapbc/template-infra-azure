locals {
  # The prefix is used to create uniquely named resources per terraform workspace, which
  # are needed in CI/CD for preview environments and tests.
  #
  # To isolate changes during infrastructure development by using manually created
  # terraform workspaces, see: /docs/infra/develop-and-test-infrastructure-in-isolation-using-workspaces.md
  prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"

  # All non-default terraform workspaces are considered temporary.
  # Temporary environments do not have deletion protection enabled.
  # Examples: pull request preview environments are temporary.
  is_temporary = terraform.workspace != "default"

  environment_config = module.app_config.environment_configs[var.environment_name]
  service_config     = local.environment_config.service_config

  service_name        = "${local.prefix}${local.service_config.service_name}"
  resource_group_name = "${local.service_config.service_name}-service"

  network_config           = module.project_config.network_configs[local.environment_config.network_name]
  private_endpoints_subnet = lookup(module.network.subnets, try(local.network_config.network.private_endpoints_subnet_name, ""), null)

  location = try(local.network_config.network.location, module.project_config.default_region)
}

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
    use_oidc         = true
  }
}

data "external" "account_ids_by_name" {
  program = ["${path.module}/../../../bin/account-ids-by-name"]
}

provider "azurerm" {
  use_oidc = true
  features {}

  subscription_id = data.external.account_ids_by_name.result[local.environment_config.account_name]
}

provider "azurerm" {
  alias = "domain"

  use_oidc = true
  features {}

  # fall back to current subscription so provider can be initialized, but we
  # won't use it if hosted_zone_subscription_id is not defined
  subscription_id = local.hosted_zone_subscription_id != null ? local.hosted_zone_subscription_id : data.external.account_ids_by_name.result[local.environment_config.account_name]
}

module "project_config" {
  source = "../../project-config"
}

module "app_config" {
  source = "../app-config"
}

module "network" {
  source       = "../../modules/network/data"
  project_name = module.project_config.project_name
  network_name = local.environment_config.network_name
}

module "endpoint_refs" {
  source = "../../modules/azure/private-endpoint-dns-refs"
}

resource "azurerm_resource_group" "service" {
  count = local.is_temporary ? 0 : 1

  name     = local.resource_group_name
  location = local.location
}

module "service" {
  source = "../../modules/service"
  providers = {
    azurerm        = azurerm
    azurerm.domain = azurerm.domain
  }

  service_name            = local.service_name
  resource_group_name     = local.is_temporary ? local.resource_group_name : azurerm_resource_group.service[0].name
  resource_group_location = local.location
  image_registry_id       = module.app_config.build_repository_config.registry_id
  image_registry_url      = module.app_config.build_repository_config.registry_url
  image_repository_url    = module.app_config.build_repository_config.repository_url
  image_tag               = local.image_tag

  subnet_name                 = local.environment_config.use_application_gateway ? module.network.subnets["apps-private"].name : module.network.subnets["apps-public"].name
  network_resource_group_name = module.network.resource_group_name

  application_gateway_subnet_id = local.environment_config.use_application_gateway ? module.network.subnets["gateway"].id : null
  application_gateway_sku_name  = local.service_config.application_gateway_sku_name

  domain_name                        = module.domain.domain_name
  domain_hosted_zone_name            = module.domain.hosted_zone_name
  domain_network_zone_name           = module.domain.network_zone_name
  domain_resource_group_name         = module.domain.resource_group_name
  domain_certificate_secret_id       = module.domain.certificate_secret_id
  domain_hosted_zone_subscription_id = local.hosted_zone_subscription_id
  manage_dns                         = local.network_config.domain_config.manage_dns

  cpu                    = local.service_config.cpu
  memory                 = local.service_config.memory
  desired_instance_count = local.service_config.desired_instance_count

  # Note: The secrets will reference the specific hash of the current revision
  # If the secret is manually updated, you will need to re-run terraform apply
  # for the new version to be picked up and updated in the revision
  secrets = [
    for secret_name in keys(local.service_config.secrets) : {
      name                    = secret_name
      id                      = module.secrets[secret_name].secret_id
      resource_versionless_id = module.secrets[secret_name].secret_resource_versionless_id
    }
  ]

  db_vars = module.app_config.has_database ? {
    migrator_group_object_id = module.database[0].migrator_object_id
    app_group_object_id      = module.database[0].app_object_id
    connection_info = {
      host        = module.database[0].host
      port        = module.database[0].port
      user        = module.database[0].app_username
      db_name     = module.database[0].db_name
      schema_name = module.database[0].schema_name
    }
  } : null

  is_temporary = local.is_temporary

  depends_on = [
    # we directly depend on modules.secrets above, but the service can't access
    # those secrets until the private endpoint is created
    module.secrets_endpoint
  ]
}
