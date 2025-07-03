output "app_username" {
  value = "${var.resource_group_name}-app"
}

output "migrator_username" {
  value = "${var.resource_group_name}-migrator"
}

# Putting this here in the interface as a simple place to share the value
# between things, as there is not a programmatic way to retrieve the DB name in
# a data provider, besides parsing the terraform state directly, see:
#
#   https://github.com/hashicorp/terraform-provider-azurerm/issues/22961
#
# This would ideally be a variable to the database/resources module, that we
# then just lookup in database/data.
output "db_name" {
  value = "app"
}

output "schema_name" {
  value = "app"
}
