variable "project_config" {
  type = object({
    project_unique_id = string
    default_region    = string
    project_name      = string
  })
}
