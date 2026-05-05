variable "container_port" {
  type        = number
  description = "The port number on the container that's bound to the user-specified"
  default     = 8000
}

variable "image_registry_id" {
  type        = string
  description = "Resource ID of the image registry."
}

variable "image_registry_url" {
  type        = string
  description = "URL of the image registry."
}

variable "image_repository_url" {
  type        = string
  description = "URL of image repository, e.g. my.registry.com/navapbc/my-cool-app"
}

variable "image_tag" {
  type        = string
  description = "docker tag of image you wish to deploy"
}

variable "service_name" {
  type        = string
  description = "name of the application service"
}

variable "resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "resource_group_location" {
  type        = string
  description = "location of resource group"
}

variable "secrets" {
  type = set(object({
    name                    = string
    id                      = string
    resource_versionless_id = string
  }))
  description = "List of configurations for defining environment variables that pull from secret store"
  default     = []
}

variable "db_vars" {
  description = "Variables for integrating the app service with a database"
  type = object({
    migrator_group_object_id = string
    app_group_object_id      = string

    connection_info = object({
      host        = string
      port        = string
      user        = string
      db_name     = string
      schema_name = string
    })
  })
  default = null
}

variable "extra_environment_variables" {
  type        = map(string)
  description = "Additional environment variables to pass to the service container. Map from environment variable name to the value."
  default     = {}
}

variable "subnet_name" {
  type        = string
  description = "Service's subnet name"
}

variable "cpu" {
  type        = number
  default     = 0.25
  description = "Number of cpu units allocated to containers. Limited to 4 with default 'Consumption' workload profile and must be specified with memory in 0.25/0.5Gi increments (e.g., 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi)."
}

variable "memory" {
  type        = string
  default     = "0.5Gi"
  description = "Amount of memory allocated to containers. Limited to 8Gi with default 'Consumption' workload profile and must be specified with CPU in 0.25/0.5Gi increments (e.g., 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi)."
}

# TODO: rename to min_instance_count? It's a little different than AWS.
variable "desired_instance_count" {
  type        = number
  description = "Minimum number of container instances to have running."
  default     = 0
}

variable "domain_name" {
  type        = string
  description = "The fully qualified domain name for the application"
  default     = null
}

variable "domain_hosted_zone_name" {
  type        = string
  description = "The root hosted zone name for the domain"
  default     = null
}

variable "domain_hosted_zone_subscription_id" {
  type        = string
  description = "The Subscription where the hosted zone lives"
  default     = null
}

variable "domain_resource_group_name" {
  type        = string
  description = "The resource group name where the hosted zone resource lives"
  default     = null
}

variable "domain_network_zone_name" {
  type        = string
  description = "The hosted zone name for network"
  default     = null
}

variable "domain_certificate_secret_id" {
  type = string
}

variable "manage_dns" {
  type    = bool
  default = true
}

variable "is_temporary" {
  description = "Whether the service is meant to be spun up temporarily (e.g. for automated infra tests)."
  type        = bool
  default     = false
}

variable "network_resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "application_gateway_subnet_id" {
  type = string
}

variable "application_gateway_sku_name" {
  type = string

  validation {
    condition     = contains(["Basic", "Standard_v2", "WAF_v2"], var.application_gateway_sku_name)
    error_message = "Valid values Application Gateway SKU: Basic, Standard_v2, WAF_v2"
  }
}
