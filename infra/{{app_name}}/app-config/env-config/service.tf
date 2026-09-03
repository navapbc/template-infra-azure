locals {
  service_name = "${var.app_name}-${var.environment}"

  service_config = {
    service_name           = local.service_name
    resource_group_name    = "${local.service_name}-service"
    cpu                    = var.service_cpu
    memory                 = var.service_memory
    desired_instance_count = var.service_desired_instance_count

    application_gateway_sku_name = var.service_application_gateway_sku_name

    extra_environment_variables = merge(
      local.default_extra_environment_variables,
      var.service_override_extra_environment_variables
    )

    secrets = local.secrets

    jobs = local.jobs

    # Whether any job is triggered by file uploads. Derived once here because
    # both the service module and the storage layer need to know, and the
    # storage layer cannot read it back off the service module without
    # creating a dependency cycle.
    has_file_upload_jobs = contains(
      [for job in values(local.jobs) : job.trigger.type],
      "event",
    )

    job_cpu    = var.service_job_cpu
    job_memory = var.service_job_memory

    # ephemeral_write_volumes = []
  }
}
