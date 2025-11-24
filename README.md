<p>
  <img src="template-only-docs/assets/Nava-Strata-Logo-V02.svg" alt="Nava Strata" width="400">
</p>
<p><i>Open source tools for every layer of government service delivery.</i></p>
<p><b>Strata is a gold-standard target architecture and suite of open-source tools that gives government agencies everything they need to run a modern service.</b></p>

<h4 align="center">
  <a href="https://github.com/navapbc/template-infra-azure/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-apache_2.0-red" alt="Nava Strata is released under the Apache 2.0 license" >
  </a>
  <a href="https://github.com/navapbc/template-infra-azure/blob/main/CONTRIBUTING.md">
    <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen" alt="PRs welcome!" />
  </a>
  <a href="https://github.com/navapbc/template-infra-azure/issues">
    <img src="https://img.shields.io/github/commit-activity/m/navapbc/template-infra-azure" alt="git commit activity" />
  </a>
  <a href="https://github.com/navapbc/template-infra-azure/repos/">
    <img alt="GitHub Downloads (all assets, all releases)" src="https://img.shields.io/github/downloads/navapbc/template-infra-azure/total">
  </a>
</h4>

# Azure infrastructure template

## Overview

This is a template repository to set up foundational infrastructure for your application in Azure. It is part of a collection of interoperable [Strata templates](https://github.com/navapbc/strata).

This template includes setup for:

- **Team workflows** - templates for pull requests (PRs), architecture decision records (ADRs), and Makefiles.
- **Account level foundational infrastructure** - infrastructure for terraform backends, including an resources for storing and managing terraform state files.
- **Application infrastructure** - the infrastructure you need to set up a basic web app, such as a image container repository, load balancer, web service, and database.
- **CI for infra** - GitHub action that performs infra code checks, including linting, validation, and security compliance checks.
- **CD / Deployments** - infrastructure for continuous deployment, including: Azure account access for Github actions, scripts for building and publishing release artifacts, and a Github action for automated deployments from the main branch.
- **Documentation** - technical documentation for the decisions that went into all the defaults that come with the template.

The system architecture will look like this (see [system architecture documentation](/docs/system-architecture.md) for more information):
![System architecture](https://lucid.app/publicSegments/view/e4eff3ce-8a40-4b41-91ca-d4c84554d5c8/image.png)

## Application Requirements

This template assumes that you have an application to deploy. See [application requirements](https://github.com/navapbc/template-infra/blob/main/template-only-docs/application-requirements.md) for more information on what is needed to use the infrastructure template. If you're using one of the [Platform application templates](https://github.com/navapbc/strata?tab=readme-ov-file#platform-templates), these requirements are already met.

## Installation

To get started, [install the nava-platform
tool](https://github.com/navapbc/platform-cli), and then run the following
command in your project's root directory:

```sh
nava-platform infra install --template-uri https://github.com/navapbc/template-infra-azure .
```

Now you're ready to set up the various pieces of your infrastructure.

## Setup

After downloading and installing the template into your project:

1. Follow the steps in [infra/README.md](/infra/README.md) to setup the infrastructure for your application.
2. After setting up Azure resources, you can [set up GitHub Actions workflows](https://github.com/navapbc/template-infra/blob/main/template-only-docs/set-up-ci.md).
3. After configuring GitHub Actions, you can [set up continuous deployment](https://github.com/navapbc/template-infra/blob/main/template-only-docs/set-up-cd.md).
4. After setting up continuous deployment, you can optionally [set up pull request environments](https://github.com/navapbc/template-infra/blob/main/template-only-docs/set-up-pr-environments.md)
5. At any point, [set up your team workflow](https://github.com/navapbc/template-infra/blob/main/template-only-docs/set-up-team-workflow.md).

## Updates

With the [nava-platform tool
installed](https://github.com/navapbc/platform-cli), run the following in your
project's root directory:

```sh
nava-platform infra update .
```

If the update fails, the tool will provide some guidance, but effectively the
next step will be apply the updates in smaller pieces with manual merge conflict
resolution.

**Remember:** Make sure to read the release notes in case there are breaking changes you need to address.

---

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.

## Community

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)
