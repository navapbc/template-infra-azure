variable "name" {
  type        = string
  description = "The name of the database cluster"
}


variable "resource_group_name" {
  type = string
}

variable "is_temporary" {
  description = "Whether the service is meant to be spun up temporarily (e.g. for automated infra tests). This is used to disable deletion protection."
  type        = bool
  default     = false
}
