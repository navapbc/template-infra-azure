output "project_name" {
  value = local.project_name
}

output "owner" {
  value = local.owner
}

output "code_repository_url" {
  value = local.code_repository_url
}

output "code_repository" {
  value       = regex("([-_\\w]+/[-_\\w]+)(\\.git)?$", local.code_repository_url)[0]
  description = "The 'org/repo' string of the repo (e.g. 'navapbc/template-infra'). This is extracted from the repo URL (e.g. 'git@github.com:navapbc/template-infra.git' or 'https://github.com/navapbc/template-infra.git')"
}

output "default_region" {
  value = local.default_region
}

output "tenant_id" {
  value = local.tenant_id
}

# Common tags for all accounts and environments
output "default_tags" {
  value = {
    project             = local.project_name
    owner               = local.owner
    repository          = local.code_repository_url
    terraform           = true
    terraform_workspace = terraform.workspace
    # description is set in each environments local use key project_description if required.        
  }
}

# Auth Github Actions output
output "github_actions_azure_config" {
  value = local.github_actions_azure_config
}

output "network_configs" {
  value = local.network_configs
}

output "default_certificate_contact_email" {
  value = local.default_certificate_contact_email
}

output "manage_privatelink_dns" {
  value = local.manage_privatelink_dns
}

output "shared_hosted_zone" {
  value = try(local.shared_hosted_zone, null)
}

output "shared_account_name" {
  value = try(local.shared_account_name, null)
}

output "project_unique_id" {
  value = md5(local.code_repository_url)
}

output "infra_admins" {
  value = local.infra_admins
}
