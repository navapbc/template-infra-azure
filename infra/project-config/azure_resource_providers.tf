# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#resource-provider-registrations
# https://github.com/hashicorp/terraform-provider-azurerm/blob/6814cbdbf8e5a61aad6eb74567ff110b0e1fa174/internal/resourceproviders/required.go
locals {
  azure_resource_providers_autoenable = true

  # TODO: does this comment live here or in some template-only docs?
  # You can get a loose list of providers from existing resources with something like:
  #
  #   az resource list | jq -r '.[].type' | sed "s|/.*||" | sort | uniq
  #
  azure_resource_providers = [
    # These are for Azure Resource Manageer itself and registered by default in a Subscription
    # TODO: should we include these? can we (does attempting to register even work)?
    # "Microsoft.Authorization",
    # "Microsoft.Resources",

    # Azure Container Apps
    "Microsoft.App",

    # Azure Container Registry
    "Microsoft.ContainerRegistry",

    # Azure Database for PostgreSQL
    "Microsoft.DBforPostgreSQL",

    # Azure Monitor - data collection rules and endpoints
    "microsoft.insights",

    # Azure Key Vault - vaults for storing application secrets and TLS certificates
    "Microsoft.KeyVault",

    # Managed identities for Azure resources - User Assigned Identities
    "Microsoft.ManagedIdentity",

    # Networking items - Application Gateway, NAT Gateway, Azure DNS, Public IP Address, Virtual Network, Private Endpoint, Network Watcher, Network Security Group, Load Balancer
    "Microsoft.Network",

    # Azure Monitor - workspaces
    "Microsoft.OperationalInsights",

    // Storage accounts - for Terraform state and various data needs
    "Microsoft.Storage",
  ]
}
