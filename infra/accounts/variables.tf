# Used to lookup the correct Subscription ID to use via the names of the
# tfbackend files, as well as other lookups and naming resources
variable "account_name" {
  type     = string
  nullable = false
}

# Generally var.account_id should only be set on initial creation, as the
# account name -> account ID map hasn't been established yet via a tfbackend
# file for the new account
variable "account_id" {
  type    = string
  default = null
}

# TODO: support these long-term?
variable "tf_state_resource_group_name_override" {
  type    = string
  default = null
}

variable "tf_state_storage_account_name_override" {
  type    = string
  default = null
}

variable "tf_state_use_customer_managed_encryption_key" {
  type    = bool
  default = true
}
