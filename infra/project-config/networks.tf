locals {
  manage_privatelink_dns = true
  shared_account_name    = "lowers"

  # If you are able to get the DNS for an entire domain/subdomain delegated to
  # your control, you can specify that domain here.
  #
  # See /docs/infra/set-up-custom-domains.md
  shared_hosted_zone = "my-project-subdomain.foo.com"

  network_configs = {
    dev = {
      account_name = "lowers"

      domain_config = {
        manage_dns  = true
        hosted_zone = "dev.${local.shared_hosted_zone}"

        # After initial experiments, you may want to switch to an ACME server
        # that issues certificates that a browser will accept. You will need to
        # tear down the service layer and destroy the existing certificate
        # resources before switching this value.
        # acme_server_url = "https://acme-v02.api.letsencrypt.org/directory"
      }

      network = {
        vnet_cidr = "10.0.0.0/20"

        application_gateway_subnet_name = "gateway"
        private_endpoints_subnet_name   = "private-endpoints"

        subnets = {
          gateway = {
            subnet_cidr         = "10.0.0.0/24"
            outbound_peer_cidrs = ["10.0.1.0/24", "10.0.4.0/24"]
            internet_access     = true
          }
          private-endpoints = {
            subnet_cidr = "10.0.1.0/24"
          }
          database = {
            subnet_cidr        = "10.0.3.0/24"
            service_delegation = ["Microsoft.DBforPostgreSQL/flexibleServers"]
          }
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
    }

    staging = {
      account_name = "lowers"

      domain_config = {
        manage_dns  = true
        hosted_zone = "staging.${local.shared_hosted_zone}"
      }

      network = {
        vnet_cidr = "10.0.16.0/20"

        subnets = {
          apps-public = {
            # You should evaluate your service's scaling needs and pick a
            # suitable subnet size.
            #
            # https://learn.microsoft.com/en-us/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli#subnet
            subnet_cidr        = "10.0.16.0/24"
            service_endpoints  = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
            service_delegation = ["Microsoft.App/environments"]
            internet_access    = true
          }
          apps-private = {
            subnet_cidr        = "10.0.17.0/24"
            service_endpoints  = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
            service_delegation = ["Microsoft.App/environments"]
          }
          database = {
            subnet_cidr        = "10.0.18.0/24"
            service_delegation = ["Microsoft.DBforPostgreSQL/flexibleServers"]
          }
        }
      }
    }

    prod = {
      account_name = "prod"

      domain_config = {
        manage_dns = true

        hosted_zone = "my-project-subdomain.foo.com"

        acme_server_url = "https://acme-v02.api.letsencrypt.org/directory"
      }

      network = {
        vnet_cidr = "10.0.32.0/20"

        application_gateway_subnet_name = "gateway"
        private_endpoints_subnet_name   = "private-endpoints"

        subnets = {
          gateway = {
            subnet_cidr         = "10.0.32.0/24"
            outbound_peer_cidrs = ["10.0.33.0/24", "10.0.35.0/24"]
            internet_access     = true
          }
          private-endpoints = {
            subnet_cidr = "10.0.33.0/24"
          }
          database = {
            subnet_cidr        = "10.0.34.0/24"
            service_delegation = ["Microsoft.DBforPostgreSQL/flexibleServers"]
          }
          apps-private = {
            # You should evaluate your service's scaling needs and pick a
            # suitable subnet size.
            #
            # https://learn.microsoft.com/en-us/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli#subnet
            subnet_cidr        = "10.0.35.0/24"
            service_delegation = ["Microsoft.App/environments"]
          }
        }
      }
    }
  }
}
