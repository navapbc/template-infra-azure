# Background jobs

The application may have background jobs that support the application. Types of
background jobs include:

* Jobs that occur on a fixed schedule (e.g. every hour or every night) — This
  type of job is useful for ETL jobs that can't be event-driven, such as ETL
  jobs that ingest source files from an SFTP server or from an storage location
  managed by another team that we have little control or influence over.
* Jobs that trigger on an event (e.g. when a file is uploaded to the document
  storage service). This type of job can be processed by two types of tasks:
  * Tasks that spin up on demand to process the job — This type of task is
    appropriate for low-frequency ETL jobs
  * Worker tasks that are running continuously, waiting for jobs to enter a
    queue that the worker then processes — This type of task is ideal for high
    frequency, low-latency jobs such as processing user uploads or submitting
    claims to an unreliable or high-latency legacy system **This functionality
    has not yet been implemented**

Most common use cases are covered via [Container App
Jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli).

## Job configuration

Background jobs are configured in the application's `env-config` module, in
`/infra/{{app_name}}/app-config/env-config/jobs.tf`. Each entry in the `jobs`
map defines one Container App Job. The map key is the job's name, which is
appended to the service name to form the name of the job in Azure.

Every job runs the same container image, environment variables, and secrets as
the service itself. A job differs from the service only in the command it runs
and in what triggers it.

```terraform
jobs = {
  nightly_etl = {
    command = ["python", "-m", "etl.nightly"]

    trigger = {
      type            = "schedule"
      cron_expression = "0 3 * * *"
    }
  }
}
```

Because jobs are defined in `env-config`'s `locals` rather than as module
variables, the same job definitions apply to every environment.

### Job settings

| Setting | Description |
| --- | --- |
| `command` | Command to run, overriding the image's `ENTRYPOINT`. This is the Azure analog of the AWS template's `task_command`. |
| `args` | Arguments passed to the command, overriding the image's `CMD`. |
| `cpu` | CPU allocated to this job. Defaults to `service_job_cpu`, then to the service's own `cpu`. |
| `memory` | Memory allocated to this job. Defaults to `service_job_memory`, then to the service's own `memory`. |
| `replica_timeout_in_seconds` | How long a replica may run before it is terminated. Defaults to `3600`. |
| `replica_retry_limit` | How many times a failed replica is retried. Defaults to `0`. |
| `trigger` | What causes the job to run. See below. |

CPU and memory are configurable separately from the application's own settings,
since background jobs frequently have different resource needs than the web
service. Set `service_job_cpu` and `service_job_memory` on the environment's
config module to change the default for all of an environment's jobs, and set
`cpu`/`memory` on an individual job to override it for that job.

Note that Container Apps requires CPU and memory to be specified together in
0.25 CPU / 0.5Gi increments (e.g. `0.5`/`1Gi`, `1`/`2Gi`).

## Triggers

Each job has exactly one trigger, set by `trigger.type`.

All trigger types accept `parallelism` (how many replicas run per execution) and
`replica_completion_count` (how many of them must succeed for the execution to
count as successful). Both default to `1`.

### Manual jobs

`type = "manual"` jobs only run when started explicitly:

```console
az containerapp job start --name <job name> --resource-group <resource group>
```

A manually triggered job is always created for running database migrations,
independent of the `jobs` configuration. See [database
access](/docs/infra/database-access-control.md).

### Scheduled jobs

`type = "schedule"` jobs run on a recurring schedule, set by `cron_expression`
using standard five field cron syntax. Schedules are evaluated in UTC.

```terraform
trigger = {
  type            = "schedule"
  cron_expression = "0 3 * * *"
}
```

This maps to the Container App Job's [schedule
trigger](https://learn.microsoft.com/en-us/azure/container-apps/jobs?tabs=azure-cli#scheduled-jobs).

### File upload (event) jobs

`type = "event"` jobs run in response to files uploaded to the application's
blob storage container. They require the application to have blob storage
enabled (`has_blob_storage = true`).

```terraform
trigger = {
  type        = "event"
  path_prefix = "uploads/"
}
```

`path_prefix` filters which uploads trigger the job. An empty prefix (the
default) matches every upload to the container.

Additional settings: `queue_length` (messages per replica, default `1`),
`min_executions` (default `0`), `max_executions` (default `10`), and
`polling_interval_in_seconds` (default `30`).

#### How file upload jobs work

Azure Container App Jobs have no direct blob-event trigger, so blob events are
routed through a queue:

```
blob upload → Event Grid system topic → storage queue → KEDA scaler → job
```

Each event triggered job gets its own storage queue on the service's storage
account, and its own Event Grid subscription filtered to `path_prefix`. The job
scales on that queue's depth using a KEDA [azure-queue
scaler](https://keda.sh/docs/scalers/azure-storage-queue/), authenticating with
the service's managed identity so that the storage account can keep shared
access keys disabled.

**This differs from the AWS template in an important way.** In the AWS template,
the uploaded file's path is substituted into the job's command via the
`<object_key>` and `<bucket_name>` placeholders. Azure's queue-based trigger has
no equivalent mechanism — the job is started by queue depth, not by an event
payload, so there is nothing to substitute at launch time.

Instead, an event triggered job reads its queue itself and processes the
messages it finds there. Each message is an [Event Grid blob created
event](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-event-overview),
whose `data.url` field holds the URL of the uploaded blob. The queue name is
`<job name>-events`, on the storage account named by the
`AZURE_STORAGE_ACCOUNT_NAME` environment variable.

A consequence of this design is that a single job execution may process more
than one uploaded file, and the job should delete each message once it has
handled it.
