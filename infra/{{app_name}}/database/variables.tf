variable "environment_name" {
  type        = string
  description = "name of the application environment"
}

variable "role_manager_image_tag" {
  type        = string
  description = "docker tag of image you wish to deploy"
  default     = null
}
