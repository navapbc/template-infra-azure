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

variable "has_blob_storage" {
  type    = bool
  default = false
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

variable "service_job_cpu" {
  description = "Number of cpu units allocated to background job containers. Defaults to the service's cpu setting when unset."
  type        = number
  default     = null
}

variable "service_job_memory" {
  description = "Amount of memory allocated to background job containers. Defaults to the service's memory setting when unset."
  type        = string
  default     = null
}

variable "service_application_gateway_sku_name" {
  type    = string
  default = "Basic"

  validation {
    condition     = contains(["Basic", "Standard_v2", "WAF_v2"], var.service_application_gateway_sku_name)
    error_message = "Valid values Application Gateway SKU: Basic, Standard_v2, WAF_v2"
  }
}

variable "service_override_extra_environment_variables" {
  type        = map(string)
  description = <<EOT
    Map that overrides the default extra environment variables defined in environment-variables.tf.
    Map from environment variable name to environment variable value
  EOT
  default     = {}
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
