locals {
  # Azure storage account names must be globally unique across all of Azure,
  # 3-24 characters, lowercase letters and numbers only.
  #
  # Constructed deterministically from project + app + environment (parallels
  # the AWS template's `bucket_name = "${project}-${app}-${environment}"` in
  # env-config/main.tf). A short hash of the same inputs is appended for
  # extra entropy, since Azure storage account names share a single global
  # namespace and short prefixes collide easily.
  storage_account_name = substr(
    "${replace(lower("${var.app_name}${var.environment}"), "/[^a-z0-9]/", "")}st${substr(md5("${var.project_name}-${var.app_name}-${var.environment}"), 0, 8)}",
    0,
    24,
  )

  storage_config = var.has_blob_storage ? {
    account_name   = local.storage_account_name
    container_name = "documents"
  } : null
}
