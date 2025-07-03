output "container_registry_name" {
  # image registry name must be globally unique, only allows alpha numeric
  # characters, and must be between 5 and 50 characters
  value = substr(replace("${var.project_config.project_name}-${var.project_config.project_unique_id}", "/[^a-zA-Z0-9]/", ""), 0, 50)
}

output "container_registry_resource_group_name" {
  value = var.project_config.project_name
}
