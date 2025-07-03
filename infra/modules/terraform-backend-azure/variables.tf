variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_container_name" {
  type    = string
  default = "backends"
}

variable "monitor_config" {
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = string
  })
}

variable "use_customer_managed_encryption_key" {
  type    = bool
  default = false
}
