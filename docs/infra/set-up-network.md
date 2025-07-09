# Set up network

The network setup process will configure and deploy network resources needed by
other modules. In particular, it will:

1. Create a Virtual Network
1. Create public subnets for publicly accessible resources such as the
   application load balancer, private subnets for the application service, and
   private subnets for the database.
1. Create private DNS zones for later use by private endpoints for the Azure
   services needed by the application (such as the container registry).
1. Create a Container App Environment for use by all apps in the network.

## Requirements

Before setting up the network you'll need to have:

1. [Set up the Azure account](./set-up-azure-account.md).
1. [Set up your custom domain(s)](/docs/infra/set-up-custom-domains.md).
1. [Set up HTTPS support](/docs/infra/https-support.md).
1. Optionally adjust the configuration for the networks you want to have on your
   project in the [project-config module](/infra/project-config/networks.tf).
   See the next section for more info.
1. Configure the app in `infra/<APP_NAME>/app-config/main.tf`.
   1. Update `has_database` to `true` or `false` depending on whether or not
      your application has a database to integrate with. This setting determines
      whether or not to create VPC endpoints needed by the database layer.
   1. Update `network_name` for your application environments. This mapping
      ensures that each network is configured appropriately based on the
      application(s) in that network (see `local.apps_in_network` in
      [/infra/networks/main.tf](/infra/networks/main.tf)). Failure to set the
      network name properly means that the network layer may not receive the
      correct application configurations (e.g., `has_database`).

## 0. Configure network setup

### Number of networks

By default, there are three networks defined, one for each application
environment. If you have multiple apps and want your applications in separate
networks, you may want to give the networks differentiating names (e.g.
"foo-dev", "foo-prod", "bar-dev", "bar-prod", instead of just "dev", "prod").

### Networking options

There is not necessarily a static list of public/private subnets per-network.
Many must be dedicated/delegated to Azure services which require the subnet to
hold only one type of resource. So you may need to add more subnet
specifications depending on your use case.

#### Default setup

A more annotated example of the default network config:

```terraform
network = {
   # IP range to use for virtual network
   vnet_cidr = "10.0.0.0/20"

   # The name of a subnet specified in block below in which the services
   # Application Gateways will be placed
   application_gateway_subnet_name = "gateway"

   # The name of a subnet specified in block below in which private endpoints
   # will be placed
   private_endpoints_subnet_name   = "private-endpoints"

   subnets = {
      # For the Application Gateways
      gateway = {
         subnet_cidr         = "10.0.0.0/24"
         # By default, subnets are allowed to access any other subnet in the
         # virtual network, except for the subnet specified by
         # `application_gateway_subnet_name`, which is locked down to only the
         # ranges specified here.
         #
         # Needs access to:
         # - The private endpoints subnet to get the TLS certs
         # - The application subnet(s) so it can route traffic to them
         outbound_peer_cidrs = ["10.0.1.0/24", "10.0.4.0/24"]
         # By default subnets do not allow traffic to/from the internet.
         internet_access     = true
      }
      # For holding private endpoints
      private-endpoints = {
         subnet_cidr = "10.0.1.0/24"
      }
      # For holding databases
      database = {
         subnet_cidr        = "10.0.3.0/24"
         service_delegation = ["Microsoft.DBforPostgreSQL/flexibleServers"]
      }
      # For the network's (default) Container App Environment
      apps-private = {
         # You should evaluate your service's scaling needs and pick a
         # suitable subnet size.
         #
         # https://learn.microsoft.com/en-us/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli#subnet
         subnet_cidr        = "10.0.4.0/24"
         service_delegation = ["Microsoft.App/environments"]
      }
   }
}
```

#### Alternative setup

A slightly simpler "alternative" setup is tentatively supported, and only
recommended for non-production environments.

Instead of a dedicated Application Gateway, another Container App Environment
with public ingress allowed is spun up to host services. This means you don't
technically need to have DNS/custom domains sorted out to get started, as you
can use the auto-generated Azure-hosted `*.azurecontainerapps.io` domains for
Container Apps.

```terraform
network = {
   vnet_cidr = "10.0.0.0/20"

   subnets = {
      apps-public = {
         # You should evaluate your service's scaling needs and pick a
         # suitable subnet size.
         #
         # https://learn.microsoft.com/en-us/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli#subnet
         subnet_cidr        = "10.0.0.0/24"
         # Instead of private endpoints, we use service endpoints
         service_endpoints  = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
         service_delegation = ["Microsoft.App/environments"]
         internet_access    = true
      }
      apps-private = {
         subnet_cidr        = "10.0.1.0/24"
         # Instead of private endpoints, we use service endpoints
         service_endpoints  = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
         service_delegation = ["Microsoft.App/environments"]
      }
      database = {
         subnet_cidr        = "10.0.2.0/24"
         service_delegation = ["Microsoft.DBforPostgreSQL/flexibleServers"]
      }
   }
}
```

## 1. Configure backend

To create the `tfbackend` file for the new network, run

```bash
make infra-configure-network NETWORK_NAME=<NETWORK_NAME>
```

## 2. Create network resources

Now run the following commands to create the resources. Review the terraform
before confirming "yes" to apply the changes.

```bash
make infra-update-network NETWORK_NAME=<NETWORK_NAME>
```

## Updating the network

If you make changes to your application's configuration that impact the network
(such as `has_database`), make sure to update the network before you update or
deploy subsequent infrastructure layers.
