# Destroy infrastructure

To destroy everything you'll need to undeploy all the infrastructure in reverse
order that they were created. In particular, the account root module(s) need to
be destroyed last.

## Instructions

1. First, destroy all your environments. Within `/infra/app/service` run the
   following, replacing `dev` with the environment you're destroying.

   ```bash
   $ terraform init --backend-config=dev.s3.tfbackend
   $ terraform destroy -var-file=dev.tfvars
   ```
1. Then the same for `/infra/app/database` and all networks.
1. Then since we're going to be destroying the tfstate buckets, you'll want to
   move the tfstate file out of S3 and back to your local system. Comment out or
   delete the azurerm backend configuration:

   ```terraform
   # infra/accounts/main.tf

   # Comment out or delete the backend block
   backend "azurerm" {
     ...
   }
   ```

1. Then run the following from within the `infra/accounts` directory to copy the
   `tfstate` back to a local `tfstate` file:

   ```bash
   terraform init -force-copy
   ```

1. Finally, you can run `terraform destroy` within the `infra/accounts` directory.

   ```bash
   terraform destroy
   ```
