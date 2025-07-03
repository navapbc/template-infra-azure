# Set up GitHub

With current restrictions for how OIDC authentication works with Azure, some
tweaks are needed at the GitHub repository level to allow CI/CD to work as
expected.

## Prerequisites

* Generally you'll need to have [set up infrastructure
  tools](./set-up-infrastructure-tools.md), but only strict dependency is the
  GitHub CLI.
* You have created a project repository on GitHub
* You are an admin for the project's GitHub repository

## Instructions

Run:
```bash
project-root$ ./bin/set-up-github
```

