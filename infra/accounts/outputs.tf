output "project_name" {
  value = module.project_config.project_name
}

output "subscription_id" {
  value = local.subscription_id
}

output "tf_state_resource_group_name" {
  value = module.backend.tf_state_resource_group_name
}

output "tf_state_storage_account_name" {
  value = module.backend.tf_state_storage_account_name
}

output "tf_state_container_name" {
  value = module.backend.tf_state_storage_container_name
}

output "certs_key_vault_uri" {
  value = module.certificate_store.cert_vault_uri
}

output "github_oidc" {
  value = {
    client_id : module.auth_github_actions.client_id,
    object_id : module.auth_github_actions.object_id
  }
}
