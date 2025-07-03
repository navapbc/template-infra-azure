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
   project in the [project-config module](/infra/project-config/networks.tf). By
   default, there are three networks defined, one for each application
   environment. If you have multiple apps and want your applications in separate
   networks, you may want to give the networks differentiating names (e.g.
   "foo-dev", "foo-prod", "bar-dev", "bar-prod", instead of just "dev", "prod").
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
