# Make the "role_manager_image_tag" variable optional so that "terraform plan"
# and "terraform apply" work without any required variables.
#
# This works as follows:

#  1. Accept an optional variable during a terraform plan/apply. (see "role_manager_image_tag" variable in variables.tf)

#  2. Read the output used from the last terraform state using "terraform_remote_state".
#     Get the backend config by parsing the backend config file
locals {
  backend_config_file_path = "${path.module}/${var.environment_name}.azurerm.tfbackend"
  backend_config_file      = file("${path.module}/${var.environment_name}.azurerm.tfbackend")

  # Use regex to parse backend config file to get a map of variables to their
  # defined values since there is no built-in terraform function that does that
  #
  # The backend config file consists of lines that look like
  # <variable_name>        = "<variable_value"
  # so our regex is (\w+)\s+= "(.+)"
  # Note that backslashes in the regex need to be escaped in Terraform
  # so they will appear as \\ instead of \
  # (see https://developer.hashicorp.com/terraform/language/functions/regex)
  backend_config_regex         = "(\\w+)\\s+= \"(.+)\""
  backend_config               = { for match in regexall(local.backend_config_regex, local.backend_config_file) : match[0] => match[1] }
  tfstate_resource_group_name  = local.backend_config["resource_group_name"]
  tfstate_storage_account_name = local.backend_config["storage_account_name"]
  tfstate_container_name       = local.backend_config["container_name"]
  tfstate_key                  = local.backend_config["key"]
}
data "terraform_remote_state" "current_role_manager_image_tag" {
  # Don't do a lookup if role_manager_image_tag is provided explicitly.
  # This saves some time and also allows us to do a first deploy,
  # where the tfstate file does not yet exist.
  count   = var.role_manager_image_tag == null ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = local.tfstate_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = local.tfstate_key

    use_azuread_auth = true
  }

  defaults = {
    role_manager_image_tag = null
  }
}

#  3. Prefer the given variable if provided, otherwise default to the value from last time.
locals {
  role_manager_image_tag = (var.role_manager_image_tag == null
    ? data.terraform_remote_state.current_role_manager_image_tag[0].outputs.role_manager_image_tag
  : var.role_manager_image_tag)
}

#  4. Store the final value used as a terraform output for next time.
output "role_manager_image_tag" {
  value = local.role_manager_image_tag
}
