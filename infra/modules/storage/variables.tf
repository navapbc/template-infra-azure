variable "storage_account_name" {
  type        = string
  description = "Name of the storage account. Must be globally unique, 3-24 characters, lowercase alphanumeric only."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group."
}

variable "container_name" {
  type        = string
  description = "Name of the blob container."
  default     = "documents"
}

variable "monitor_config" {
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = string
  })
}
