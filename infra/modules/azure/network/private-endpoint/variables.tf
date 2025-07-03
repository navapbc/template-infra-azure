variable "enable" {
  type    = bool
  default = true
}

variable "dns_zone_key" {
  type    = string
  default = null
}

variable "subnet_id" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "resource_name" {
  type    = string
  default = null
}

variable "resource_location" {
  type    = string
  default = null
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "subresource_names" {
  type    = list(string)
  default = null
}
