variable "manage_dns" {
  type        = bool
  description = "Whether DNS is managed by the project (true) or managed externally (false)"
}

variable "create_dns_zone" {
  type        = bool
  description = "Whether this module should create the hosted zone"
}

variable "name" {
  type        = string
  description = "DNS hosted zone"
}

variable "resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "certificate_configs" {
  type = map(object({
    source = string
  }))
  description = <<EOT
    Map from domains to certificate configuration objects for that domain.

    For each domain's certificate:
    `source` indicates whether the certificate is managed by the project
    (issued) or imported from an external source (imported)
  EOT

  validation {
    condition = alltrue([
      for certificate_config in var.certificate_configs :
      contains(["issued", "imported"], certificate_config.source)
    ])
    error_message = "certificate_config.source must be either 'issued' or 'imported'"
  }
}

variable "cert_vault_id" {
  type = string
}

variable "cert_contact_email" {
  type = string
}
