variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_config" {}

variable "log_analytics_workspace_resource_id" {
  type = string
}

variable "log_analytics_workspace_workspace_id" {
  type = string
}

variable "log_analytics_workspace_location" {
  type = string
}
