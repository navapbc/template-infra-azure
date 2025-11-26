# Set up Application Environment

The application environment setup process will:

1. Configure a new application environment and create the infrastructure
   resources for the application in that environment

## Requirements

Before setting up the application's environments you'll need to have:

1. [A compatible application in the app
   folder](https://github.com/navapbc/template-infra/blob/main/template-only-docs/application-requirements.md)
1. Configure the app in `infra/<APP_NAME>/app-config/main.tf`.
   1. Make sure you update `has_database` to `true` or `false` depending on
      whether or not your application has a database to integrate with.
   1. If you're configuring your production environment, make sure to update the
      `service_cpu`, `service_memory`, and `service_desired_instance_count`
      settings based on the project's needs. If your application is sensitive to
      performance, consider doing a load test.
1. [Create a nondefault VPC to be used by the application](./set-up-network.md)
1. (If the application has a database) [Set up the database for the
   application](./set-up-database.md)

## 1. Configure backend

To create the `tfbackend` and `tfvars` files for the new application
environment, run:

```bash
make infra-configure-app-service APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

`APP_NAME` needs to be the name of the application folder within the `infra`
folder. `ENVIRONMENT` needs to be the name of the environment you are creating.
This will create a file called
`<ENVIRONMENT>.s3.tfbackend` in the `infra/app/service` module directory.

Depending on the value of `has_database` in the app-config module
(`infra/<APP_NAME>/app-config/main.tf`), the application will be configured with
or without database access.

## 2. Build and publish the application to the application build repository

Before creating the application resources, you'll need to first build and
publish at least one image to the application build repository.

There are two ways to do this:

1. Trigger the "Build and Publish" workflow from your repo's GitHub Actions tab.
   This option requires that the configuration parameters have been set for the
   GitHub client as a part of the infra account setup process.
1. Alternatively, run the following from the root directory. This option can
   take much longer than the GitHub workflow, depending on your machine's
   architecture.

    ```bash
    make release-build APP_NAME=<APP_NAME>
    make release-publish APP_NAME=<APP_NAME>
    ```

Copy the image tag name that was published. You'll need this in the next step.

## 3. Create application resources with the image tag that was published

Now run the following commands to create the resources, using the image tag that
was published in the previous step. Review the terraform before confirming "yes"
to apply the changes.

```bash
TF_CLI_ARGS_apply="-var=image_tag=<IMAGE_TAG>" make infra-update-app-service APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

