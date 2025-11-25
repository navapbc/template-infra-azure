PROJECT_ROOT ?= $(notdir $(PWD))

# Get the list of reusable terraform modules by getting out all the directories
# containing a `main.tf` file under infra/modules.
MODULE_DIRS := $(shell find infra/modules -iname main.tf -exec dirname {} \;)
# Strip out the "infra/modules/" prefix for help page, to reduce visual noise.
MODULES := $(MODULE_DIRS:infra/modules/%=%)

CONTAINER_CMD ?= docker
export CONTAINER_CMD

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
# Based off of https://stackoverflow.com/questions/10858261/how-to-abort-makefile-if-variable-not-set
check_defined = \
	$(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))$(if $(value @), \
			required by target '$@')))


.PHONY : \
	help \
	infra-check-app-database-roles \
	infra-check-compliance-checkov \
	infra-check-compliance-tfsec \
	infra-check-compliance \
	infra-configure-app-database \
	infra-configure-app-service \
	infra-configure-monitoring-secrets \
	infra-configure-network \
	infra-format \
	infra-lint \
	infra-lint-scripts \
	infra-lint-terraform \
	infra-lint-workflows \
	infra-set-up-account \
	infra-test-service \
	infra-update-app-database-roles \
	infra-update-app-database \
	infra-update-app-service \
	infra-update-current-account \
	infra-update-network \
	infra-validate-modules \
	lint-markdown \
	release-build \
	release-deploy \
	release-image-name \
	release-image-tag \
	release-publish \
	release-run-database-migrations

infra-set-up-account: ## Configure and create resources for account and create its tfbackend file
	@:$(call check_defined, ACCOUNT_NAME, human readable name for account e.g. "prod" or the account alias)
	./bin/set-up-account $(ACCOUNT_NAME) $(args)

infra-configure-network: ## Configure network $NETWORK_NAME
	@:$(call check_defined, NETWORK_NAME, the name of the network in /infra/networks)
	./bin/create-tfbackend infra/networks $(NETWORK_NAME) $$(./bin/account-name-for-network $(NETWORK_NAME))

infra-configure-app-database: ## Configure infra/$APP_NAME/database module's tfbackend and tfvars files for $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/create-tfbackend "infra/$(APP_NAME)/database" "$(ENVIRONMENT)" $$(./bin/network-name-for-app-environment $(APP_NAME) $(ENVIRONMENT) | ./bin/account-name-for-network)

infra-configure-monitoring-secrets: ## Set $APP_NAME's incident management service integration URL for $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	@:$(call check_defined, URL, incident management service (PagerDuty or VictorOps) integration URL)
	./bin/configure-monitoring-secret $(APP_NAME) $(ENVIRONMENT) $(URL)

infra-configure-app-service: ## Configure infra/$APP_NAME/service module's tfbackend and tfvars files for $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/create-tfbackend "infra/$(APP_NAME)/service" "$(ENVIRONMENT)" $$(./bin/network-name-for-app-environment $(APP_NAME) $(ENVIRONMENT) | ./bin/account-name-for-network)

infra-update-account: ## Update infra resources for $ACCOUNT_NAME
	@:$(call check_defined, ACCOUNT_NAME, human readable name for account e.g. "prod")
	./bin/terraform-init-and-apply infra/accounts $$(./bin/account-config-name "$(ACCOUNT_NAME)")

infra-update-current-account: ## Update infra resources for primary account associated with current shell environment credentials
	./bin/terraform-init-and-apply infra/accounts $$(./bin/current-account-config-name)

infra-update-network: ## Update network
	@:$(call check_defined, NETWORK_NAME, the name of the network in /infra/networks)
	./bin/terraform-init-and-apply infra/networks $(NETWORK_NAME) -var="network_name=$(NETWORK_NAME)"

infra-update-app-database: ## Create or update $APP_NAME's database module for $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/terraform-init-and-apply infra/$(APP_NAME)/database $(ENVIRONMENT) -var="environment_name=$(ENVIRONMENT)"

infra-update-app-database-roles: ## Create or update database roles and schemas for $APP_NAME's database in $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/create-or-update-database-roles $(APP_NAME) $(ENVIRONMENT)

infra-update-app-service: ## Create or update $APP_NAME's web service module
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/terraform-init-and-apply infra/$(APP_NAME)/service $(ENVIRONMENT) -var="environment_name=$(ENVIRONMENT)"

# The prerequisite for this rule is obtained by
# prefixing each module with the string "infra-validate-module-"
infra-validate-modules: ## Run terraform validate on reusable child modules
infra-validate-modules: $(patsubst %, infra-validate-module/%, $(MODULE_DIRS))

