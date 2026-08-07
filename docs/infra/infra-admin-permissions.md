# Infra Admin Permissions

In order to run terraform, including initial Azure Subscription set up, your
account needs various roles assigned in the appropriate Microsoft Entra ID
tenant. There are alternate permission setups possible, but this is what has
been tested.

## Option 1 — Broad Access (Tested)

Scoped to relevant Subscription(s), without conditions limiting their
application:
- Owner
- Key Vault Administrator
- Role Based Access Control Administrator
- Storage Blob Data Contributor

Scoped to the Microsoft Entra ID tenant itself:
- Cloud Application Administrator, to register the GitHub Actions identity. This
  requirement could be removed by future work[1].

## Option 2 — Least-Privilege with ABAC Conditions

For a more security-conscious setup, the `Owner` and `Role Based Access Control
Administrator` roles can be granted with an **ABAC condition** that restricts
which roles the admin can assign to others.

Scoped to relevant Subscription(s), with an ABAC condition limiting role
assignment to only the roles Terraform requires:
- Owner *(with ABAC condition, see below)*
- Key Vault Administrator
- Role Based Access Control Administrator *(with ABAC condition, see below)*
- Storage Blob Data Contributor

Scoped to the Microsoft Entra ID tenant itself:
- Cloud Application Administrator, to register the GitHub Actions identity. This
  requirement could be removed by future work[1].

### Required ABAC Condition

The ABAC condition must allow assigning only the following roles to service
principals and managed identities:

| Role | GUID |
|---|---|
| `Contributor` | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| `Key Vault Secrets Officer` | `b86a8fe4-44ce-4948-aee5-eccb2c155cd7` |
| `Key Vault Certificates Officer` | `a4417e6f-fecd-4de8-b567-7b0420556985` |
| `Role Based Access Control Administrator` | `f58310d9-a9f6-439a-9e8d-f62e7b41a168` |
| `Storage Blob Data Contributor` | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` |
| `AcrPull` | `7f951dda-4ed3-4680-a7ca-43fe172d538d` |
| `Key Vault Secrets User` | `4633458b-17de-408a-b874-0445c86b69e6` |
| `Key Vault Crypto Service Encryption User` | `e147488a-f6f5-4113-8e2d-b22465e65bf6` |

To configure the condition in the Azure Portal:
> Subscriptions → \<your subscription\> → IAM → Role assignments → find the
> admin's Owner entry → **Edit condition** → add the role GUIDs above to the
> allowed list.

### Important: ABAC Condition Must Include All Required Roles

If the ABAC condition is more restrictive than the list above, Terraform will
fail with a `403 AuthorizationFailed` error during `make infra-set-up-account`.
In that case, a user with an **unconditional Owner** must either:

- Pre-assign the missing roles to the GitHub Actions service principal manually
  before running Terraform:

  ```bash
  SP_OBJECT_ID="<github-actions-service-principal-object-id>"
  SCOPE="/subscriptions/<subscription-id>"

  for ROLE in \
    "Contributor" \
    "Key Vault Secrets Officer" \
    "Key Vault Certificates Officer" \
    "Role Based Access Control Administrator" \
    "Storage Blob Data Contributor"; do
    az role assignment create \
      --role "$ROLE" \
      --assignee "$SP_OBJECT_ID" \
      --scope "$SCOPE"
  done
  ```

- Or broaden the ABAC condition to include all roles in the table above.

[1]: https://github.com/navapbc/template-infra-azure/issues/17.
