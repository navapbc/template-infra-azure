locals {
  # Background jobs that run alongside the service.
  #
  # Each job runs the same container image, environment variables, and secrets
  # as the service, differing only in the command it runs and what triggers it.
  # The map key is the job name.
  #
  # See /docs/infra/background-jobs.md for the full set of options.
  jobs = {
    # Example job that runs on a schedule, using standard five field cron
    # syntax, in UTC.
    #
    # nightly_etl = {
    #   command = ["python", "-m", "etl.nightly"]
    #
    #   trigger = {
    #     type            = "schedule"
    #     cron_expression = "0 3 * * *"
    #   }
    # }

    # Example job that runs when a file is uploaded to the service's blob
    # storage container under the given path prefix. Requires
    # has_blob_storage = true.
    #
    # process_uploads = {
    #   command = ["python", "-m", "etl.process_upload"]
    #
    #   # Jobs can request more CPU and memory than the service itself.
    #   cpu    = 1
    #   memory = "2Gi"
    #
    #   trigger = {
    #     type        = "event"
    #     path_prefix = "uploads/"
    #   }
    # }
  }
}
