variable "name" {
  description = "name of the database cluster. Note that this is not the name of the Postgres database itself, but the name of the cluster in Azure. It must be unique across the entire Azure service, not just within the resource group."
  type        = string
  validation {
    condition     = can(regex("^[-_\\da-z]+$", var.name))
    error_message = "use only lower case letters, numbers, dashes, and underscores"
  }
}

variable "location" {
  type        = string
  description = "Database Server Location"
  default     = "West US 2"
}

variable "subnet_id" {
  description = "ID of DB subnet"
}

variable "role_manager_subnet_name" {
  description = "Name of subnet for Role Manager"
}

variable "network_resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "dns_zone_id" {
  description = "ID of DB DNS zone"
}

variable "storage_mb" {
  description = "Value of maximum storage on DB. 32768 is the default and lowest value."
  default     = 32768
  validation {
    condition     = contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408], var.storage_mb)
    error_message = "Valid values for storage_mb are: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, or 33553408."
  }
}

variable "flex_sku_name" {
  default = "GP_Standard_D4ds_v4"
}

variable "resource_group_name" {
  type = string
}

variable "role_manager_image_registry_id" {
  type        = string
  description = "Resource ID of the image registry."
}

variable "role_manager_image_registry_url" {
  type        = string
  description = "URL of the image registry."
}

variable "role_manager_image_repository_url" {
  type        = string
  description = "URL of image repository, e.g. my.registry.com/navapbc/my-cool-app"
}

variable "role_manager_image_tag" {
  type        = string
  description = "docker tag of image you wish to deploy"
}

variable "server_parameters" {
  type        = map(string)
  description = "Additional DB server parameters. Map from parameter name to the value. Pass in `null` to disable the module's default parameters."
  default     = {}
}

variable "resource_owners" {
  type = list(string)
}
