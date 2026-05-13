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
  description = "Name of the blob container created inside the storage account."
  default     = "documents"
}

variable "monitor_config" {
  description = "Diagnostic-settings configuration for sending storage account logs/metrics to a Log Analytics workspace. Azure-specific."
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = string
  })
}

variable "principals_with_access" {
  description = <<-EOT
    List of principals that should have Storage Blob Data Contributor access to this storage account.
    Each principal can optionally include ABAC conditions for fine-grained access control.

    Example:
    ```
    principals_with_access = [
      {
        principal_id = azurerm_user_assigned_identity.app.principal_id
        description  = "App service managed identity"
      },
      {
        principal_id = azurerm_user_assigned_identity.worker.principal_id
        description  = "Background worker managed identity"
        condition    = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'uploads'"
        condition_version = "2.0"
      }
    ]
    ```
  EOT
  type = list(object({
    principal_id      = string
    description       = optional(string, "Storage Blob Data Contributor access")
    condition         = optional(string, null)
    condition_version = optional(string, null)
  }))
  default = []
  validation {
    condition = alltrue([
      for p in var.principals_with_access :
      (p.condition == null && p.condition_version == null) ||
      (p.condition != null && p.condition_version != null)
    ])
    error_message = "If condition is specified, condition_version must also be specified (and vice versa)."
  }
}
