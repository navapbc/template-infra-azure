variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  description = "A map of tags for associated resources."
  type        = map(string)
  default     = {}
}
