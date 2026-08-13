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

resource "azurerm_monitor_diagnostic_setting" "vault" {
  count = var.enable ? 1 : 0

  name                       = local.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "audit" # or "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
