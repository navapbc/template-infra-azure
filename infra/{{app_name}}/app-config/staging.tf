module "staging_config" {
  source         = "./env-config"
  project_name   = local.project_name
  app_name       = local.app_name
  default_region = module.project_config.default_region
  environment    = "staging"
  network_name   = "staging"
  domain_name    = local.app_name
  has_database   = local.has_database
}
