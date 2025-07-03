locals {
  database_config = var.has_database ? {
    region = var.default_region
    # TODO: this is supposed to be globally (across Azure) unique, should we
    # additionally prefix with project_config.owner?
    cluster_name        = "${var.project_name}-${var.app_name}-${var.environment}"
    resource_group_name = "${var.app_name}-${var.environment}-db"
  } : null
}
