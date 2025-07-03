output "migrator_username" {
  value = module.app_config.has_database ? module.database[0].migrator_username : null
}

output "migrator_user_client_id" {
  value = module.service.migrator_user_client_id
}

output "service_resource_group" {
  value = local.resource_group_name
}

output "service_job_name" {
  value = module.service.service_job_name
}

output "service_endpoint" {
  description = "The public endpoint for the service."
  value       = module.service.public_endpoint
}
