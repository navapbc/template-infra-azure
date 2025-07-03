# Database Access Control

All database access authenticates via [Entra
ID](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-configure-sign-in-azure-ad-authentication).
One benefit of which is there are no long-lived credentials that need to be
stored and managed for database access.

This is accomplished by creating Entra ID groups for each database that relevant
service principals or users can be put into. There are three Entra ID Groups
created during the provisioning of a database:

- "DB Admin" group
- "Migrator" group
- "App" group

When connecting to the database, the group name is given as the username and a
generated token as the password. Refer to the above linked Microsoft
documentation for more details.

## Administrator access

Any entity in the "DB Admin" Entra group can connect to the database as an
administrator.

If your currently authenticated user is in this group, you can get a token to
use as the "password" with:

```bash
az account get-access-token --resource-type oss-rdbms
```

And use the group name as the "username".

## Database roles and permissions

The database roles are created by the Role Manager code running as an admin. The
following roles are created:

* **migrator** — The `migrator` role is the role the database migration task
  assumes. Database migrations are run as part of the deploy workflow before the
  new container image is deployed to the service. The `migrator` role has
  permissions to create tables in the `app` schema.
* **app** — The `app` role is the role the application service assumes. The
  `app` role has read/write permissions in the `app` schema.
