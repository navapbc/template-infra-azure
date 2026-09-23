import os

from pg8000.native import Connection

from role_manager.providers import Provider, get_provider
from role_manager.sql import execute

__all__ = [
    "connect_as_admin_user",
    "connect_as_admin_user_to_root_db",
    "connect_using_iam",
    "execute",
    "get_db_auth_token",
]


def connect_as_admin_user_to_root_db(provider: Provider | None = None) -> Connection:
    return connect_as_admin_user(db_name="postgres", provider=provider)


def connect_as_admin_user(
    db_name: str | None = None, provider: Provider | None = None
) -> Connection:
    admin_username = os.environ["ADMIN_USER"]
    return connect_using_iam(admin_username, db_name=db_name, provider=provider)


def connect_using_iam(
    user: str, db_name: str | None = None, provider: Provider | None = None
) -> Connection:
    host = os.environ["DB_HOST"]
    port = os.environ["DB_PORT"]
    database = db_name or os.environ["DB_NAME"]

    token = get_db_auth_token(provider)

    print(f"Connecting to database: {user=} {host=} {port=} {database=}")
    return Connection(
        user=user,
        host=host,
        port=port,
        database=database,
        password=token,
        ssl_context=True,
    )


def get_db_auth_token(provider: Provider | None = None) -> str:
    return (provider or get_provider()).get_auth_token()
