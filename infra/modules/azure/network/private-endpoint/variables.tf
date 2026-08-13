variable "enable" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type = string

  validation {
    condition = var.enable ? var.subnet_id != null && var.subnet_id != "" : true

    error_message = "A 'subnet_id' must be provided when 'enable' is set to true."
  }
}

variable "resource_id" {
  type = string

  validation {
    condition = var.enable ? var.resource_id != null && var.resource_id != "" : true

    error_message = "A 'resource_id' must be provided when 'enable' is set to true."
  }
}

variable "subresource_names" {
  type    = list(string)
  default = null
}

variable "dns_zone_key" {
  type    = string
  default = null
}

variable "name" {
  type        = string
  default     = null
  description = "Name for the Private Endpoint resource. If not specified, will use the name of the targeted resource."
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "Resource Group for the Private Endpoint resource. If not specified, will use the resource group of the subnet."
}
