from typing import Any, Protocol, runtime_checkable

from pg8000.native import Connection


@runtime_checkable
class Provider(Protocol):
    """The cloud-specific parts of database role management.

    Implementations supply credential handling and principal creation. All
    other role-manager behaviour -- schemas, grants, default privileges,
    checks -- is portable Postgres and lives outside this protocol.
    """

    #: Human-readable name, used in log output.
    name: str

    #: Whether principals must be created against the `postgres` root database
    #: rather than the application database. Azure requires this for Entra
    #: users; AWS does not.
    creates_principals_in_root_db: bool

    def get_auth_token(self) -> str:
        """Return a short-lived token used as the database password."""
        ...

    def create_principal(self, conn: Connection, username: str) -> None:
        """Create a database user backed by a cloud managed identity.

        Must be idempotent: re-running against an existing user is a no-op.
        """
        ...

    def get_managed_principals(self, conn: Connection) -> list[list[Any]]:
        """List principals the cloud identity provider knows about.

        Rows are whatever the provider's catalog returns and may mix types --
        Azure's pgaadauth_list_principals includes boolean and OID columns
        alongside the name. Used for diagnostic output only, so callers should
        stringify rather than index into them. Returns an empty list where the
        provider exposes no equivalent concept.
        """
        ...

    def grant_roles_for_principal(self, username: str) -> list[str]:
        """Roles that must be granted to every managed principal.

        AWS requires `rds_iam` for IAM authentication; Azure requires nothing.
        """
        ...
