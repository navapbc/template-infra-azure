import logging
import os

from azure.identity import DefaultAzureCredential
import psycopg
import psycopg.conninfo

logger = logging.getLogger()


def get_db_connection():
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    user = os.environ.get("DB_USER")
    password = get_db_auth_token()
    dbname = os.environ.get("DB_NAME")

    conninfo = psycopg.conninfo.make_conninfo(
        host=host, port=port, user=user, password=password, dbname=dbname
    )

    conn = psycopg.connect(conninfo)
    return conn


def get_db_auth_token() -> str:
    # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/connect-python?tabs=cmd%2Cpasswordless
    # https://pypi.org/project/azure-identity/
    credential = DefaultAzureCredential()
    token = credential.get_token(
        "https://ossrdbms-aad.database.windows.net/.default"
    ).token

    return token
