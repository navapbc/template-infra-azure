variable "project_name" {
  type        = string
  description = "name of project"
}

variable "network_name" {
  type        = string
  description = "name of network"
}

variable "network_config" {
  description = "network configuration object"
}

variable "has_database" {
  type        = bool
  description = "does the network need a database"
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_resource_id" {
  type = string
}

variable "log_analytics_workspace_workspace_id" {
  type = string
}

variable "log_analytics_workspace_location" {
  type = string
}

variable "container_registry_id" {
  type = string
}

variable "container_registry_name" {
  type = string
}
