# The migration job used to be defined inline in this module. It is now
# created through the shared `jobs` child module so that it and the
# configurable background jobs stay consistent.
#
# This `moved` block tells Terraform the resource was relocated in the
# configuration rather than replaced, so existing projects keep their job
# instead of destroying and recreating it.
moved {
  from = azurerm_container_app_job.service_job
  to   = module.migrator_job.azurerm_container_app_job.job
}
