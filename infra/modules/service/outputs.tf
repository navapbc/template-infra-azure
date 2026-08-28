output "service_user_identity_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "migrator_user_client_id" {
  value = azurerm_user_assigned_identity.migrator.client_id
}


output "service_job_name" {
  description = "The name of the manually triggered job used to run database migrations."
  value       = module.migrator_job.job_name
}

output "job_names" {
  description = "Map from configured background job name to the name of its Container App Job."
  value       = { for name, job in module.jobs : name => job.job_name }
}

output "public_endpoint" {
  description = "The public endpoint for the service."
  value       = "https://${local.custom_fqdn != null ? local.custom_fqdn : azurerm_container_app.service.ingress[0].fqdn}"
}
