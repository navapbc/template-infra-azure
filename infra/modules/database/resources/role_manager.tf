locals {
  role_manager_name = "${var.resource_group_name}-role-manager"
}

data "azurerm_container_app_environment" "env" {
  name                = var.role_manager_subnet_name
  resource_group_name = var.network_resource_group_name
}

resource "azurerm_user_assigned_identity" "db_role_manager" {
  name                = "${local.role_manager_name}-uai"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "db_role_manager" {
  scope                = var.role_manager_image_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.db_role_manager.principal_id
  depends_on = [
    azurerm_user_assigned_identity.db_role_manager
  ]
}

resource "azuread_group_member" "db_role_manager_admin" {
  group_object_id  = azuread_group.db_admin.object_id
  member_object_id = azurerm_user_assigned_identity.db_role_manager.principal_id
}

resource "azuread_group_member" "db_role_manager_app" {
  group_object_id  = azuread_group.db_app.object_id
  member_object_id = azurerm_user_assigned_identity.db_role_manager.principal_id
}

resource "azuread_group_member" "db_role_manager_migrator" {
  group_object_id  = azuread_group.db_migrator.object_id
  member_object_id = azurerm_user_assigned_identity.db_role_manager.principal_id
}

resource "azurerm_container_app_job" "db_role_manager" {
  name                         = "${local.role_manager_name}-job"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  workload_profile_name        = "Consumption"

  depends_on = [
    azurerm_role_assignment.db_role_manager
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.db_role_manager.id]
  }

  registry {
    server   = var.role_manager_image_registry_url
    identity = azurerm_user_assigned_identity.db_role_manager.id
  }

  replica_timeout_in_seconds = 3600
  replica_retry_limit        = 0
  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name  = "db-role-manager"
      image = "${var.role_manager_image_repository_url}:${var.role_manager_image_tag}"

      cpu    = 0.5
      memory = "1Gi"

      # https://github.com/Azure/azure-sdk-for-python/tree/09eeca7a37485f58e14ad297d2686c0a01fd688e/sdk/identity/azure-identity#specify-a-user-assigned-managed-identity-with-defaultazurecredential
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.db_role_manager.client_id
      }

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.db.fqdn
      }

      env {
        name  = "DB_PORT"
        value = 5432
      }

      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.db.name
      }

      env {
        name  = "DB_SCHEMA"
        value = module.interface.schema_name
      }

      env {
        name  = "APP_USER"
        value = azuread_group.db_app.display_name
      }

      env {
        name  = "MIGRATOR_USER"
        value = azuread_group.db_migrator.display_name
      }

      env {
        name  = "ADMIN_USER"
        value = azuread_group.db_admin.display_name
      }
    }
  }
}
