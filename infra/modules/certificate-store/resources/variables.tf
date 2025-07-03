variable "project_config" {
  type = object({
    project_unique_id = string
    default_region    = string
    project_name      = string
  })
}

variable "account_name" {
  type = string
}

variable "monitor_config" {
  type = object({
    enabled                    = bool
    log_analytics_workspace_id = string
  })
}
