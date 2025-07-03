locals {
  domain_config = local.environment_config.domain_config
  domain_name   = "${local.prefix}${local.domain_config.domain_name}"

  hosted_zone_subscription_id = local.domain_config.hosted_zone_account_name != null ? data.external.account_ids_by_name.result[local.domain_config.hosted_zone_account_name] : null
}

module "certificate_store" {
  source = "../../modules/certificate-store/data"

  project_config = module.project_config
  account_name   = local.environment_config.account_name
}

module "domain" {
  source = "../../modules/domain/data"
  providers = {
    azurerm        = azurerm
    azurerm.domain = azurerm.domain
  }

  hosted_zone = local.hosted_zone_subscription_id != null ? local.domain_config.hosted_zone : null
  domain_name = local.domain_name
  cert_name   = local.environment_config.use_application_gateway ? local.domain_config.cert_name : null

  cert_vault_id = module.certificate_store.cert_vault_id
}
