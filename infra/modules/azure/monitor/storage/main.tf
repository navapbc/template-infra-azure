terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  target_resource_info = provider::azurerm::parse_resource_id(var.target_resource_id)
  name                 = var.name != null ? var.name : substr("diag-${local.target_resource_info["resource_name"]}", 0, 260)
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  for_each = toset(var.enable ? ["account", "blob", "queue", "table", "file"] : [])

  name                       = local.name
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
