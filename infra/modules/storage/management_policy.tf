# Azure Storage Management Policy for lifecycle management
# Note: Unlike AWS S3, Azure automatically cleans up uncommitted blocks after 7 days.
# This policy handles versioning cleanup and blob lifecycle management.

resource "azurerm_storage_management_policy" "storage" {
  storage_account_id = azurerm_storage_account.storage.id

  # Delete old blob versions after 30 days
  # This helps manage storage costs when versioning is enabled
  rule {
    name    = "DeleteOldVersions"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = 30
      }
    }
  }

  # Delete old snapshots after 30 days
  rule {
    name    = "DeleteOldSnapshots"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }
}
