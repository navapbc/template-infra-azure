output "job_name" {
  description = "The name of the Container App Job."
  value       = azurerm_container_app_job.job.name
}

output "job_id" {
  description = "The resource ID of the Container App Job."
  value       = azurerm_container_app_job.job.id
}
