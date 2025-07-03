import itertools
import os
from operator import itemgetter

from pg8000.native import Connection, identifier, literal

import role_manager.db as db


def manage_main():
    manage()
    return 0


def manage(config: dict | None = None):
    """Manage database roles, schema, and privileges"""

    print(
        "-- Running command 'manage' to manage database roles, schema, and privileges"
    )

    # Microsoft Entra/Azure AD users must be created in the `postgres` database,
    # so we do that first.
    #
    # https://github.com/Azure/azure-postgresql/issues/117
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users
    with db.connect_as_admin_user_to_root_db() as admin_conn:
        print_current_db_config(admin_conn, True)

        admin_username = os.environ["ADMIN_USER"]
        app_username = os.environ["APP_USER"]
        migrator_username = os.environ["MIGRATOR_USER"]
        database_name = os.environ["DB_NAME"]
        configure_roles(
            admin_conn, admin_username, [migrator_username, app_username], database_name
        )

    # Then connect to the application's database to do everything else.
    with db.connect_as_admin_user() as admin_conn:
        print_current_db_config(admin_conn)
        configure_database(admin_conn, config)
        roles, schema_privileges = print_current_db_config(admin_conn)
        roles_with_groups = get_roles_with_groups(admin_conn)

    configure_default_privileges()

    print(
        {
            "roles": roles,
            "roles_with_groups": roles_with_groups,
            "schema_privileges": {
                schema_name: schema_acl for schema_name, schema_acl in schema_privileges
            },
        }
    )

    return 0


def get_roles(conn: Connection) -> list[str]:
    return [
        row[0]
        for row in db.execute(
            conn,
            "SELECT rolname "
            "FROM pg_roles "
            "WHERE rolname NOT LIKE 'pg_%' "
            "AND rolname NOT LIKE 'rds%'",
            print_query=False,
        )
    ]


def get_entra_principals(conn: Connection) -> list[list[str]]:
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users#list-microsoft-entra-roles-using-sql
    #
    # pg_catalog.pgaadauth_list_principals(isAdminValue boolean)
    return list(
        db.execute(
            conn,
            """
            SELECT *
            FROM pg_catalog.pgaadauth_list_principals(true)
            """,
            print_query=False,
        )
    )


def get_roles_with_groups(conn: Connection) -> dict[str, str]:
    roles_groups = db.execute(
        conn,
        """
        SELECT u.rolname AS user, g.rolname AS group
        FROM pg_roles u
        INNER JOIN pg_auth_members a ON u.oid = a.member
        INNER JOIN pg_roles g ON g.oid = a.roleid
        ORDER BY user ASC
        """,
        print_query=False,
    )

    result = {}
    for user, groups in itertools.groupby(roles_groups, itemgetter(0)):
        result[user] = ",".join(map(itemgetter(1), groups))
    return result


# Get schema access control lists. The format of the ACLs is abbreviated. To interpret
# what the ACLs mean, see the Postgres documentation on Privileges:
# https://www.postgresql.org/docs/current/ddl-priv.html
def get_schema_privileges(conn: Connection) -> list[tuple[str, str]]:
    return [
        (row[0], row[1])
        for row in db.execute(
            conn,
            """
            SELECT nspname, nspacl
            FROM pg_namespace
            WHERE nspname NOT LIKE 'pg_%'
            AND nspname <> 'information_schema'
            """,
            print_query=False,
        )
    ]


def configure_database(conn: Connection, config: dict | None = None) -> None:
    print("-- Configuring database")
    app_username = os.environ["APP_USER"]
    migrator_username = os.environ["MIGRATOR_USER"]
    schema_name = os.environ["DB_SCHEMA"]
    database_name = os.environ["DB_NAME"]

    # In Postgres 15 and higher, the CREATE privilege on the public
    # schema is already revoked/removed from all users except the
    # database owner. However, we are explicitly revoking access anyways
    # for projects that wish to use earlier versions of Postgres.
    print("---- Revoking default access on public schema")
    db.execute(conn, "REVOKE CREATE ON SCHEMA public FROM PUBLIC")

    print("---- Revoking database access from public role")
    db.execute(conn, f"REVOKE ALL ON DATABASE {identifier(database_name)} FROM PUBLIC")
    print(f"---- Setting default search path to schema {schema_name}")
    db.execute(
        conn,
        f"ALTER DATABASE {identifier(database_name)} SET search_path TO {identifier(schema_name)}",
    )

    configure_schema(conn, schema_name, migrator_username, app_username)
    # TODO: support calling job with arguments for `superuser_extensions`
    if config and config.get("superuser_extensions"):
        configure_superuser_extensions(conn, config["superuser_extensions"])


def configure_roles(
    conn: Connection, admin_username: str, roles: list[str], database_name: str
) -> None:
    print("---- Configuring roles")
    for role in roles:
        configure_role(conn, admin_username, role, database_name)


def configure_role(
    conn: Connection, admin_username: str, username: str, database_name: str
) -> None:
    print(f"------ Configuring role: {username=}")

    create_principal(conn, username)
    user_grants(conn, username, database_name)

    # ensure the admin user can become any created role
    db.execute(conn, f"GRANT {identifier(username)} TO {identifier(admin_username)}")