# Running `terraform validate` against modules that have required provider
# aliases is not supported at the moment.
#
# https://github.com/hashicorp/terraform/issues/28490
#
# At time of writing OpenTofu has support, but unreleased, should be in version
# >= 1.11.0
# https://github.com/opentofu/opentofu/issues/2862
infra-validate-module/%:
	@echo "Validate library module: $*"
	grep -q "configuration_aliases" $*/* && echo 'Modules with `configuration_aliases` are not supported by `terraform validate` at the moment, skipping.' || \
	{ terraform -chdir=$* init -backend=false; terraform -chdir=$* validate; }

infra-check-app-database-roles: ## Check that app database roles have been configured properly
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "staging")
	./bin/check-database-roles $(APP_NAME) $(ENVIRONMENT)

infra-check-compliance: ## Run compliance checks
infra-check-compliance: infra-check-compliance-checkov infra-check-compliance-tfsec

infra-check-compliance-checkov: ## Run checkov compliance checks
	checkov --directory infra

infra-check-compliance-tfsec: ## Run tfsec compliance checks
	tfsec infra

infra-lint: ## Lint infra code
infra-lint: lint-markdown infra-lint-scripts infra-lint-terraform infra-lint-workflows

infra-lint-scripts: ## Lint shell scripts
	shellcheck bin/**

infra-lint-terraform: ## Lint Terraform code
	terraform fmt -recursive -check infra

infra-lint-workflows: ## Lint GitHub actions
	actionlint

infra-format: ## Format infra code
	terraform fmt -recursive infra

infra-test-service: ## Run service layer infra test suite
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	cd infra/test && APP_NAME=$(APP_NAME) IMAGE_TAG=$(IMAGE_TAG) go test -run TestService -v -timeout 30m

lint-markdown: ## Lint Markdown docs for broken links
	./bin/lint-markdown

########################
## Release Management ##
########################

# Include project name in image name so that image name
# does not conflict with other images during local development
IMAGE_NAME := $(PROJECT_ROOT)-$(APP_NAME)

GIT_REPO_AVAILABLE := $(shell git rev-parse --is-inside-work-tree 2>/dev/null)

# Generate a unique tag based solely on the git hash.
# This will be the identifier used for deployment via terraform.
ifdef GIT_REPO_AVAILABLE
IMAGE_TAG ?= $(shell git rev-parse HEAD)
else
IMAGE_TAG ?= "unknown-dev.$(DATE)"
endif

# Generate an informational tag so we can see where every image comes from.
DATE := $(shell date -u '+%Y%m%d.%H%M%S')
INFO_TAG := $(DATE).$(USER)

release-build: ## Build release for $APP_NAME and tag it with current git hash
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	cd $(APP_NAME) && $(MAKE) release-build \
		OPTS="--tag $(IMAGE_NAME):latest --tag $(IMAGE_NAME):$(IMAGE_TAG)"

release-publish: ## Publish release to $APP_NAME's build repository
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	./bin/publish-release $(APP_NAME) $(IMAGE_NAME) $(IMAGE_TAG)

release-run-database-migrations: ## Run $APP_NAME's database migrations in $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "dev")
	./bin/run-database-migrations $(APP_NAME) $(IMAGE_TAG) $(ENVIRONMENT)

release-deploy: ## Deploy release to $APP_NAME's web service in $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "dev")
	./bin/deploy-release $(APP_NAME) $(IMAGE_TAG) $(ENVIRONMENT)

release-image-name: ## Prints the image name of the release image
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@echo $(IMAGE_NAME)

release-image-tag: ## Prints the image tag of the release image
	@echo $(IMAGE_TAG)

DB_ROLE_MANAGER_IMAGE_TAG ?= $(IMAGE_TAG)

DB_ROLE_MANAGER_IMAGE_NAME := $(PROJECT_ROOT)-db-role-manager

db-role-manager-release-build: ## Build release for the DB Role Manager and tag it with current git hash
	cd infra/modules/database/resources/role_manager && $(MAKE) release-build \
		OPTS="--tag $(DB_ROLE_MANAGER_IMAGE_NAME):latest --tag $(DB_ROLE_MANAGER_IMAGE_NAME):$(DB_ROLE_MANAGER_IMAGE_TAG)"

db-role-manager-release-publish: ## Publish DB Role Manager release to $APP_NAME build repository
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	./bin/publish-release $(APP_NAME) $(DB_ROLE_MANAGER_IMAGE_NAME) $(DB_ROLE_MANAGER_IMAGE_TAG) "db-role-manager"

db-role-manager-release-deploy: ## Deploy DB Role Manager release for $APP_NAME in $ENVIRONMENT
	@:$(call check_defined, APP_NAME, "the name of subdirectory of /infra that holds the application's infrastructure code")
	@:$(call check_defined, ENVIRONMENT, the name of the application environment e.g. "prod" or "dev")
	./bin/deploy-db-role-manager-release $(APP_NAME) $(DB_ROLE_MANAGER_IMAGE_TAG) $(ENVIRONMENT)

########################
## Scripts and Helper ##
########################

help: ## Prints the help documentation and info about each command
	@grep -Eh '^[[:print:]]+:.*?##' $(MAKEFILE_LIST) | \
	sort -d | \
	awk -F':.*?## ' '{printf "\033[36m%s\033[0m\t%s\n", $$1, $$2}' | \
	column -t -s "$$(printf '\t')"
	@echo ""
	@echo "APP_NAME=$(APP_NAME)"
	@echo "ENVIRONMENT=$(ENVIRONMENT)"
	@echo "IMAGE_NAME=$(IMAGE_NAME)"
	@echo "IMAGE_TAG=$(IMAGE_TAG)"
	@echo "INFO_TAG=$(INFO_TAG)"
	@echo "GIT_REPO_AVAILABLE=$(GIT_REPO_AVAILABLE)"
	@echo "SHELL=$(SHELL)"
	@echo "MAKE_VERSION=$(MAKE_VERSION)"
	@echo "MODULES=$(MODULES)"
