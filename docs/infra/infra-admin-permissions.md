# Infra Admin Permissions

In order to run terraform, including initial Azure Subscription set up, your
account needs various roles assigned in the appropriate Microsoft Entra ID
tenant. There are alternate permission setups possible, but this is what has
been tested.

Scoped to relevant Subscription(s), without conditions limiting their
application:
- Owner
- Key Vault Administrator
- Role Based Access Control Administrator

Scoped to the Microsoft Entra ID tenant itself:
- Cloud Application Administrator, to register the GitHub Actions identity. This
  requirement could be removed by future work[1].

[1]: https://github.com/navapbc/template-infra-azure/issues/17.
