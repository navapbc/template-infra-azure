terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm, azurerm.domain]
    }
  }
}

locals {
  secrets = { for item in var.secrets : item.name => item }

  # The jobs child module only needs the name and versioned id of each secret.
  job_secrets = [for item in var.secrets : { name = item.name, id = item.id }]

  base_environment_variables = [
    { name : "PORT", value : tostring(var.container_port) },
    { name : "IMAGE_TAG", value : var.image_tag },
    { name : "AZURE_CLIENT_ID", value : azurerm_user_assigned_identity.app.client_id },
  ]
  db_environment_variables = var.db_vars == null ? [] : [
    { name : "DB_HOST", value : var.db_vars.connection_info.host },
    { name : "DB_PORT", value : var.db_vars.connection_info.port },
    { name : "DB_USER", value : var.db_vars.connection_info.user },
    { name : "DB_NAME", value : var.db_vars.connection_info.db_name },
    { name : "DB_SCHEMA", value : var.db_vars.connection_info.schema_name },
  ]
  storage_environment_variables = var.storage_vars == null ? [] : [
    { name : "AZURE_STORAGE_ACCOUNT_NAME", value : var.storage_vars.storage_account_name },
    { name : "AZURE_STORAGE_CONTAINER_NAME", value : var.storage_vars.container_name },
  ]
  environment_variables = concat(
    local.base_environment_variables,
    local.db_environment_variables,
    local.storage_environment_variables,
    [
      for name, value in var.extra_environment_variables :
      { name : name, value : value }
    ],
  )
}

data "azurerm_container_app_environment" "env" {
  name                = var.subnet_name
  resource_group_name = var.network_resource_group_name
}

# Note: You might have to rerun after this user gets provisioned for the first
# time. There can be a delay before the permissions are propagated.
resource "azurerm_user_assigned_identity" "app" {
  location            = var.resource_group_location
  name                = "${var.service_name}-app"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "terraform_data" "waiter" {
  input = try(length(var.dependencies), 0) > 0 ? var.dependencies : ["skip"]
}

resource "azurerm_container_app" "service" {
  name                         = var.service_name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  # Other roles are also required, but that list may be dynamic/would require
  # more work to track super accurately, so just reference the roles/assignments
  # that are readily accessible, which generally gets things delayed/ordered
  # correctly. If you happen to encounter deploy errors around roles not
  # existing, should be able to just retry the deploy.
  depends_on = [
    azurerm_role_assignment.app_cr,
    azurerm_role_assignment.app_secrets,
    terraform_data.waiter
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server   = var.image_registry_url
    identity = azurerm_user_assigned_identity.app.id
  }

  // Secrets are loaded then referenced by env blocks
  dynamic "secret" {
    for_each = local.secrets

    content {
      identity            = azurerm_user_assigned_identity.app.id
      name                = replace(lower(secret.value["name"]), "_", "-")
      key_vault_secret_id = secret.value["id"]
    }
  }

  template {
    container {
      name   = var.service_name
      image  = "${var.image_repository_url}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = local.environment_variables
        content {
          name        = env.value["name"]
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret_name", null)
        }
      }

      dynamic "env" {
        for_each = local.secrets
        content {
          name        = env.value["name"]
          secret_name = replace(lower(env.value["name"]), "_", "-")
        }
      }
    }

    # Scaling behavior, for more see
    #
    #   https://learn.microsoft.com/en-us/azure/container-apps/scale-app
    min_replicas = var.desired_instance_count

    # Default is 10, max is 1000
    # max_replicas = 10

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 10
    }
  }

  ingress {
    # by default this is `false`, which means HTTP requests to port 80 are
    # redirected to HTTPS on port 443, if you need to allow plain HTTP you can
    # uncomment here
    #
    # allow_insecure_connections = true
    external_enabled = true
    target_port      = var.container_port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "migrator" {
  location            = var.resource_group_location
  name                = "${var.service_name}-migrator"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# The migration job. This is the manually triggered job that has always been
# created by default, now expressed through the shared `jobs` child module so
# that it and the configurable jobs below stay consistent.
module "migrator_job" {
  source = "./jobs"

  job_name       = "${var.service_name}-job"
  container_name = var.service_name

  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  resource_group_location      = var.resource_group_location

  identity_id        = azurerm_user_assigned_identity.migrator.id
  image_registry_url = var.image_registry_url
  image_url          = "${var.image_repository_url}:${var.image_tag}"

  cpu    = coalesce(var.job_cpu, var.cpu)
  memory = coalesce(var.job_memory, var.memory)

  environment_variables = local.environment_variables
  secrets               = local.job_secrets

  trigger = {
    type = "manual"
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.migrator_cr,
    azurerm_role_assignment.migrator_secrets
  ]
}

# Configurable background jobs. Each job runs the same image and configuration
# as the service, differing only in its command and its trigger.
#
# See /docs/infra/background-jobs.md
module "jobs" {
  for_each = var.jobs

  source = "./jobs"

  job_name       = "${var.service_name}-${each.key}"
  container_name = var.service_name

  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  resource_group_location      = var.resource_group_location

  identity_id        = azurerm_user_assigned_identity.app.id
  image_registry_url = var.image_registry_url
  image_url          = "${var.image_repository_url}:${var.image_tag}"

  command = each.value.command
  args    = each.value.args

  cpu    = coalesce(each.value.cpu, var.job_cpu, var.cpu)
  memory = coalesce(each.value.memory, var.job_memory, var.memory)

  replica_timeout_in_seconds = each.value.replica_timeout_in_seconds
  replica_retry_limit        = each.value.replica_retry_limit

  environment_variables = local.environment_variables
  secrets               = local.job_secrets

  # Event triggered jobs read from a queue that this module creates on the
  # service's storage account, so the queue's identity is filled in here
  # rather than by the caller.
  trigger = each.value.trigger.type == "event" ? merge(each.value.trigger, {
    storage_account_name = var.storage_vars.storage_account_name
    queue_name           = azurerm_storage_queue.file_upload_jobs[each.key].name
  }) : each.value.trigger

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.app_cr,
    azurerm_role_assignment.app_secrets
  ]
}
