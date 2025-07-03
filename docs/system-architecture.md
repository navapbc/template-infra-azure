# System Architecture

This diagram shows the system architecture. [🔒 Make a copy of this Lucid template for your own application](https://lucid.app/lucidchart/cd2e441b-68ca-429e-a71f-35b8d7c48bae/edit).

![System architecture](https://lucid.app/publicSegments/view/e4eff3ce-8a40-4b41-91ca-d4c84554d5c8/image.png)

* **Application Gateways** - Azure Application Gateway instances, one per application/service.
* **Azure Database PostgreSQL Server** - Azure Database PostgreSQL flexible server holding the database used by the application. One per application.
* **Container App Environment** - Azure Container App Environment. TODO . One per network.
* **Container App** - Azure Container App. TODO. One per application.
* **Container App Job** - Azure Container App Job. TODO. Generally two per application, one for the application background jobs (run migrations, data processing, etc) and one for the application's "DB Role Manager" (provisions database roles, etc.).
* **Container Registry** - Azure Container Registry that holds the build repositories of application container images. There is one instance for the entire project (by default).
* **Entra Tenant** - Microsoft Entra tenant, represents an organization and provides an dedicated instance of Entra ID TODO. One per project generally.
* **GitHub** - Source code repository. Also responsible for Continuous Integration (CI) and Continuous Delivery (CD) workflows. GitHub Actions builds and deploys releases to the projects Azure Container Registry that stores container images for the application service.
* **GitHub OIDC** - For each Subscription, there is an Application registered for use by GitHub Actions to connect and manage resources inside that Subscription.
* **Key Vault** - Azure Key Vault which stores secrets/key/certificates. There are multiple instances for a project, as follows:
    * **Certificate Key Vault** - Azure Key Vault instance for TLS certificates for all web services in a Subscription. One per Subscription.
    * **Service Key Vaults** - Azure Key Vault instances holding service secrets. One per application.
    * **Terraform Backend Key Vault** - Azure Key Vault instance holding Customer Managed Encryption Key for the Terraform state file(s) (if enabled). One per Terraform Backend Storage instance.
* **Log Analytics Workspace** - Azure Log Analytics Workspace. Data store to collect and analyze various logs.
    * **Log Analytics Workspace - Subscription** - Stores log data for resources not associated with a particular network, like the access logs for the Terraform backend storage account. So more operations/admin.
    * **Log Analytics Workspace - Network** - Stores log data for resources inside the network, like applications.
* **Monitor** - Azure Monitor, observability service which pushes activity logs, access logs, metrics, and more into different data storage backends.
* **Private Endpoints** - Azure Private Endpoints. These connect specific Azure resources (instances of an Azure service) to a network interface/IP address inside the Private Endpoint subnet, which the default network security group rules allow the rest of the virtual network access to. This means traffic to these Azure resources never travels over the public internet. There is one endpoint per Azure resource used.
* **Private DNS Zones** - Azure Private DNS. Provides DNS/name based resolution to the Private Endpoints for configured services/resources.
* **Subnet** - Azure Subnet. Many are dedicated/delegated to Azure services which require the subnet to hold only one type of resource. So there is not necessarily a static list of public/private subnets. All subnets have Network Security Group rules defined that generally allow intra-virtual-network traffic, except for the Application Gateway subnet, which is restricted to only connect to explicit subnets (typically the Private App subnet and the Private Endpoints subnet).
* **Subscription** - Azure Subscription, also called "account" in various project docs. Generally they should all belong to the same Tenant, cross-Tenant setups have not been tested.
* **Terraform ACME provider** - Acquires and refreshes TLS certificates for the Application Gateway during Terraform operations for domains that don't have certificates managed by other methods.
* **Terraform Backend Storage** - Azure Storage Account+Container used to store Terraform state files with native locking for managing concurrent access. One per subscription.
* **Virtual Network** - Azure Virtual Network. One per configured network.
