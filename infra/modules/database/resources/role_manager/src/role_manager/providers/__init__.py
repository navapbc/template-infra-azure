"""Cloud-provider-specific database logic.

Everything the role manager does is portable Postgres except for four things,
which differ between Azure and AWS:

  1. how an auth token is obtained,
  2. how a principal (database user) is created,
  3. how existing managed-identity principals are listed,
  4. whether roles must be created against the `postgres` root database.

Those four are captured by the Provider protocol in `base.py`. The rest of the
role manager is written against that protocol, so adding AWS support means
adding a module here -- not touching manage.py or check.py.
"""

import os

from role_manager.providers.azure import AzureProvider
from role_manager.providers.base import Provider

_PROVIDERS: dict[str, type[Provider]] = {
    "azure": AzureProvider,
}


def get_provider(name: str | None = None) -> Provider:
    """Return the provider implementation for `name`.

    Defaults to the CLOUD_PROVIDER environment variable, then to "azure" so
    that existing Azure deployments keep working without config changes.
    """
    # Strip before testing for emptiness: Terraform emits "" for an unset
    # variable, and a trailing newline is easy to introduce in a shell export.
    # Both should fall back to the default rather than fail obscurely later.
    provider_name = (name or os.environ.get("CLOUD_PROVIDER") or "").strip().lower()
    provider_name = provider_name or "azure"

    if provider_name not in _PROVIDERS:
        supported = ", ".join(sorted(_PROVIDERS))
        raise ValueError(
            f"Unsupported cloud provider {provider_name!r}. Supported: {supported}"
        )

    return _PROVIDERS[provider_name]()


__all__ = ["AzureProvider", "Provider", "get_provider"]
