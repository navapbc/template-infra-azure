# Set up infrastructure developer tools

If you are contributing to infrastructure, you will need to complete these setup steps.

## Prerequisites

### Install Terraform

[Terraform](https://www.terraform.io/) is an infrastructure as code (IaC) tool
that allows you to build, change, and version infrastructure safely and
efficiently. This includes both low-level components like compute instances,
storage, and networking, as well as high-level components like DNS entries and
SaaS features.

You may need different versions of Terraform since different projects may
require different versions of Terraform. The best way to manage Terraform
versions is with [Terraform Version Manager](https://github.com/tfutils/tfenv).

To install via [Homebrew](https://brew.sh/)

```bash
brew install tfenv
```

Then install the version of Terraform you need.

```bash
tfenv install 1.4.6
```

### Install Azure CLI

The [Azure Command-Line Interface (Azure
CLI)](https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) is a
cross-platform command-line tool for managing Azure resources with interactive
commands or scripts. Install the Azure command line tool by following the
instructions found here:

- [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

If you are using macOS:

```bash
brew install azure-cli
```

### Install Go

The [Go programming language](https://go.dev/dl/) is required to run
[Terratest](https://terratest.gruntwork.io/), the unit test framework for
Terraform.

### Install GitHub CLI

The [GitHub CLI](https://cli.github.com/) is useful for automating certain
operations for GitHub such as with GitHub actions. This is needed to run
[check-github-actions-auth](/bin/check-github-actions-auth)

```bash
brew install gh
```

### Install misc. script tools

Some scripts require various other CLI tools, which you may or may not encounter
during regular operations.

```bash
brew install jq
```

### Install linters

We have several optional utilities for running infrastructure linters locally.
These are run as part of the CI pipeline, therefore, it is often simpler to test
them locally first.

* [Shellcheck](https://github.com/koalaman/shellcheck)
* [actionlint](https://github.com/rhysd/actionlint)
* [markdown-link-check](https://github.com/tcort/markdown-link-check)

```bash
brew install shellcheck
brew install actionlint
make infra-lint
```

## Azure Authentication

In order for Terraform to authenticate with your accounts you will need to
configure your Azure credentials using the Azure CLI.

For a single project, the simplest approach is to just run:

```bash
az login
```

And login with the appropriate user.

If you are juggling multiple projects with different tenants, you could set the
`AZURE_TENANT_ID` environment variable in your local environment for each
project, like with [direnv](https://direnv.net/). Then continue to just `az
login` each time you switch projects.

If you are running multiple projects in different Azure clouds, you may want to
look at setting up multiple configuration directories tailored to each project,
and setting the `AZURE_CONFIG_DIR` in your local environment for each project.
