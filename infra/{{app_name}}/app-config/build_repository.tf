data "external" "account_ids_by_name" {
  program = ["${path.module}/../../../bin/account-ids-by-name"]
}

module "container_registry_interface" {
  source = "../../modules/azure/container-registry/interface"

  project_config = module.project_config
}

locals {
  image_registry_name = module.container_registry_interface.container_registry_name
  # TODO: account for domain name label (DNL) scope if ever enabled
  image_registry_url = "${local.image_registry_name}.azurecr.io"

  image_registry_resource_group_name = module.container_registry_interface.container_registry_resource_group_name

  # TODO: maybe better as "${module.project_config.code_repository}/${local.app_name}"?
  image_repository_name                 = "${module.project_config.owner}/${local.app_name}"
  db_role_manager_image_repository_name = local.has_database ? "${module.project_config.owner}/db-role-manager" : null

  image_repository_region       = module.project_config.default_region
  image_repository_account_name = module.project_config.shared_account_name
  image_repository_account_id   = data.external.account_ids_by_name.result[local.image_repository_account_name]

  build_repository_config = {
    region       = local.image_repository_region
    account_name = local.image_repository_account_name
    account_id   = local.image_repository_account_id

    registry_name = local.image_registry_name
    registry_url  = local.image_registry_url
    registry_id   = "/subscriptions/${local.image_repository_account_id}/resourceGroups/${local.image_registry_resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${local.image_registry_name}"

    name           = local.image_repository_name
    repository_url = "${local.image_registry_url}/${local.image_repository_name}"

    db_role_manager_name           = local.db_role_manager_image_repository_name
    db_role_manager_repository_url = "${local.image_registry_url}/${local.db_role_manager_image_repository_name}"
  }
}