def create_principal(conn: Connection, username: str) -> None:
    """Create user for Microsoft Entra identity.

    This needs to be run against the `postgres` database.
    """
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users#create-a-userrole-using-microsoft-entra-principal-name
    #
    # pg_catalog.pgaadauth_create_principal(roleName text, isAdmin boolean, isMfa boolean)
    db.execute(
        conn,
        f"""
        DO $$
        BEGIN
            PERFORM pg_catalog.pgaadauth_create_principal({literal(username)}, false, false);
            EXCEPTION WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'user already exists';
        END
        $$;
        """,
    )


def user_grants(
    conn: Connection, username: str, database_name: str, roles: list[str] | None = None
) -> None:
    if roles:
        for role in roles:
            db.execute(conn, f"GRANT {identifier(role)} TO {identifier(username)}")

    db.execute(
        conn,
        f"GRANT CONNECT ON DATABASE {identifier(database_name)} TO {identifier(username)}",
    )


def configure_pg_role(conn: Connection, username: str, database_name: str) -> None:
    print(f"------ Configuring role: {username=}")
    create_pg_user(conn, username)
    user_grants(conn, username, database_name, ["rds_iam"])


def create_pg_user(conn: Connection, username: str) -> None:
    db.execute(
        conn,
        f"""
        DO $$
        BEGIN
            CREATE USER {identifier(username)};
            EXCEPTION WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'user already exists';
        END
        $$;
        """,
    )


def configure_schema(
    conn: Connection, schema_name: str, migrator_username: str, app_username: str
) -> None:
    print("---- Configuring schema")
    print(f"------ Creating schema: {schema_name=}")
    db.execute(conn, f"CREATE SCHEMA IF NOT EXISTS {identifier(schema_name)}")
    print(f"------ Changing schema owner: new_owner={migrator_username}")
    db.execute(
        conn,
        f"ALTER SCHEMA {identifier(schema_name)} OWNER TO {identifier(migrator_username)}",
    )
    print(f"------ Granting schema usage privileges: grantee={app_username}")
    db.execute(
        conn,
        f"GRANT USAGE ON SCHEMA {identifier(schema_name)} TO {identifier(app_username)}",
    )


def configure_default_privileges():
    """
    Configure default privileges so that future tables, sequences, and routines
    created by the migrator user can be accessed by the app user.
    You can only alter default privileges for the current role, so we need to
    run these SQL queries as the migrator user rather than as the master user.
    """
    migrator_username = os.environ.get("MIGRATOR_USER")
    schema_name = os.environ.get("DB_SCHEMA")
    app_username = os.environ.get("APP_USER")
    with db.connect_using_iam(migrator_username) as conn:
        print(
            f"------ Granting privileges for future objects in schema: grantee={app_username}"
        )
        db.execute(
            conn,
            f"ALTER DEFAULT PRIVILEGES IN SCHEMA {identifier(schema_name)} GRANT ALL ON TABLES TO {identifier(app_username)}",
        )
        db.execute(
            conn,
            f"ALTER DEFAULT PRIVILEGES IN SCHEMA {identifier(schema_name)} GRANT ALL ON SEQUENCES TO {identifier(app_username)}",
        )
        db.execute(
            conn,
            f"ALTER DEFAULT PRIVILEGES IN SCHEMA {identifier(schema_name)} GRANT ALL ON ROUTINES TO {identifier(app_username)}",
        )


def print_current_db_config(
    conn: Connection, isRootDb: bool = False
) -> tuple[list[str], list[tuple[str, str]]]:
    print("-- Current database configuration")
    roles = get_roles(conn)
    if isRootDb:
        roles.extend(map(str, get_entra_principals(conn)))
    print_roles(roles)
    schema_privileges = get_schema_privileges(conn)
    print_schema_privileges(schema_privileges)
    return roles, schema_privileges


def print_roles(roles: list[str]) -> None:
    print("---- Roles")
    for role in roles:
        print(f"------ Role {role}")


def print_schema_privileges(schema_privileges: list[tuple[str, str]]) -> None:
    print("---- Schema privileges")
    for name, acl in schema_privileges:
        print(f"------ Schema {name=} {acl=}")


# https://learn.microsoft.com/en-us/azure/postgresql/extensions/concepts-extensions-by-engine?pivots=postgresql-16
#
# Some extensions require the `shared_preload_libraries` server param is configured correctly as well:
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/server-parameters-table-client-connection-defaults-shared-library-preloading?pivots=postgresql-16
def configure_superuser_extensions(conn: Connection, superuser_extensions: dict):
    print("---- Configuring superuser extensions")
    for extension, should_be_enabled in superuser_extensions.items():
        if should_be_enabled:
            print(f"------ Enabling {extension} extension")
            db.execute(
                conn,
                f"CREATE EXTENSION IF NOT EXISTS {identifier(extension)} SCHEMA pg_catalog",
            )
        else:
            print(f"------ Disabling or skipping {extension} extension")
            db.execute(conn, f"DROP EXTENSION IF EXISTS {identifier(extension)}")
