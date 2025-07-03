variable "hosted_zone" {
  type        = string
  description = "Fully qualified domain name for the hosted zone"
}

variable "domain_name" {
  type        = string
  description = "Fully qualified domain name"
}

variable "cert_name" {
  type        = string
  description = "Name of Key Vault entry containing certificate to use for configured domain"
}

variable "resource_group_name" {
  type        = string
  description = "name of resource group"
  default     = null
}

variable "shared_hosted_zone" {
  type    = string
  default = null
}

variable "cert_vault_id" {
  type = string
}
