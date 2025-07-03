output "client_id" {
  value = azuread_application_registration.github_actions.client_id
}

output "object_id" {
  value = azuread_service_principal.github_actions.object_id
}
