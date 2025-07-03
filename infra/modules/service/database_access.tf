#-----------------
# Database Access
#-----------------

resource "time_sleep" "wait_for_uai_propagation" {
  create_duration  = "30s"
  destroy_duration = "0s"

  triggers = {
    app      = azurerm_user_assigned_identity.app.principal_id
    migrator = azurerm_user_assigned_identity.migrator.principal_id
  }
}

resource "azuread_group_member" "db_migrator" {
  count = var.db_vars != null ? 1 : 0

  group_object_id  = var.db_vars.migrator_group_object_id
  member_object_id = azurerm_user_assigned_identity.migrator.principal_id

  depends_on = [
    time_sleep.wait_for_uai_propagation,
  ]
}

resource "azuread_group_member" "db_app" {
  count = var.db_vars != null ? 1 : 0

  group_object_id  = var.db_vars.app_group_object_id
  member_object_id = azurerm_user_assigned_identity.app.principal_id

  depends_on = [
    time_sleep.wait_for_uai_propagation,
  ]
}
