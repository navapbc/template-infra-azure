output "account_name" {
  value = local.network_config.account_name
}

output "database_config" {
  value = local.database_config
}

output "domain_config" {
  value = local.domain_config
}

output "network_name" {
  value = var.network_name
}

output "service_config" {
  value = local.service_config
}

output "use_application_gateway" {
  value = try(local.network_config.network.application_gateway_subnet_name != null, false)
}
