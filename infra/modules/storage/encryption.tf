# Storage account encryption at rest is enabled by default in Azure using
# Microsoft-managed keys (256-bit AES). No additional Terraform configuration
# is required for the baseline guarantee.
#
# For workloads that require customer-managed keys (CMK) — e.g., regulated
# environments — add an azurerm_key_vault_key plus a customer_managed_key
# block on the storage account here. This is parallel to the AWS template's
# encryption.tf, which provisions a KMS key and bucket SSE configuration.
#
# Tracked as a follow-up; see CKV2_AZURE_1 skip in main.tf.
