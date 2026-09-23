"""Tests for the cloud provider abstraction.

These exercise the seam that lets an AWS implementation drop in alongside
Azure: that provider selection works, that the protocol is satisfied, and
that manage.py routes through the provider rather than hardcoding Azure.
"""

import pytest

from role_manager.providers import AzureProvider, Provider, get_provider


def test_defaults_to_azure_when_unset(monkeypatch):
    monkeypatch.delenv("CLOUD_PROVIDER", raising=False)
    assert isinstance(get_provider(), AzureProvider)


def test_reads_cloud_provider_env_var(monkeypatch):
    monkeypatch.setenv("CLOUD_PROVIDER", "azure")
    assert isinstance(get_provider(), AzureProvider)


def test_provider_name_is_case_insensitive(monkeypatch):
    monkeypatch.setenv("CLOUD_PROVIDER", "AZURE")
    assert isinstance(get_provider(), AzureProvider)


def test_explicit_argument_beats_env_var(monkeypatch):
    monkeypatch.setenv("CLOUD_PROVIDER", "azure")
    assert isinstance(get_provider("azure"), AzureProvider)


def test_unsupported_provider_raises_with_supported_list(monkeypatch):
    monkeypatch.delenv("CLOUD_PROVIDER", raising=False)
    with pytest.raises(ValueError, match="Unsupported cloud provider 'gcp'"):
        get_provider("gcp")


def test_azure_satisfies_provider_protocol():
    assert isinstance(AzureProvider(), Provider)


def test_azure_creates_principals_in_root_db():
    # Entra users must be created in the `postgres` database.
    # https://github.com/Azure/azure-postgresql/issues/117
    assert AzureProvider().creates_principals_in_root_db is True


def test_azure_needs_no_extra_role_grants():
    # Contrast with AWS, which requires rds_iam.
    assert AzureProvider().grant_roles_for_principal("someuser") == []
