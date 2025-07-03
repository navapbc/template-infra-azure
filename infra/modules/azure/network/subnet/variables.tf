variable "subnet_config" {
  description = "Subnet configuration object"
}

variable "name" {
  type        = string
  description = "Subnet name"
}

variable "vnet_name" {
  type        = string
  description = "Vnet Name"
}

variable "resource_group_name" {
  type        = string
  description = "Network resource group name"
}

variable "nat_gateway_id" {
  type        = string
  description = "NAT Gateway ID"
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_resource_id" {
  type = string
}

variable "application_gateway_subnet_name" {
  type = string
}
