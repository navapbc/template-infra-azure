import os

from azure.identity import DefaultAzureCredential
from pg8000.native import Connection


def connect_as_admin_user_to_root_db() -> Connection:
    return connect_as_admin_user(db_name="postgres")


def connect_as_admin_user(db_name: str | None = None) -> Connection:
    admin_username = os.environ["ADMIN_USER"]
    return connect_using_iam(admin_username, db_name=db_name)


def connect_using_iam(user: str, db_name: str | None = None) -> Connection:
    host = os.environ["DB_HOST"]
    port = os.environ["DB_PORT"]
    database = db_name or os.environ["DB_NAME"]

    token = get_db_auth_token()

    print(f"Connecting to database: {user=} {host=} {port=} {database=}")
    return Connection(
        user=user,
        host=host,
        port=port,
        database=database,
        password=token,
        ssl_context=True,
    )


def get_db_auth_token() -> str:
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/connect-python?tabs=cmd%2Cpasswordless
    # https://pypi.org/project/azure-identity/
    credential = DefaultAzureCredential()
    token = credential.get_token(
        "https://ossrdbms-aad.database.windows.net/.default"
    ).token

    return token


def execute(conn: Connection, query: str, print_query: bool = True):
    if print_query:
        print(f"{conn.user.decode('utf-8')}> {query}")
    return conn.run(query)
