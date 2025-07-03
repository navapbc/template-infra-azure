variable "name" {
  type        = string
  description = "Name of github actions application registration"
}

variable "code_repository" {
  type = string
}

variable "tf_state_storage_container_scope" {
  type = string
}

variable "resource_owners" {
  type = list(string)
}
