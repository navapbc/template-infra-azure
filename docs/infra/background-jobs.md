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

There is currently a single manually triggered Container App Job definition that
is created by default, which is used to run migrations.

There is not yet simpler interface exposed to configure additional jobs, but you
can create additional `azurerm_container_app_job` resources yourself in your
`/infra/{{app_name}}/service` module.
