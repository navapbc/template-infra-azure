module "prod_config" {
  source         = "./env-config"
  project_name   = local.project_name
  app_name       = local.app_name
  default_region = module.project_config.default_region
  environment    = "prod"
  network_name   = "prod"
  domain_name    = "platform-test-azure.navateam.com"
  has_database   = local.has_database

  service_cpu                    = 1
  service_memory                 = "2Gi"
  service_desired_instance_count = 3

  service_application_gateway_sku_name = "Standard_v2"
}
