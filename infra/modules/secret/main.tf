locals {
  secret = var.manage_method == "generated" ? azurerm_key_vault_secret.secret[0] : data.azurerm_key_vault_secret.secret[0]
}

resource "random_password" "secret" {
  count = var.manage_method == "generated" ? 1 : 0

  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "secret" {
  count = var.manage_method == "generated" ? 1 : 0

  name         = var.secret_name
  value        = random_password.secret[0].result
  key_vault_id = var.key_vault_id

  # Azure Key Vault Secrets requires a value to be populated
  # and resets to the initial value unless we ignore changes
  lifecycle {
    ignore_changes = [value]
  }
}

data "azurerm_key_vault_secret" "secret" {
  count = var.manage_method == "manual" ? 1 : 0

  name         = var.secret_name
  key_vault_id = var.key_vault_id
}
