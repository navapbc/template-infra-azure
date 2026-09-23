from typing import Any

from azure.identity import DefaultAzureCredential
from pg8000.native import Connection, literal

from role_manager import sql


class AzureProvider:
    """Microsoft Entra ID (formerly Azure AD) authentication for Postgres."""

    name = "azure"

    # Entra users must be created in the `postgres` database.
    # https://github.com/Azure/azure-postgresql/issues/117
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users
    creates_principals_in_root_db = True

    def get_auth_token(self) -> str:
        # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/connect-python?tabs=cmd%2Cpasswordless
        # https://pypi.org/project/azure-identity/
        credential = DefaultAzureCredential()
        return credential.get_token(
            "https://ossrdbms-aad.database.windows.net/.default"
        ).token

    def create_principal(self, conn: Connection, username: str) -> None:
        """Create a user for a Microsoft Entra identity.

        This needs to be run against the `postgres` database.
        """
        # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users#create-a-userrole-using-microsoft-entra-principal-name
        #
        # pg_catalog.pgaadauth_create_principal(roleName text, isAdmin boolean, isMfa boolean)
        sql.execute(
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

    def get_managed_principals(self, conn: Connection) -> list[list[Any]]:
        # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-azure-ad-users#list-microsoft-entra-roles-using-sql
        #
        # pg_catalog.pgaadauth_list_principals(isAdminValue boolean)
        return list(
            sql.execute(
                conn,
                """
                SELECT *
                FROM pg_catalog.pgaadauth_list_principals(true)
                """,
                print_query=False,
            )
        )

    def grant_roles_for_principal(self, username: str) -> list[str]:
        # Entra principals need no additional role grant; membership is
        # conferred by pgaadauth_create_principal.
        return []
