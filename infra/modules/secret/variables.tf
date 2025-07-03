variable "manage_method" {
  type        = string
  description = <<EOT
    Method to manage the secret. Options are 'manual' or 'generated'.
    Set to 'generated' to generate a random secret.
    Set to 'manual' to reference a secret that was manually created and stored in Azure Key Vault.
    Defaults to 'generated'."
    EOT
  default     = "generated"
  validation {
    condition     = can(regex("^(manual|generated)$", var.manage_method))
    error_message = "Invalid manage_method. Must be 'manual' or 'generated'."
  }
}

variable "secret_name" {
  type        = string
  description = "Name of the secret"
}

variable "key_vault_id" {
  type = string
}
