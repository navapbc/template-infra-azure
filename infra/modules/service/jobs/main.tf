terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  # Key Vault secret names are exposed to the container under a normalized
  # name, since Container Apps secret names must be lowercase and may not
  # contain underscores.
  secrets_by_name = { for secret in var.secrets : secret.name => secret }

  secret_name = { for secret in var.secrets : secret.name => replace(lower(secret.name), "_", "-") }
}

resource "azurerm_container_app_job" "job" {
  name                         = var.job_name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  workload_profile_name        = "Consumption"

  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.image_registry_url
    identity = var.identity_id
  }

  # Secrets are loaded here, then referenced by the env blocks below.
  dynamic "secret" {
    for_each = local.secrets_by_name

    content {
      identity            = var.identity_id
      name                = local.secret_name[secret.key]
      key_vault_secret_id = secret.value.id
    }
  }

  dynamic "manual_trigger_config" {
    for_each = var.trigger.type == "manual" ? [var.trigger] : []

    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  dynamic "schedule_trigger_config" {
    for_each = var.trigger.type == "schedule" ? [var.trigger] : []

    content {
      cron_expression          = schedule_trigger_config.value.cron_expression
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
    }
  }

  # Event triggered jobs scale on queue depth using a KEDA azure-queue scaler.
  # See https://keda.sh/docs/scalers/azure-storage-queue/
  dynamic "event_trigger_config" {
    for_each = var.trigger.type == "event" ? [var.trigger] : []

    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count

      scale {
        min_executions              = event_trigger_config.value.min_executions
        max_executions              = event_trigger_config.value.max_executions
        polling_interval_in_seconds = event_trigger_config.value.polling_interval_in_seconds

        # Authenticate to the queue with the job's user assigned identity
        # rather than a connection string, so that the storage account can
        # keep `shared_access_key_enabled = false`.
        rules {
          name             = "queue-scaler"
          custom_rule_type = "azure-queue"
          identity_id      = var.identity_id

          metadata = {
            accountName = event_trigger_config.value.storage_account_name
            queueName   = event_trigger_config.value.queue_name
            queueLength = tostring(event_trigger_config.value.queue_length)
          }
        }
      }
    }
  }

  template {
    container {
      name   = var.container_name
      image  = var.image_url
      cpu    = var.cpu
      memory = var.memory

      command = var.command
      args    = var.args

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.secrets_by_name
        content {
          name        = env.value.name
          secret_name = local.secret_name[env.key]
        }
      }
    }
  }

  tags = var.tags
}
