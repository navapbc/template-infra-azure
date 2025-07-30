variable "project_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "environment" {
  description = "name of the application environment (e.g. dev, staging, prod)"
  type        = string
}

variable "has_database" {
  type = bool
}

variable "service_cpu" {
  type    = number
  default = 0.25
}

variable "service_memory" {
  type    = string
  default = "0.5Gi"
}

variable "service_desired_instance_count" {
  type    = number
  default = 0
}

variable "service_application_gateway_sku_name" {
  type    = string
  default = "Basic"

  validation {
    condition     = contains(["Basic", "Standard_v2", "WAF_v2"], var.service_application_gateway_sku_name)
    error_message = "Valid values Application Gateway SKU: Basic, Standard_v2, WAF_v2"
  }
}

variable "network_name" {
  description = "Human readable identifier of the network / VPC"
  type        = string
}

variable "domain_name" {
  type        = string
  description = "The subdomain on the configured hosted zone for the environment or fully qualified domain name for the application"
  default     = null
}

variable "cert_name" {
  type        = string
  description = "Name of Key Vault entry containing certificate to use for configured domain"
  default     = null
}
