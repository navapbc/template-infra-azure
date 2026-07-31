variable "enable" {
  type    = bool
  default = true
}

variable "name" {
  type    = string
  default = null
}

variable "target_resource_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}
