output "service_user_identity_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "migrator_user_client_id" {
  value = azurerm_user_assigned_identity.migrator.client_id
}


output "service_job_name" {
  value = azurerm_container_app_job.service_job.name
}

output "public_endpoint" {
  description = "The public endpoint for the service."
  value       = "https://${local.custom_fqdn != null ? local.custom_fqdn : azurerm_container_app.service.ingress[0].fqdn}"
}
