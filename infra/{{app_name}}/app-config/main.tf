locals {
  # app_name is the name of the application, which by convention should match the name of
  # the folder under /infra that corresponds to the application
  app_name = regex("/infra/([^/]+)/app-config$", abspath(path.module))[0]

  environments = ["dev", "staging", "prod"]
  project_name = module.project_config.project_name

  # Whether or not the application has a database
  # If enabled:
  # 1. The networks associated with this application's environments will have
  #    VPC endpoints needed by the database layer
  # 2. Each environment's config will have a database_config property that is used to
  #    pass db_vars into the infra/modules/service module, which provides the necessary
  #    configuration for the service to access the database
  has_database = true

  has_incident_management_service = true

  environment_configs = {
    dev     = module.dev_config
    staging = module.staging_config
    prod    = module.prod_config
  }

  # The name of the network that contains the resources shared across all
  # application environments, such as the build repository.
  # The list of networks can be found in /infra/networks
  # by looking for the backend config files of the form:
  #   <NETWORK_NAME>.*.tfbackend
  shared_network_name = "dev"
}

module "project_config" {
  source = "../../project-config"
}
