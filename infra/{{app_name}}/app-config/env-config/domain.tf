locals {
  shared_hosted_zone            = module.project_config.shared_hosted_zone
  network_hosted_zone           = local.network_config.domain_config.hosted_zone
  is_network_zone_sub_to_shared = local.shared_hosted_zone != null ? endswith(local.network_hosted_zone, local.shared_hosted_zone) : false
  hosted_zone                   = local.is_network_zone_sub_to_shared ? local.shared_hosted_zone : local.network_hosted_zone

  is_domain_name_var_fqdn = strcontains(var.domain_name, ".")
  is_subdomain_of_network = !local.is_domain_name_var_fqdn

  domain_name = local.is_domain_name_var_fqdn ? var.domain_name : "${var.domain_name}.${local.network_hosted_zone}"

  domain_config = {
    hosted_zone = local.hosted_zone
    domain_name = local.domain_name

    is_subdomain_of_network = local.is_subdomain_of_network
    cert_name               = var.cert_name != null ? var.cert_name : (local.is_subdomain_of_network ? "*.${local.network_hosted_zone}" : local.domain_name)

    hosted_zone_account_name = local.is_network_zone_sub_to_shared ? module.project_config.shared_account_name : (local.network_config.manage_dns ? local.network_config.account_name : null)
  }
}
