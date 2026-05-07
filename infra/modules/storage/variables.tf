variable "is_temporary" {
  description = "Whether the storage account is meant to be spun up temporarily (e.g. for automated infra tests). When true, soft-delete retention is shortened so test teardown is fast."
  type        = bool
  default     = false
}

variable "name" {
  type        = string
  description = "Name of the Azure storage account. Must be globally unique across Azure, 3-24 characters, lowercase alphanumeric only."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group the storage account is created in."
}

variable "resource_group_location" {
  type        = string
  description = "Azure region the storage account is created in."
}

variable "container_name" {
  type        = string
  description = "Name of the blob container created inside the storage account. Azure-specific: AWS S3 has no equivalent — buckets are flat namespaces."
  default     = "documents"
}

variable "monitor_config" {
  description = "Diagnostic-settings configuration for sending storage account logs/metrics to a Log Analytics workspace. Azure-specific."
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = string
  })
}
