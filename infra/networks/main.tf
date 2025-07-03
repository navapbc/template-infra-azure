locals {
  network_config = module.project_config.network_configs["${var.network_name}"]
  domain_config  = local.network_config.domain_config

  location = try(local.network_config.network.location, module.project_config.default_region)

  # List of configuration for all applications, even ones that are not in the current network
  # If project has multiple applications, add other app configs to this list
  app_configs = [module.app_config]

  # List of configuration for applications that are in the current network
  # An application is in the current network if at least one of its environments
  # is mapped to the network
  apps_in_network = [
    for app in local.app_configs :
    app
    if anytrue([
      for environment_config in app.environment_configs : true if environment_config.network_name == var.network_name
    ])
  ]

  has_database = anytrue([for app in local.apps_in_network : app.has_database])

  # Whether any of the applications in the network have an Application Gateway
  env_configs = flatten(
    [for app in local.apps_in_network :
      [for env_config in app.environment_configs :
        env_config if env_config.network_name == var.network_name
      ]
  ])
  use_application_gateway = anytrue([for env_config in local.env_configs : env_config.use_application_gateway])

  app_domain_configs = flatten(
    [for env_config in local.env_configs :
      env_config.domain_config
    ]
  )

  hosted_zone_account_names_in_network = distinct(flatten(
    [for domain_config in local.app_domain_configs :
      domain_config.hosted_zone_account_name
    ]
  ))

  domains_in_network = distinct(flatten(
    [for domain_config in local.app_domain_configs :
      domain_config.domain_name if domain_config.domain_name != null
    ]
  ))

  subdomains_in_network = distinct(flatten(
    [for domain_config in local.app_domain_configs :
      domain_config.domain_name if domain_config.domain_name != null && domain_config.is_subdomain_of_network == true
    ]
  ))

  non_subdomains_in_network = distinct(flatten(
    [for domain_config in local.app_domain_configs :
      domain_config.domain_name if domain_config.domain_name != null && domain_config.is_subdomain_of_network == false
    ]
  ))

  auto_generated_domain_cert_configs = merge({
    for domain in local.non_subdomains_in_network : domain => { source = "issued" }
  }, length(local.subdomains_in_network) != 0 ? { "*.${local.network_config.domain_config.hosted_zone}" = { source = "issued" } } : {})

  manual_cert_configs = try(local.domain_config.certificate_configs, {})

  certificate_configs = try(local.domain_config.manage_certs, local.use_application_gateway) ? merge(local.auto_generated_domain_cert_configs, local.manual_cert_configs) : local.manual_cert_configs

  container_registry_config = local.apps_in_network[0].build_repository_config
}

module "app_config" {
  source = "../app/app-config"
}

module "project_config" {
  source = "../project-config"
}

module "network_interface" {
  source       = "../modules/network/interface"
  project_name = module.project_config.project_name
  network_name = var.network_name
}

resource "azurerm_resource_group" "network" {
  name     = module.network_interface.resource_group_name
  location = local.location
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "logs"
  location            = local.location
  resource_group_name = azurerm_resource_group.network.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "network" {
  source              = "../modules/network/resources"
  project_name        = module.project_config.project_name
  network_name        = var.network_name
  network_config      = local.network_config
  has_database        = local.has_database
  resource_group_name = azurerm_resource_group.network.name

  log_analytics_workspace_resource_id  = azurerm_log_analytics_workspace.logs.id
  log_analytics_workspace_workspace_id = azurerm_log_analytics_workspace.logs.workspace_id
  log_analytics_workspace_location     = azurerm_log_analytics_workspace.logs.location

  container_registry_id   = local.container_registry_config.registry_id
  container_registry_name = local.container_registry_config.registry_name
}

module "certificate_store" {
  source = "../modules/certificate-store/data"

  project_config = module.project_config
  account_name   = local.network_config.account_name
}

module "domain" {
  source = "../modules/domain/resources"
  providers = {
    azurerm        = azurerm
    azurerm.domain = azurerm.domain
  }

  # We use the app domain config, just to avoid re-implementing the logic to
  # determine the foundational hosted zone, which does mean the network requires
  # at least one application defined for it. Re-implement the hosted zone logic
  # from env-config/domain.tf if this presents a problem for you.
  name                = local.app_domain_configs[0].hosted_zone
  create_dns_zone     = local.app_domain_configs[0].hosted_zone != module.project_config.shared_hosted_zone
  manage_dns          = local.domain_config.manage_dns
  resource_group_name = azurerm_resource_group.network.name

  certificate_configs = local.certificate_configs

  cert_vault_id      = module.certificate_store.cert_vault_id
  cert_contact_email = try(local.domain_config.cert_contact_email, module.project_config.default_certificate_contact_email)
}

module "cert_endpoint" {
  source = "../modules/azure/network/private-endpoint"

  enable      = try(local.network_config.network.private_endpoints_subnet_name, null) != null
  subnet_id   = try(module.network.subnets[local.network_config.network.private_endpoints_subnet_name].id, null)
  resource_id = module.certificate_store.cert_vault_id
}
