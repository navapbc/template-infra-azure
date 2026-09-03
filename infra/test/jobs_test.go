// Tests for the configurable background jobs interface.
//
// These validate the `jobs` variable's contract in the service module: that
// well-formed job configurations are accepted, and that malformed ones are
// rejected by variable validation with an actionable message rather than
// surfacing as an opaque Azure API error at apply time.
//
// They run `terraform validate` against a fixture root module, so they need no
// Azure credentials and no real infrastructure. End-to-end coverage of a job
// actually running lives in TestService, which exercises the manually
// triggered migration job.

package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// jobsFixture renders a root module that instantiates the service module with
// the given `jobs` configuration, and returns its directory.
func jobsFixture(t *testing.T, jobsHCL string) string {
	t.Helper()

	dir := t.TempDir()

	servicePath, err := filepath.Abs("../modules/service")
	require.NoError(t, err)

	config := fmt.Sprintf(`
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
}

provider "azurerm" {
  alias                           = "domain"
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
}

module "service" {
  source = %q

  providers = {
    azurerm        = azurerm
    azurerm.domain = azurerm.domain
  }

  service_name                  = "svc"
  resource_group_name           = "rg"
  resource_group_location       = "eastus"
  image_registry_id             = "/subscriptions/x/registry"
  image_registry_url            = "reg.azurecr.io"
  image_repository_url          = "reg.azurecr.io/o/app"
  image_tag                     = "abc123"
  subnet_name                   = "apps-public"
  network_resource_group_name   = "net-rg"
  application_gateway_subnet_id = null
  application_gateway_sku_name  = "Basic"
  domain_certificate_secret_id  = "sec"

  storage_vars = {
    storage_account_id          = "/subscriptions/x/sa"
    storage_account_name        = "sa"
    container_name              = "documents"
    eventgrid_system_topic_name = "sa-storage-events"
    resource_group_name         = "rg"
  }

  jobs = %s
}
`, servicePath, jobsHCL)

	require.NoError(t, os.WriteFile(filepath.Join(dir, "main.tf"), []byte(config), 0o644))

	return dir
}

// validateJobs runs `terraform validate` against a fixture configured with the
// given jobs, returning the combined output and any error.
func validateJobs(t *testing.T, jobsHCL string) (string, error) {
	t.Helper()

	options := &terraform.Options{
		TerraformDir: jobsFixture(t, jobsHCL),
		NoColor:      true,
	}

	if _, err := terraform.RunTerraformCommandE(t, options, "init", "-backend=false"); err != nil {
		t.Fatalf("terraform init failed: %v", err)
	}

	return terraform.RunTerraformCommandE(t, options, "validate")
}

// TestJobsAcceptsEachTriggerType asserts that all three supported trigger types
// produce a valid configuration.
func TestJobsAcceptsEachTriggerType(t *testing.T) {
	t.Parallel()

	_, err := validateJobs(t, `{
    nightly = {
      command = ["python", "-m", "etl.nightly"]
      trigger = {
        type            = "schedule"
        cron_expression = "0 3 * * *"
      }
    }

    uploads = {
      command = ["python", "-m", "etl.process_upload"]
      cpu     = 1
      memory  = "2Gi"
      trigger = {
        type        = "event"
        path_prefix = "uploads/"
      }
    }

    oneoff = {
      command = ["python", "-m", "etl.oneoff"]
      trigger = { type = "manual" }
    }
  }`)

	assert.NoError(t, err, "schedule, event, and manual jobs should all be valid")
}

// TestJobsRejectsInvalidTriggerType asserts that a typo in the trigger type is
// caught by variable validation.
func TestJobsRejectsInvalidTriggerType(t *testing.T) {
	t.Parallel()

	out, err := validateJobs(t, `{
    oneoff = {
      trigger = { type = "bogus" }
    }
  }`)

	require.Error(t, err, "an unknown trigger type should be rejected")
	assert.Contains(t, out, "must be one of: manual, schedule, event",
		"the error should name the supported trigger types")
}

// TestJobsRejectsScheduleWithoutCron asserts that a scheduled job missing its
// cron expression is caught before apply.
func TestJobsRejectsScheduleWithoutCron(t *testing.T) {
	t.Parallel()

	out, err := validateJobs(t, `{
    nightly = {
      trigger = { type = "schedule" }
    }
  }`)

	require.Error(t, err, "a schedule job without a cron expression should be rejected")
	assert.Contains(t, strings.ToLower(out), "cron_expression",
		"the error should name the missing setting")
}

// TestJobsDefaultsToNoJobs asserts that the jobs interface is opt-in, so that
// existing projects that do not configure any jobs are unaffected.
func TestJobsDefaultsToNoJobs(t *testing.T) {
	t.Parallel()

	_, err := validateJobs(t, "{}")

	assert.NoError(t, err, "a service with no jobs configured should be valid")
}
