variable "container_port" {
  type        = number
  description = "The port number on the container that's bound to the user-specified"
  default     = 8000
}

variable "image_registry_id" {
  type        = string
  description = "Resource ID of the image registry."
}

variable "image_registry_url" {
  type        = string
  description = "URL of the image registry."
}

variable "image_repository_url" {
  type        = string
  description = "URL of image repository, e.g. my.registry.com/navapbc/my-cool-app"
}

variable "image_tag" {
  type        = string
  description = "docker tag of image you wish to deploy"
}

variable "service_name" {
  type        = string
  description = "name of the application service"
}

variable "resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "resource_group_location" {
  type        = string
  description = "location of resource group"
}

variable "secrets" {
  type = set(object({
    name                    = string
    id                      = string
    resource_versionless_id = string
  }))
  description = "List of configurations for defining environment variables that pull from secret store"
  default     = []
}

variable "db_vars" {
  description = "Variables for integrating the app service with a database"
  type = object({
    migrator_group_object_id = string
    app_group_object_id      = string

    connection_info = object({
      host        = string
      port        = string
      user        = string
      db_name     = string
      schema_name = string
    })
  })
  default = null
}

variable "storage_vars" {
  description = <<-EOT
    Variables for integrating the app service with blob storage.

    `eventgrid_system_topic_name` and `resource_group_name` are only required
    when the service defines event triggered jobs (see `var.jobs`), since those
    subscribe to blob events on the storage account.
  EOT
  type = object({
    storage_account_id   = string
    storage_account_name = string
    container_name       = string

    eventgrid_system_topic_name = optional(string)
    resource_group_name         = optional(string)
  })
  default = null
}

variable "extra_environment_variables" {
  type        = map(string)
  description = "Additional environment variables to pass to the service container. Map from environment variable name to the value."
  default     = {}
}

variable "subnet_name" {
  type        = string
  description = "Service's subnet name"
}

variable "cpu" {
  type        = number
  default     = 0.25
  description = "Number of cpu units allocated to containers. Limited to 4 with default 'Consumption' workload profile and must be specified with memory in 0.25/0.5Gi increments (e.g., 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi)."
}

variable "memory" {
  type        = string
  default     = "0.5Gi"
  description = "Amount of memory allocated to containers. Limited to 8Gi with default 'Consumption' workload profile and must be specified with CPU in 0.25/0.5Gi increments (e.g., 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi)."
}

variable "job_cpu" {
  type        = number
  default     = null
  description = "Number of cpu units allocated to job containers. Defaults to `var.cpu` when unset. Individual jobs can override this via their own `cpu` setting."
}

variable "job_memory" {
  type        = string
  default     = null
  description = "Amount of memory allocated to job containers. Defaults to `var.memory` when unset. Individual jobs can override this via their own `memory` setting."
}

variable "jobs" {
  description = <<-EOT
    Configurations for background jobs that run alongside the service.

    Each job runs the same container image and the same environment variables
    and secrets as the service, differing only in the command it runs and what
    triggers it. The map key is the job's name, which is appended to the
    service name to form the Container App Job name.

    Supported triggers:

    * `manual` — only runs when started explicitly, e.g. with
      `az containerapp job start`.
    * `schedule` — runs on a recurring cron schedule, set by
      `cron_expression`. Uses the standard five field cron syntax, in UTC.
    * `event` — runs in response to files uploaded to the service's blob
      storage container, optionally filtered by `path_prefix`. Requires the
      application to have blob storage enabled.

    Example:

    ```
    jobs = {
      nightly-etl = {
        command = ["python", "-m", "etl.nightly"]
        trigger = {
          type            = "schedule"
          cron_expression = "0 3 * * *"
        }
      }

      process-uploads = {
        command = ["python", "-m", "etl.process_upload"]
        cpu     = 1
        memory  = "2Gi"
        trigger = {
          type        = "event"
          path_prefix = "uploads/"
        }
      }
    }
    ```
  EOT

  type = map(object({
    command = optional(list(string), [])
    args    = optional(list(string), [])

    cpu    = optional(number)
    memory = optional(string)

    replica_timeout_in_seconds = optional(number, 3600)
    replica_retry_limit        = optional(number, 0)

    trigger = object({
      type                     = string
      parallelism              = optional(number, 1)
      replica_completion_count = optional(number, 1)

      # schedule
      cron_expression = optional(string)

      # event
      path_prefix                 = optional(string, "")
      queue_length                = optional(number, 1)
      min_executions              = optional(number, 0)
      max_executions              = optional(number, 10)
      polling_interval_in_seconds = optional(number, 30)
    })
  }))

  default = {}

  validation {
    condition = alltrue([
      for name, job in var.jobs :
      contains(["manual", "schedule", "event"], job.trigger.type)
    ])
    error_message = "Each job's trigger.type must be one of: manual, schedule, event."
  }

  validation {
    condition = alltrue([
      for name, job in var.jobs :
      job.trigger.cron_expression != null if job.trigger.type == "schedule"
    ])
    error_message = "Jobs with trigger.type \"schedule\" must set trigger.cron_expression."
  }
}

# TODO: rename to min_instance_count? It's a little different than AWS.
variable "desired_instance_count" {
  type        = number
  description = "Minimum number of container instances to have running."
  default     = 0
}

variable "domain_name" {
  type        = string
  description = "The fully qualified domain name for the application"
  default     = null
}

variable "domain_hosted_zone_name" {
  type        = string
  description = "The root hosted zone name for the domain"
  default     = null
}

variable "domain_hosted_zone_subscription_id" {
  type        = string
  description = "The Subscription where the hosted zone lives"
  default     = null
}

variable "domain_resource_group_name" {
  type        = string
  description = "The resource group name where the hosted zone resource lives"
  default     = null
}

variable "domain_network_zone_name" {
  type        = string
  description = "The hosted zone name for network"
  default     = null
}

variable "domain_certificate_secret_id" {
  type = string
}

variable "manage_dns" {
  type    = bool
  default = true
}

variable "is_temporary" {
  description = "Whether the service is meant to be spun up temporarily (e.g. for automated infra tests)."
  type        = bool
  default     = false
}

variable "network_resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "application_gateway_subnet_id" {
  type = string
}

variable "application_gateway_sku_name" {
  type = string

  validation {
    condition     = contains(["Basic", "Standard_v2", "WAF_v2"], var.application_gateway_sku_name)
    error_message = "Valid values Application Gateway SKU: Basic, Standard_v2, WAF_v2"
  }
}

variable "tags" {
  description = "A map of tags for associated resources."
  type        = map(string)
  default     = {}
}

variable "dependencies" {
  type        = list(any)
  default     = null
  description = <<EOT
Utility variable for establishing resources the main service should wait on
before creation.

The service may depend on some things to run that are hard to capture directly
as a part of the service definition, this provides a workaround for some use
cases.
EOT
}
