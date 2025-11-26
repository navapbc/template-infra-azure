# Set up database

The database setup process will:

1. Configure and deploy an application database cluster using [Azure Database
   for PostgreSQL flexible
   server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/overview)
2. Create a [PostgreSQL
   schema](https://www.postgresql.org/docs/current/ddl-schemas.html) `app` to
   contain tables used by the application.
3. Create an Microsoft Entra group that allows [connection to the database using
   Microsoft Entra ID
   authentication](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-configure-sign-in-azure-ad-authentication)
4. Create an Azure Container App Job, the "role manager", for provisioning the
   [PostgreSQL database
   users](https://www.postgresql.org/docs/8.0/user-manag.html) that will be used
   by the application service and by the migrations task.
5. Invoke the role manager to create the `app` and `migrator` Postgres users.

## Requirements

Before setting up the database you'll need to:

1. [Set up the Azure account](./set-up-azure-account.md)
2. [Create a nondefault VPC for application](./set-up-network.md)

## 1. Configure backend

To create the `tfbackend` file for the new application environment, run

```bash
make infra-configure-app-database APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

`APP_NAME` needs to be the name of the application folder within the `infra` folder. By default, this is `app`.
`ENVIRONMENT` needs to be the name of the environment you are creating. This will create a file called `<ENVIRONMENT>.s3.tfbackend` in the `infra/app/service` module directory.

## 2. Build and publish the role-manager to build repository

Before creating the application resources, you'll need to first build and publish at least one image to the application build repository.

```sh
make db-role-manager-release-build
make db-role-manager-release-publish APP_NAME=<APP_NAME>
```

Copy the image tag name that was published. You'll need this in the next step.

## 3. Create database resources

Now run the following commands to create the resources. Review the terraform before confirming "yes" to apply the changes. This can take over 5 minutes.

```bash
TF_CLI_ARGS_apply="-var=role_manager_image_tag=<IMAGE_TAG>" make infra-update-app-database APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

## 4. Create Postgres users

Trigger the role manager Lambda function that was created in the previous step
to create the application and `migrator` Postgres users.

```bash
make infra-update-app-database-roles APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

### Important note on Postgres table permissions

Before creating migrations that create tables, first create a migration that
includes the following SQL command (or equivalent if your migrations are written
in a general-purpose programming language):

```sql
ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO app
```

This will cause all future tables created by the `migrator` user to
automatically be accessible by the `app` user. See the [Postgres docs on ALTER
DEFAULT
PRIVILEGES](https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html)
for more info. As an example see the example app's migrations file
[migrations.sql](https://github.com/navapbc/template-infra-azure/blob/main/template-only-app/migrations.sql).

Why is this needed? The reason is that the `migrator` role will be used by the
migration task to run database migrations (creating tables, altering tables,
etc.), while the `app` role will be used by the web service to access the
database. Moreover, in Postgres, new tables won't automatically be accessible by
roles other than the creator unless specifically granted, even if those other
roles have usage access to the schema that the tables are created in. In other
words, if the `migrator` user created a new table `foo` in the `app` schema, the
`app` user will not automatically be able to access it by default.

## 5. Check that database roles have been configured properly

```bash
make infra-check-app-database-roles APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

## Set up application environments

Once you set up the deployment process, you can proceed to [set up the
application service](./set-up-app-env.md)
