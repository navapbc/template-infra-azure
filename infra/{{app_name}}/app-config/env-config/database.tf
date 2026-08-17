locals {
  database_config = var.has_database ? {
    # TODO: this is supposed to be globally (across Azure) unique, should we
    # additionally prefix with project_config.owner?
    cluster_name        = "${var.project_name}-${local.service_name}"
    resource_group_name = "${local.service_name}-db"
  } : null
}
