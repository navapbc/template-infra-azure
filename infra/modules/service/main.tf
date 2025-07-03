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
  environment_variables = concat(
    local.base_environment_variables,
    local.db_environment_variables,
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
}

resource "azurerm_container_app" "service" {
  name                         = var.service_name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  # TODO: do we need this? probably for first deploy. how to handle the dynamic
  # "azure_role_assignment" resources properly?
  depends_on = [azurerm_role_assignment.app_cr]

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
}

resource "azurerm_user_assigned_identity" "migrator" {
  location            = var.resource_group_location
  name                = "${var.service_name}-migrator"
  resource_group_name = var.resource_group_name
}

resource "azurerm_container_app_job" "service_job" {
  name                         = "${var.service_name}-job"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  workload_profile_name        = "Consumption"

  depends_on = [azurerm_role_assignment.migrator_cr]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.migrator.id]
  }

  registry {
    server   = var.image_registry_url
    identity = azurerm_user_assigned_identity.migrator.id
  }

  // Secrets are loaded then referenced by env blocks
  dynamic "secret" {
    for_each = local.secrets

    content {
      identity            = azurerm_user_assigned_identity.migrator.id
      name                = replace(lower(secret.value["name"]), "_", "-")
      key_vault_secret_id = secret.value["id"]
    }
  }

  replica_timeout_in_seconds = 3600
  replica_retry_limit        = 0
  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name  = var.service_name
      image = "${var.image_repository_url}:${var.image_tag}"
      # TODO: or should this be configured separately
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
  }
}
