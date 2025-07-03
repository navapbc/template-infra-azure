data "azurerm_subscription" "domain" {
  provider = azurerm.domain
}

locals {
  # Filter configs for issued certificates.
  # These certificates are managed by the project.
  # TODO: or check that local.dsn_zone exists? Which should be null if we are not managing dns?
  issued_certificate_configs = var.manage_dns ? {
    for domain, config in var.certificate_configs : domain => config
    if config.source == "issued"
  } : {}

  # Filter configs for imported certificates.
  # These certificates are created outside of the project and imported.
  imported_certificate_configs = {
    for domain, config in var.certificate_configs : domain => config
    if config.source == "imported"
  }
}

# Note this stores credentials in the Terraform state. If this is a problem for
# your use case, you should manage acquiring/renewing certs out-of-band/switch
# to different setup.
resource "acme_registration" "reg" {
  email_address = var.cert_contact_email
}

resource "acme_certificate" "certificate" {
  for_each = local.issued_certificate_configs

  # Note this stores credentials in the Terraform state, see above note.
  account_key_pem = acme_registration.reg.account_key_pem
  common_name     = each.key
  # subject_alternative_names = ["www2.example.com"]

  dns_challenge {
    provider = "azuredns"

    config = {
      AZURE_RESOURCE_GROUP  = local.dns_zone.resource_group_name               # DNS zone resource group.
      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.domain.subscription_id # DNS zone subscription ID.
      AZURE_ZONE_NAME       = local.dns_zone.name                              # Zone name to use inside Azure DNS service to add the TXT record in.

      # AZURE_ENVIRONMENT = "public" # Azure environment, one of: public, usgovernment, and china.
    }
  }
}

resource "azurerm_key_vault_certificate" "key_vault_certificate" {
  for_each = local.issued_certificate_configs

  name         = replace(replace(each.key, ".", "-"), "*", "wildcard")
  key_vault_id = var.cert_vault_id

  certificate {
    contents = acme_certificate.certificate[each.key].certificate_p12
  }
}
