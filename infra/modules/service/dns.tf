locals {
  should_configure_domain_name = !var.is_temporary && var.domain_name != null && var.domain_hosted_zone_name != null && var.domain_hosted_zone_subscription_id != null
  use_application_gateway      = var.application_gateway_subnet_id != null

  full_domain = var.domain_name
  dns_sub     = trimsuffix(trimsuffix(local.full_domain, var.domain_hosted_zone_name), ".")

  subdomain_name = local.should_configure_domain_name ? trimsuffix(trimsuffix(var.domain_name, var.domain_hosted_zone_name), ".") : null
  custom_fqdn    = local.should_configure_domain_name || local.use_application_gateway ? local.full_domain : null
}

resource "azurerm_dns_txt_record" "service" {
  provider = azurerm.domain

  # Don't create DNS record for temporary environments (e.g. ones spun up by CI/)
  count = var.manage_dns && local.should_configure_domain_name && !local.use_application_gateway ? 1 : 0

  # https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-certificates?tabs=general&pivots=azure-portal
  name                = "asuid.${local.dns_sub}"
  resource_group_name = var.domain_resource_group_name
  zone_name           = var.domain_hosted_zone_name
  ttl                 = 300

  record {
    value = azurerm_container_app.service.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "service" {
  provider = azurerm.domain

  count = var.manage_dns && local.should_configure_domain_name && !local.use_application_gateway ? 1 : 0

  name                = local.dns_sub
  resource_group_name = var.domain_resource_group_name
  zone_name           = var.domain_hosted_zone_name
  ttl                 = 300
  record              = azurerm_container_app.service.ingress[0].fqdn
}

# Longer term would maybe want to support pulling certs from Key Vault, but not
# yet supported via Terraform provider.
#
# https://github.com/hashicorp/terraform-provider-azurerm/issues/28118
# https://learn.microsoft.com/en-us/azure/container-apps/key-vault-certificates-manage
resource "azurerm_container_app_custom_domain" "service" {
  provider = azurerm.domain

  count = local.should_configure_domain_name && !local.use_application_gateway ? 1 : 0

  name                     = trimsuffix(trimprefix(azurerm_dns_txt_record.service[0].fqdn, "asuid."), ".")
  container_app_id         = azurerm_container_app.service.id
  certificate_binding_type = "SniEnabled"

  lifecycle {
    # When using an Azure created Managed Certificate these values must be added
    # to ignore_changes to prevent resource recreation.
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/27362#issuecomment-2407827846
resource "null_resource" "custom_domain_and_managed_certificate" {
  count = local.should_configure_domain_name && !local.use_application_gateway ? 1 : 0

  provisioner "local-exec" {
    command = "az containerapp hostname bind --hostname ${local.custom_fqdn} --resource-group ${var.resource_group_name} --name ${azurerm_container_app.service.name} --environment ${data.azurerm_container_app_environment.env.id} --subscription ${data.azurerm_subscription.current.subscription_id} --validation-method CNAME"
  }
  triggers = {
    settings     = azurerm_dns_cname_record.service[0].id
    managed_cert = azurerm_container_app_custom_domain.service[0].container_app_environment_managed_certificate_id
  }
  depends_on = [azurerm_dns_cname_record.service[0], azurerm_container_app_custom_domain.service[0]]
}
