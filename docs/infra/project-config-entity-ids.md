# Project Config Entity Ids

There are properties in `/infra/project-config/main.tf` which are basically
lists of users that must be manually specified and maintained for different
purposes:

- `github_actions_azure_config`
- `infra_admins`

This doc provides some further explanation for why they exist, which is for
primarily two reasons.

## For GitHub to understand how to connect to Azure

`github_actions_azure_config` (the `client_id` part at least) exists because in
order to authenticate the GH Action runner with Azure, to be able to read the
terraform state/do anything in Azure, it needs a client ID to request a token
with (using `/.github/actions/configure-azure-credentials/action.yml`). So this
client ID has to be available somewhere outside of the terraform state. It
currently lives in the project config because we currently set up a GH Action
user in Azure for each Subscription and so there isn't a single client ID to set
as a repository secret. Rather than embed a JSON object in an environment
variable/multiple env vars or require setting up multiple GitHub environments,
it was easier/quicker to just track it as configuration.

## To streamline permissions

`infra_admins` (and the `object_id` part of `github_actions_azure_config`)
exists to be able to assign ownership to resources, primarily Microsoft Entra
resources, to mainly enable the GH Actions user to be able to deploy/operate on
those resources without additional elevated permissions in Microsoft Entra
(e.g., since the GH Actions user is an owner of the DB access group, it can
assign service users to it directly, instead of needing to have write access to
all groups in Entra/its assigned Entra admin group). But also in general it is
best practice to assign multiple owners to resources in Azure, and this
facilitates that.


./infra-admin-permissions.md
~/projects/template-infra-azure/docs/infra/cloud-access-control.md
~/projects/template-infra-azure/docs/infra/database-access-control.md

./infrastructure-configuration.md

~/projects/template-infra-azure/docs/infra/set-up-azure-account.md

https://github.com/navapbc/template-infra-azure/issues/16
