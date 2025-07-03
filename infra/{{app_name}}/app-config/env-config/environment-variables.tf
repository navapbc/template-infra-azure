locals {
  # Map from environment variable name to environment variable value
  # This is a map rather than a list so that variables can be easily
  # overridden per environment using terraform's `merge` function
  default_extra_environment_variables = {
    # Example environment variables
    # WORKER_THREADS_COUNT    = 4
    # LOG_LEVEL               = "info"
    # DB_CONNECTION_POOL_SIZE = 5
  }

  # Configuration for secrets
  # List of configurations for defining environment variables that pull from Azure Key Vault
  # Configurations are of the format
  # {
  #   ENV_VAR_NAME = {
  #     secret_name = "key-vault-secret-name"
  #   }
  # }
  secrets = {
    SECRET_SAUCE = {
      manage_method = "manual"
      secret_name   = "secret-sauce"
    },
    RANDOM_SECRET = {
      manage_method = "generated"
      secret_name   = "random-secret"
    },
  }
}
