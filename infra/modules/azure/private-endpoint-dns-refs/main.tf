# https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
locals {
  private_endpoint_dns_zones = {
    blob             = "privatelink.blob.core.windows.net"             # Azure Storage - Blob
    file             = "privatelink.file.core.windows.net"             # Azure Storage - File
    queue            = "privatelink.queue.core.windows.net"            # Azure Storage - Queue
    table            = "privatelink.table.core.windows.net"            # Azure Storage - Table
    sql              = "privatelink.database.windows.net"              # Azure SQL Database
    synapse          = "privatelink.sql.azuresynapse.net"              # Azure Synapse Analytics
    cosmosdb         = "privatelink.documents.azure.com"               # Azure Cosmos DB
    keyvault         = "privatelink.vaultcore.azure.net"               # Azure Key Vault
    webapp           = "privatelink.azurewebsites.net"                 # Azure App Service (Web Apps, API Apps, Mobile Apps)
    webpubsub        = "privatelink.webpubsub.azure.com"               # Azure Web PubSub Service
    backup           = "privatelink.backup.windowsazure.com"           # Azure Backup
    redis            = "privatelink.redis.cache.windows.net"           # Azure Cache for Redis
    acr              = "privatelink.azurecr.io"                        # Azure Container Registry
    batch            = "privatelink.batch.azure.com"                   # Azure Batch
    aks              = "privatelink.azmk8s.io"                         # Azure Kubernetes Service (AKS)
    search           = "privatelink.search.windows.net"                # Azure Cognitive Search
    eventgrid        = "privatelink.eventgrid.azure.net"               # Azure Event Grid
    servicebus       = "privatelink.servicebus.windows.net"            # Azure Service Bus
    eventhub         = "privatelink.eventhub.windows.net"              # Azure Event Hubs
    datalake2        = "privatelink.dfs.core.windows.net"              # Azure Data Lake Storage Gen2
    adf              = "privatelink.adf.azure.net"                     # Azure Data Factory
    loganalytics     = "privatelink.ods.opinsights.azure.com"          # Azure Monitor - Log Analytics
    datalake1        = "privatelink.azuredatalakestore.net"            # Azure Data Lake Storage Gen1
    automation       = "privatelink.azure-automation.net"              # Azure Automation
    hdinsight        = "privatelink.azurehdinsight.net"                # Azure HDInsight
    signalr          = "privatelink.signalr.net"                       # Azure SignalR Service
    springcloud      = "privatelink.springcloud.azure.com"             # Azure Spring Cloud
    apim             = "privatelink.apim.azure-api.net"                # Azure API Management
    monitor          = "privatelink.monitor.azure.com"                 # Azure Monitor
    dataexplorer     = "privatelink.dataexplorer.kusto.windows.net"    # Azure Data Explorer
    mlworkspace      = "privatelink.workspace.azureml.net"             # Azure Machine Learning Workspaces
    mlapi            = "privatelink.api.azureml.net"                   # Azure Machine Learning API
    mlnotebooks      = "privatelink.notebooks.azureml.net"             # Azure Machine Learning Notebooks
    recovery         = "privatelink.vaultcore.azure.net"               # Azure Recovery Services Vault (Azure Site Recovery)
    frontendhub      = "privatelink.frontendhub.windows.net"           # Azure Event Hubs (Frontend)
    websockets       = "privatelink.websockets.azurewebsites.net"      # Azure App Service Websockets
    postgresql       = "privatelink.postgres.database.azure.com"       # Azure Database for PostgreSQL
    mariadb          = "privatelink.mariadb.database.azure.com"        # Azure Database for MariaDB
    mysql            = "privatelink.mysql.database.azure.com"          # Azure Database for MySQL
    synapsepipelines = "privatelink.dev.azuresynapse.net"              # Azure Synapse Analytics (Pipelines)
    synapseworkspace = "privatelink.sql.azuresynapse.net"              # Azure Synapse Analytics (Workspaces)
    cognitive        = "privatelink.cognitiveservices.azure.com"       # Azure Cognitive Services
    analysis         = "privatelink.asazure.windows.net"               # Azure Analysis Services
    recoveryvault    = "privatelink.recoveryservices.windowsazure.com" # Azure Recovery Services Vault
  }

  dns_zone_key_resource_type_map = {
    "vaults"          = "keyvault"
    "registries"      = "acr"
    "flexibleServers" = "postgresql" # not always correct (like if you're using MariaDB)
  }

  zones_by_resource_type = {
    for resource_type, zone_key in local.dns_zone_key_resource_type_map : resource_type => local.private_endpoint_dns_zones[zone_key]
  }

  dns_zone_key_provider_map = {
    "Microsoft.KeyVault"          = "keyvault"
    "Microsoft.ContainerRegistry" = "acr"
    "Microsoft.DBforPostgreSQL"   = "postgresql"
  }

  zones_by_provider = {
    for provider, zone_key in local.dns_zone_key_provider_map : provider => local.private_endpoint_dns_zones[zone_key]
  }

}

output "zones" {
  value = local.private_endpoint_dns_zones
}

output "zones_by_resource_type" {
  value = local.zones_by_resource_type
}

output "zones_by_provider" {
  value = local.zones_by_resource_type
}
