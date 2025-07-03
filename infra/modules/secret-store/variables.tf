variable "vault_name" {
  type        = string
  description = "Name of the key vault. This must be globally unique."
}

variable "resource_group_name" {
  type        = string
  description = "Name of secret store resource group"
}

variable "resource_group_location" {
  type        = string
  description = "Location of secret store resource group"
}

variable "sku_name" {
  type        = string
  description = "The SKU of the vault to be created."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be one of the following: standard, premium."
  }
}
