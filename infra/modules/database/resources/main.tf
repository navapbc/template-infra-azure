data "azurerm_subscription" "current" {
}

locals {
  enable_high_availability = !startswith(var.flex_sku_name, "B")

  server_config_params_default = {
    "log_statement"              = "ddl" # Log data definition statements (e.g. DROP, ALTER, CREATE)
    "log_min_duration_statement" = "100" # Log all statements that run 100ms or longer
  }
  server_config_params = var.server_parameters == null ? {} : merge(local.server_config_params_default, var.server_parameters)
}

module "interface" {
  source              = "../interface"
  name                = var.name
  resource_group_name = var.resource_group_name
}

resource "azuread_group" "db_admin" {
  display_name     = "${var.resource_group_name}-admin"
  description      = "Entities that can connect as administrators to ${var.name} DB server"
  security_enabled = true

  # TODO: see db_app comment
  # assignable_to_role = true

  prevent_duplicate_names = true

  owners = var.resource_owners
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "db_admin_group" {
  server_name         = azurerm_postgresql_flexible_server.db.name
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_subscription.current.tenant_id
  object_id           = azuread_group.db_admin.object_id
  principal_name      = azuread_group.db_admin.display_name
  principal_type      = "Group"
}

resource "azurerm_postgresql_flexible_server" "db" {
  # the name must be unique across the entire Azure service, not just within the resource group
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "16"
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.dns_zone_id
  zone                          = "1"
  geo_redundant_backup_enabled  = true
  public_network_access_enabled = false

  storage_mb = var.storage_mb
  # TODO: decide if we want to enable this by default or leave as configuration
  # for projects to choose
  #
  # Currently the terraform resource always provisions a `Premium SSD` storage type.
  #
  # > Azure Database for PostgreSQL flexible server only supports the storage
  # > autogrow feature on storage type Premium SSD. Storage always doubles in size
  # > for premium disk SSD, and that doubles the storage cost. Only premium SSD V2
  # > supports more granular disk size increase.
  #
  # From https://github.com/MicrosoftDocs/azure-databases-docs/blob/e93f7c80bbb4e7be21d406caaac1d7f5e5951715/articles/postgresql/flexible-server/how-to-auto-grow-storage.md
  #
  # Support to configure `Premium SSD v2` should be coming in May 2025 per
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/24294
  #
  # auto_grow_enabled = true

  sku_name = var.flex_sku_name

  authentication {
    # If you want/need to enable password auth for alternative access, do the
    # first deploy with password_auth_enabled=false so later created databases
    # are owned by the Entra admin and not the password admin, as the Entra
    # admin is what the role manager expects to be able to use to manage the
    # database. After the initial server creation, you can enable password auth.
    #
    # https://github.com/hashicorp/terraform-provider-azurerm/issues/27895#issuecomment-2462169310
    password_auth_enabled         = false
    active_directory_auth_enabled = true
    tenant_id                     = data.azurerm_subscription.current.tenant_id
  }

  dynamic "high_availability" {
    for_each = local.enable_high_availability ? [true] : []

    content {
      mode = "ZoneRedundant"
      # Can specify the particular zone if desired.
      # standby_availability_zone =
    }
  }

  # checkov:skip=CKV2_AZURE_57:Server is using Private Access/VNet integration mode, instead of explicit private endpoint
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = module.interface.db_name
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # make sure the admin is created before the database, so we don't get locked out
  depends_on = [azurerm_postgresql_flexible_server_active_directory_administrator.db_admin_group]
}

resource "azurerm_postgresql_flexible_server_configuration" "param" {
  for_each = local.server_config_params

  name  = each.key
  value = each.value

  server_id = azurerm_postgresql_flexible_server.db.id
}

resource "azuread_group" "db_migrator" {
  display_name     = module.interface.migrator_username
  description      = "Entities that can connect as migrators to ${var.name} DB server"
  security_enabled = true

  # TODO: see db_app comment
  #
  # assignable_to_role = true

  # by default group names are not enforced to be unique, but we do some lookups
  # based on the name, so prevent getting the wrong result there
  prevent_duplicate_names = true

  owners = var.resource_owners
}

resource "azuread_group" "db_app" {
  display_name     = module.interface.app_username
  description      = "Entities that can connect as Applications to ${var.name} DB server"
  security_enabled = true

  # TODO: probably want this theoretically? But requires more Entra permissions
  #
  # Users will need Entra role: Groups Administrator, User Administrator or Global Administrator
  #
  # Service principals (e.g. GitHub) would need API permission: RoleManagement.ReadWrite.Directory
  # assignable_to_role = true

  # by default group names are not enforced to be unique, but we do some lookups
  # based on the name, so prevent getting the wrong result there
  prevent_duplicate_names = true

  owners = var.resource_owners
}
