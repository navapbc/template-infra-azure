"""Proves manage.py drives role configuration through the provider seam.

The point of the refactor is that a second provider (AWS) can be added
without editing manage.py. These tests substitute a fake provider whose
behaviour differs from Azure's on every axis the protocol covers, and assert
manage.py honours it.
"""

from role_manager import manage


class FakeAwsProvider:
    """Stands in for a future AWS implementation.

    Differs from Azure deliberately: creates principals in the application
    database, and requires the rds_iam role grant.
    """

    name = "fake-aws"
    creates_principals_in_root_db = False

    def __init__(self):
        self.created_principals: list[str] = []

    def get_auth_token(self) -> str:
        return "fake-token"

    def create_principal(self, conn, username: str) -> None:
        self.created_principals.append(username)

    def get_managed_principals(self, conn) -> list[list[str]]:
        return []

    def grant_roles_for_principal(self, username: str) -> list[str]:
        return ["rds_iam"]


class RecordingConnection:
    """Minimal pg8000-shaped connection that records statements."""

    def __init__(self, user: str = "admin"):
        self.user = user.encode("utf-8")
        self.statements: list[str] = []

    def run(self, query: str):
        self.statements.append(query)
        return []


def test_configure_role_uses_provider_to_create_principal():
    provider = FakeAwsProvider()
    conn = RecordingConnection()

    manage.configure_role(conn, "admin", "app_user", "appdb", provider)

    # The provider created the principal, not hardcoded Azure SQL.
    assert provider.created_principals == ["app_user"]
    assert not any("pgaadauth" in s for s in conn.statements)


def test_configure_role_applies_provider_required_role_grants():
    provider = FakeAwsProvider()
    conn = RecordingConnection()

    manage.configure_role(conn, "admin", "app_user", "appdb", provider)

    # rds_iam comes from the provider, and Azure would contribute none.
    assert any("rds_iam" in s for s in conn.statements)


def test_azure_contributes_no_role_grant():
    from role_manager.providers import AzureProvider

    # create_principal would need a live Entra-enabled server, so only the
    # grant behaviour is exercised here.
    assert AzureProvider().grant_roles_for_principal("app_user") == []


def test_admin_can_assume_every_configured_role():
    provider = FakeAwsProvider()
    conn = RecordingConnection()

    manage.configure_role(conn, "admin", "app_user", "appdb", provider)

    assert any(
        "GRANT" in s and "app_user" in s and "admin" in s for s in conn.statements
    )


class _ListingProvider(FakeAwsProvider):
    """Returns a distinguishable principal so the assertions cannot be vacuous."""

    def get_managed_principals(self, conn) -> list[list[str]]:
        return [["managed-principal"]]


def test_managed_principals_are_listed_when_requested():
    roles, _ = manage.print_current_db_config(
        RecordingConnection(), _ListingProvider(), include_managed_principals=True
    )

    assert any("managed-principal" in r for r in roles)


def test_managed_principals_are_omitted_by_default():
    roles, _ = manage.print_current_db_config(RecordingConnection(), _ListingProvider())

    assert not any("managed-principal" in r for r in roles)


def test_non_root_db_provider_uses_a_single_connection(monkeypatch):
    """A provider that creates principals in the app database should not open
    the same connection twice: that mints a second auth token and splits role
    creation from schema configuration across two sessions."""
    import role_manager.manage as manage_mod

    opened: list[str] = []

    class _Conn(RecordingConnection):
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

    def fake_connect_as_admin_user(db_name=None, provider=None):
        opened.append(db_name or "appdb")
        return _Conn()

    def fake_connect_root(provider=None):
        opened.append("postgres")
        return _Conn()

    monkeypatch.setattr(
        manage_mod.db, "connect_as_admin_user", fake_connect_as_admin_user
    )
    monkeypatch.setattr(
        manage_mod.db, "connect_as_admin_user_to_root_db", fake_connect_root
    )
    monkeypatch.setattr(manage_mod, "configure_database", lambda *a, **k: None)
    monkeypatch.setattr(manage_mod, "get_roles_with_groups", lambda conn: {})
    monkeypatch.setattr(
        manage_mod, "configure_default_privileges", lambda provider: None
    )
    for var in ["ADMIN_USER", "APP_USER", "MIGRATOR_USER", "DB_NAME"]:
        monkeypatch.setenv(var, "x")

    manage_mod.manage(provider=FakeAwsProvider())

    assert opened == ["appdb"], f"expected one connection, got {opened}"


def test_root_db_provider_uses_two_connections(monkeypatch):
    """Azure-style providers still need the root database for principals."""
    import role_manager.manage as manage_mod

    opened: list[str] = []

    class _Conn(RecordingConnection):
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

    class _RootProvider(FakeAwsProvider):
        creates_principals_in_root_db = True

    monkeypatch.setattr(
        manage_mod.db,
        "connect_as_admin_user",
        lambda db_name=None, provider=None: (opened.append("appdb"), _Conn())[1],
    )
    monkeypatch.setattr(
        manage_mod.db,
        "connect_as_admin_user_to_root_db",
        lambda provider=None: (opened.append("postgres"), _Conn())[1],
    )
    monkeypatch.setattr(manage_mod, "configure_database", lambda *a, **k: None)
    monkeypatch.setattr(manage_mod, "get_roles_with_groups", lambda conn: {})
    monkeypatch.setattr(
        manage_mod, "configure_default_privileges", lambda provider: None
    )
    for var in ["ADMIN_USER", "APP_USER", "MIGRATOR_USER", "DB_NAME"]:
        monkeypatch.setenv(var, "x")

    manage_mod.manage(provider=_RootProvider())

    assert opened == ["postgres", "appdb"], f"expected root then app, got {opened}"
