import logging
import os

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

logger = logging.getLogger(__name__)

_blob_service_client = None


def _get_blob_service_client():
    global _blob_service_client
    if _blob_service_client is None:
        account_name = os.environ["AZURE_STORAGE_ACCOUNT_NAME"]
        account_url = f"https://{account_name}.blob.core.windows.net"
        credential = DefaultAzureCredential()
        _blob_service_client = BlobServiceClient(account_url, credential=credential)
    return _blob_service_client


def _get_container_name():
    return os.environ.get("AZURE_STORAGE_CONTAINER_NAME", "documents")


def create_upload_url(path):
    """Return the local upload endpoint for server-side upload."""
    return "/document-upload", {}


def download_file(path):
    """Download a blob and return its content as bytes."""
    client = _get_blob_service_client()
    blob_client = client.get_blob_client(container=_get_container_name(), blob=path)
    return blob_client.download_blob().readall()


def upload_file(path, data):
    """Upload data to a blob at the given path."""
    client = _get_blob_service_client()
    blob_client = client.get_blob_client(container=_get_container_name(), blob=path)
    blob_client.upload_blob(data, overwrite=True)
