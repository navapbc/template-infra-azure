# Terraform module architecture

This doc describes how the Terraform modules are structured. Directory structure
and layers are documented in the [infrastructure README](/infra/README.md).

## Approach

The infrastructure code is organized into:

- root modules
- child modules

[Root modules](https://www.terraform.io/language/modules#the-root-module) are
modules that are deployed separately from each other, whereas child modules are
reusable modules that are called from root modules. To deploy all the resources
necessary for a given environment, all the root modules must be deployed
independently in the correct order.

Root modules generally create a Resource Group for all their child modules to
use.

## Module calling structure

The following diagram describes the relationship between modules and their child
modules. Arrows go from the caller module to the child module.

```mermaid
flowchart TB

  classDef default fill:#FFF,stroke:#000
  classDef root-module fill:#F37100,stroke-width:3,font-family:Arial
  classDef child-module fill:#F8E21A,font-family:Arial

  subgraph infra
    account:::root-module
    network:::root-module

    subgraph app
      subgraph environment
        app/database[database]:::root-module
        app/service[service]:::root-module
      end
    end

    subgraph modules
      azure/container-registry:::child-module
      terraform-backend-azure:::child-module
      auth-github-actions:::child-module
      network/resources:::child-module
      database:::child-module
      service:::child-module
      domain:::child-module
      private-endpoint:::child-module
      certificate-store:::child-module
      secret-store:::child-module
      secret:::child-module
    end

    account --> terraform-backend-azure
    account --> auth-github-actions
    account --> certificate-store
    account --> azure/container-registry
    network --> network/resources
    network --> domain
    network --> private-endpoint
    app/service --> service
    app/service --> secret-store
    app/service --> secret
    app/service --> private-endpoint
    app/database --> database

  end
```

## Module dependencies

The following diagram illustrates the dependency structure of the root modules.

1. Account root modules need to be deployed first to create the Terraform
   backends storage used in the rest of the root modules.
3. The individual application environment root modules are deployed last once
   everything else is set up. These root modules are the ones that are deployed
   regularly as part of application deployments.

```mermaid
flowchart RL

classDef default fill:#F8E21A,stroke:#000,font-family:Arial

app/service --> accounts
app/service --> app/network
app/service --> app/database --> app/network --> accounts
app/database --> accounts
```

### Guidelines for layers

When deciding which layer to put an infrastructure resource in, follow the
following guidelines.

* **Default to the service layer** By default, consider putting application
  resources as part of the service layer. This way the resource is managed
  together with everything else in the environment, and spinning up new
  application environments automatically spins up the resource.

* **Consider variations in the number and types of environments of each layer:**
  If the resource does not or might not map one-to-one with application
  environments, consider putting the resource in a different layer. For example,
  the number of cloud accounts may or may not match the number of networks,
  which may or may not match the number of application environments. As a final
  example, an application may or may not need a database layer at all, so by
  putting database-related resources in the database layer, and application can
  skip those resources by skipping the entire layer rather than by needing to
  change the behavior of an existing layer. Choose the layer for the resource
  that maps most closely with that resource's purpose.

* **Consider uniqueness constraints on resources:** This is a special case of
  the previous consideration: resources that are required to be unique at some
  layer should be managed by a layer that creates only one of that resource per
  instance of that layer. For example, in AWS, there can only be one OIDC
  provider for GitHub actions per AWS account (see [Creating OIDC identity
  providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)),
  so the OIDC provider should go in the account layer. As another example, there
  can only be one VPC endpoint per VPC per AWS service (see [Fix conflicting DNS
  domain errors for interface VPC
  endpoints](https://repost.aws/knowledge-center/vpc-interface-endpoint-domain-conflict)).
  Therefore, if multiple application environments share a VPC, they can't each
  create a VPC endpoint for the same AWS service. As such, the VPC endpoint
  logically belongs to the network layer and VPC endpoints should be created and
  managed per network instance rather than per application environment.

* **Consider policy constraints on what resources the project team is authorized
  to manage:** Different categories of resources may have different requirements
  on who is allowed to create and manage those resources. Resources that the
  project team are not allowed to manage directly should not be mixed with
  resources that the project team needs to manage directly.

* **Consider out-of-band dependencies:** Put infrastructure resources that
  require steps outside of Terraform to be completed configured in layers that
  are upstream to resources that depend on those completed resources. For
  example, after creating a database cluster, the database schemas, roles, and
  privileges need to be configured before they can be used by a downstream
  service. Therefore database resources should be separate from the service
  layer so that the database can be configured fully before attempting to create
  the service layer resources.

## Making changes to infrastructure

Now that you understand how the modules are structured, see [making changes to
infrastructure](./making-infra-changes.md).
