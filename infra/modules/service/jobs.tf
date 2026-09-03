# Event triggered ("file upload") jobs.
#
# Azure Container App Jobs have no direct blob-event trigger. Instead, blob
# events are routed through Event Grid onto a storage queue, and the job scales
# on that queue's depth using a KEDA azure-queue scaler. Each event triggered
# job gets its own queue so that jobs are isolated from one another and each
# can filter for a different path prefix.
#
#   blob upload -> Event Grid system topic -> storage queue -> KEDA -> job
#
# Unlike the AWS template, the triggering blob's path is not substituted into
# the job's command. The job reads the queue itself and receives the full
# Event Grid event, which contains the blob URL. See
# /docs/infra/background-jobs.md.

locals {
  file_upload_jobs = {
    for name, job in var.jobs : name => job
    if job.trigger.type == "event"
  }
}

# Event triggered jobs subscribe to blob events, so they require the
# application to have blob storage enabled. Checked here rather than in a
# variable validation block because it spans two variables.
check "file_upload_jobs_require_storage" {
  assert {
    condition     = length(local.file_upload_jobs) == 0 || var.storage_vars != null
    error_message = "Jobs with trigger.type \"event\" require blob storage. Set has_blob_storage = true in the app-config module."
  }
}

resource "azurerm_storage_queue" "file_upload_jobs" {
  for_each = local.file_upload_jobs

  name               = "${each.key}-events"
  storage_account_id = var.storage_vars.storage_account_id
}

resource "azurerm_eventgrid_system_topic_event_subscription" "file_upload_jobs" {
  for_each = local.file_upload_jobs

  name                = "${var.service_name}-${each.key}"
  system_topic        = var.storage_vars.eventgrid_system_topic_name
  resource_group_name = var.storage_vars.resource_group_name

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  storage_queue_endpoint {
    storage_account_id = var.storage_vars.storage_account_id
    queue_name         = azurerm_storage_queue.file_upload_jobs[each.key].name
  }

  # Event Grid subjects for blob events are of the form
  # /blobServices/default/containers/<container>/blobs/<path>, so the path
  # prefix filter is anchored to the service's container.
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.storage_vars.container_name}/blobs/${each.value.trigger.path_prefix}"
  }

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
}

# The job's identity needs to read and delete messages from the queue it is
# scaling on. `Storage Queue Data Contributor` covers both, plus the peek
# permission KEDA uses to measure queue depth.
resource "azurerm_role_assignment" "app_queue" {
  count = length(local.file_upload_jobs) > 0 ? 1 : 0

  scope                = var.storage_vars.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  skip_service_principal_aad_check = var.is_temporary
}
