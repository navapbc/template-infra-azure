resource "azurerm_monitor_diagnostic_setting" "tf_state" {
  for_each = toset(var.enable ? ["account", "blob", "queue", "table", "file"] : [])

  name                       = var.name
  target_resource_id         = each.value == "account" ? var.target_resource_id : "${var.target_resource_id}/${each.value}Services/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = each.value != "account" ? [true] : []

    content {
      category_group = "audit" # or "allLogs"
    }
  }

  enabled_metric {
    category = "Transaction"
  }
}
