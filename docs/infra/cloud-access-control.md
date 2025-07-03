# Cloud Access Control

GitHub Actions needs permissions to create, modify, and destroy resources in the
cloud account as part of the CI/CD workflows. In the current Azure setup, the
GitHub Actions account is given broad access to Subscription resources, as
listed in `subscription_roles` variable in
`infra/modules/auth-github-actions/main.tf`.
