variable "job_name" {
  type        = string
  description = "Name of the Container App Job. Must be unique within the resource group."
}

variable "container_name" {
  type        = string
  description = "Name of the container within the job's template."
}

variable "container_app_environment_id" {
  type        = string
  description = "Resource ID of the Container App Environment the job runs in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group the job is created in."
}

variable "resource_group_location" {
  type        = string
  description = "Azure region the job is created in."
}

variable "identity_id" {
  type        = string
  description = "Resource ID of the user assigned identity the job runs as."
}

variable "image_registry_url" {
  type        = string
  description = "URL of the image registry the job pulls its image from."
}

variable "image_url" {
  type        = string
  description = "Fully qualified image reference to run, e.g. my.registry.com/navapbc/my-cool-app:abc123."
}

variable "command" {
  type        = list(string)
  description = <<-EOT
    Command to run in the container, overriding the image's ENTRYPOINT.

    Leave empty to use the image's default entrypoint. This is the Azure
    analog of the AWS template's `task_command`.
  EOT
  default     = []
}

variable "args" {
  type        = list(string)
  description = "Arguments passed to the container's command, overriding the image's CMD."
  default     = []
}

variable "cpu" {
  type        = number
  description = "Number of CPU units allocated to the job's container. Must be specified with memory in 0.25/0.5Gi increments."
}

variable "memory" {
  type        = string
  description = "Amount of memory allocated to the job's container. Must be specified with cpu in 0.25/0.5Gi increments."
}

variable "environment_variables" {
  description = "List of plain (non-secret) environment variables to set on the job's container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "List of Key Vault backed secrets to expose to the job's container as environment variables."
  type = set(object({
    name = string
    id   = string
  }))
  default = []
}

variable "trigger" {
  description = <<-EOT
    Trigger that causes the job to run. Exactly one trigger type is configured
    per job.

    * `manual` — the job only runs when started explicitly (e.g. by the
      database-migrations workflow or `az containerapp job start`).
    * `schedule` — the job runs on a recurring cron schedule. Requires
      `cron_expression`.
    * `event` — the job scales up in response to messages on a storage queue,
      via a KEDA `azure-queue` scaler. Requires `storage_account_name` and
      `queue_name`.

    `parallelism` is the number of replicas run per execution, and
    `replica_completion_count` is how many of them must succeed for the
    execution to be considered successful.
  EOT
  type = object({
    type                     = string
    parallelism              = optional(number, 1)
    replica_completion_count = optional(number, 1)

    # schedule
    cron_expression = optional(string)

    # event
    storage_account_name        = optional(string)
    queue_name                  = optional(string)
    queue_length                = optional(number, 1)
    min_executions              = optional(number, 0)
    max_executions              = optional(number, 10)
    polling_interval_in_seconds = optional(number, 30)
  })

  validation {
    condition     = contains(["manual", "schedule", "event"], var.trigger.type)
    error_message = "trigger.type must be one of: manual, schedule, event."
  }

  validation {
    condition     = var.trigger.type != "schedule" || var.trigger.cron_expression != null
    error_message = "trigger.cron_expression is required when trigger.type is \"schedule\"."
  }

  validation {
    condition = var.trigger.type != "event" || (
      var.trigger.queue_name != null && var.trigger.storage_account_name != null
    )
    error_message = "trigger.queue_name and trigger.storage_account_name are required when trigger.type is \"event\"."
  }
}

variable "replica_timeout_in_seconds" {
  type        = number
  description = "Maximum time a replica is allowed to run before it is terminated."
  default     = 3600
}

variable "replica_retry_limit" {
  type        = number
  description = "Number of times a failed replica is retried before the execution is marked failed."
  default     = 0
}

variable "tags" {
  description = "A map of tags for associated resources."
  type        = map(string)
  default     = {}
}
