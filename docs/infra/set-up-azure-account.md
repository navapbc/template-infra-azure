# Set up Azure account

Note the more correct term for "Azure account" is "Azure Subscription", the docs
and the code mix them in various places, but generally mean the same thing.

The Azure account setup process will:

1. Create the [Terraform
   backend](https://developer.hashicorp.com/terraform/language/backend)
   resources needed to store Terraform's infrastructure state files.
1. Create the OpenID connect provider in the Microsoft Entra ID Tenant to allow
   GitHub Actions to access Azure Subscription resources. Assigning it various
   admin roles.
1. Create an Azure Container Registry for the project (if the account is the
   shared resources account).

## Prerequisites

* You'll need to have [set up infrastructure
  tools](./set-up-infrastructure-tools.md), like Terraform, Azure CLI, and Azure
  authentication.
<!-- markdown-link-check-disable-next-line -->
* You'll also need to make sure the [project is
  configured](/infra/project-config/main.tf).
  * You will ultimately want to set an `infra_admins` entry for the given
    account name, but you can do that after initial creation. Note only the
    person who runs the initial create will be able to run the update.

## Instructions

### 1. Make sure you're authenticated for the Azure account you want to configure

By default the account set up sets up whatever account is your default in the
Azure CLI session. To see which account that is, run:

```bash
az account show
```

You can specify a different account ID for set up if you wish, as discussed in
the next section.

To see a list of accounts your currently authenticated user has access too, run:

```bash
az account list
```

### 2. Create backend resources and tfbackend config file

Run the following command, replacing `<ACCOUNT_NAME>` with a human readable name
for the Azure account that you're authenticated into. The account name will be
used to prefix the created tfbackend file so that it's easier to visually
identify as opposed to identifying the file using the account id. For example,
you have an account per environment, the account name can be the name of the
environment (e.g. "prod" or "staging"). Or if you are setting up an account for
all lower environments, account name can be "lowers".

```bash
make infra-set-up-account ACCOUNT_NAME=<ACCOUNT_NAME>
```

If your current Azure CLI session is not against the desired account, you can
set the account ID explicitly with an addition argument, like:

```bash
make infra-set-up-account ACCOUNT_NAME=<ACCOUNT_NAME> args="<SUBSCRIPTION_ID>"
```

This command will create the storage account and the GitHub OIDC provider. It
will also create a `[account name].[account id].azurerm.tfbackend` file in the
`infra/accounts` directory.

### 3. Copy GitHub OIDC IDs to config

Retrieve the created GitHub OIDC info needed for CI/CD with:

```bash
terraform -chdir=infra/accounts output github_oidc
```

And copy those to an entry for the new `<ACCOUNT NAME>` to the
`github_actions_azure_config` object in `/infra/project-config/main.tf`

So if the terraform output is:

```
{
  "client_id" = "88759704-2f3b-4804-87e0-eff82f2f50a4"
  "object_id" = "7724a67d-6f47-4e6a-ba71-3a08b7fc1717"
}
```


Then in the project config it should look like:

```terraform
  github_actions_azure_config = {
    # ...other account blocks

    <ACCOUNT_NAME> : {
      client_id : "88759704-2f3b-4804-87e0-eff82f2f50a4"
      object_id : "7724a67d-6f47-4e6a-ba71-3a08b7fc1717"
    },
  }
```

### 4. Update "infra_admins"

By default, the account that runs creates the Terraform resources will be marked
as the only "owner". This is most relevant to Microsoft Entra resources. In a
team environment this is not a good practice. Add/remove team member's IDs here
as they onboard/offboard. Or create a shared account to assign here.

It's also important to assign the GitHub actions principal as an owner. This
simplifies CI/CD permissions, otherwise need to request Microsoft Entra "write"
permissions to all groups in an Tenant, etc.

Something like:

```terraform
  infra_admins = {
    <ACCOUNT_NAME> : {
      object_ids : [
        "18142116-817f-46a4-92c4-486ba97b8859",             # foo@acme.onmicrosoft.com
        local.github_actions_azure_config["<ACCOUNT_NAME>"].object_id, # GH Actions Service Principal/Enterprise Application
      ]
    },
  }
```

### 5. Approve GitHub identity Entra permissions

The created GitHub identity will be setup with permissions in the Azure account
automatically, but it additionally needs permissions at the Microsoft Entra
tenant level which will require elevated permissions to approval for initial
setup of the account.

Specifically a user with "Global Administrator" or "Privileged Role
Administrator" role will need to grant admin consent to the Entra registered
application that the service principal is connected to.

In the Azure Portal or Entra admin center, this user should go to:

<App registration page for app> > Manage > API Permissions

The registration page for the app can be found by searching `<project
name>-<account name>-github-oidc`, but as display names are not unique in Entra,
it's better to search via an ID, like the application/client ID.

There should be a "Grant admin consent for <org name>" button at the top of the
table. The user should click it.

Alternatively, the global admin could use the [Azure CLI to grant the
permission](https://learn.microsoft.com/en-us/cli/azure/ad/app/permission?view=azure-cli-latest#az-ad-app-permission-admin-consent):

```bash
az ad app permission admin-consent --id <app id>
```

Or if developers themselves will have an elevated account, and if all account
runs will be with the elevated permissions uncomment the
`azuread_app_role_assignment` block in
`/infra/modules/auth-github-actions/main.tf`.

## Making changes to the account

If you make changes to the account terraform and want to apply those changes,
run:

```bash
make infra-update-current-account
```

## Destroying infrastructure

To undeploy and destroy infrastructure, see [instructions on destroying infrastructure](./destroy-infrastructure.md).
