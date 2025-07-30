module "dev_config" {
  source       = "./env-config"
  project_name = local.project_name
  app_name     = local.app_name
  environment  = "dev"
  network_name = "dev"
  domain_name  = local.app_name
  has_database = local.has_database
}
