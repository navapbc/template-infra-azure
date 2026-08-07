# Destroy infrastructure

To destroy everything you'll need to undeploy all the infrastructure in reverse
order that they were created. In particular, the account root module(s) need to
be destroyed last.

## Instructions

1. First, destroy all of your application environments. For each app and
   environment, run:

   ```bash
   TF_CLI_ARGS_apply="-destroy" make infra-update-app-service APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
   ```

1. Run similar for the all app databases (`infra-update-app-database`) and then
   all networks (`infra-update-network`).
1. Then, since we're going to be destroying the tfstate storage location, you'll
   want to move the tfstate file out of remote storage and back to your local
   system. Comment out or delete the remote backend configuration:

   ```terraform
   # infra/accounts/main.tf

   # Comment out or delete the backend block
   backend "azurerm" {
     ...
   }
   ```

1. Then run the following from within the `infra/accounts` directory to copy the
   remote `tfstate` back to a local `tfstate` file:

   ```bash
   terraform init -force-copy
   ```

1. Finally, you can run `terraform destroy` within the `infra/accounts`
   directory.

   ```bash
   TF_CLI_ARGS_apply="-destroy" make infra-update-account ACCOUNT_NAME=<ACCOUNT_NAME>
   ```
