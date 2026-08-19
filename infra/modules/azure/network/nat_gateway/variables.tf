variable "vnet_name" {
  type        = string
  description = "Vnet Name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "NAT Gateway Location"
}

variable "tags" {
  description = "A map of tags for associated resources."
  type        = map(string)
  default     = {}
}
