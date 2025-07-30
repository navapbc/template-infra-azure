locals {
  service_config = {
    service_name           = "${var.app_name}-${var.environment}"
    cpu                    = var.service_cpu
    memory                 = var.service_memory
    desired_instance_count = var.service_desired_instance_count

    application_gateway_sku_name = var.service_application_gateway_sku_name

    extra_environment_variables = merge(
      local.default_extra_environment_variables,
      # var.service_override_extra_environment_variables
    )

    secrets = local.secrets

    # file_upload_jobs = {
    #   for job_name, job_config in local.file_upload_jobs :
    #   # For job configs that don't define a source_bucket, add the source_bucket config property
    #   job_name => merge({ source_bucket = local.bucket_name }, job_config)
    # }

    # ephemeral_write_volumes = []
  }
}
