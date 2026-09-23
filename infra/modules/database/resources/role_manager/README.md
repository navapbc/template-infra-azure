# DB Role Manager

Creates and configures the database roles, schema, and privileges used by the
application.

## Cloud provider abstraction

Almost everything this tool does is portable Postgres. Four things are
cloud-specific:

1. obtaining an auth token,
2. creating a principal (database user),
3. listing managed-identity principals,
4. whether principals must be created in the `postgres` root database.

Those four are the `Provider` protocol in
[`src/role_manager/providers/base.py`](src/role_manager/providers/base.py).
`manage.py` and `check.py` are written against that protocol, so adding AWS
support means adding a module under `providers/` and registering it -- not
editing the role management logic.

| | Azure | AWS (not yet implemented) |
| --- | --- | --- |
| Auth | Entra token via `DefaultAzureCredential` | IAM auth token |
| Create principal | `pgaadauth_create_principal` | `CREATE USER` |
| Required role grant | none | `rds_iam` |
| Principals created in | `postgres` root db | application db |

The provider is selected by the `CLOUD_PROVIDER` environment variable and
defaults to `azure`, so existing deployments need no configuration change.

## Development

```bash
make check   # format, lint, typecheck, and test
make test    # tests only
```
