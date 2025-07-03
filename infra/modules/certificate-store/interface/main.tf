locals {
  # this must be globally unique
  cert_vault_name           = substr("certs-${var.account_name}-${var.project_config.project_unique_id}", 0, 24)
  cert_vault_location       = var.project_config.default_region
  cert_vault_resource_group = var.project_config.project_name
}
