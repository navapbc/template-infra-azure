PY_SRCS := src/

PY_RUN ?= uv run --frozen

ifdef CI
FMT_ARGS :=--check
LINT_ARGS :=
else
FMT_ARGS :=
LINT_ARGS :=--fix
endif

check: ## Run checks
check: check-static

check-static: ## Run static code checks
check-static: fmt lint

fmt: ## Run formatter
	$(PY_RUN) ruff format $(FMT_ARGS) $(PY_SRCS)

lint: ## Run linting
lint: lint-mypy lint-ruff lint-uv

lint-mypy: ## Run mypy
	$(PY_RUN) mypy $(args) $(PY_SRCS)

lint-ruff: ## Run ruff linting with auto-fixes
	$(PY_RUN) ruff check $(LINT_ARGS) $(args) $(PY_SRCS)

lint-uv: ## Run uv checks
	uv lock --check

release-build:
	$(CONTAINER_CMD) build \
		--platform=linux/amd64 \
		$(OPTS) \
		.

help: ## Display this help screen
	@grep -Eh '^[[:print:]]+:.*?##' $(MAKEFILE_LIST) | \
	sort -d | \
	awk -F':.*?## ' '{printf "\033[36m%s\033[0m\t%s\n", $$1, $$2}' | \
	column -ts "$$(printf '\t')"
	@echo ""
	@echo "APP_NAME=$(APP_NAME)"
	@echo "PKG_NAME=$(PKG_NAME)"
	@echo "PY_RUN=$(PY_RUN)"
