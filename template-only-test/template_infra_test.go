package test

import (
	"fmt"
	"os"
	"testing"
	"time"

    "crypto/md5"
    "encoding/hex"

	// "github.com/gruntwork-io/terratest/modules/azure"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

var projectName = os.Getenv("PROJECT_NAME")
var imageTag = os.Getenv("IMAGE_TAG")

const accountId = "4998bf77-b5bd-4bac-8ce7-eecaf9519de2"

const appName = "app"
const environmentName = "dev"

const maxRetries = 3
const sleepBetweenRetries = 5 * time.Second

func TestEndToEnd(t *testing.T) {
	defer TeardownAccount(t)
	SetUpProject(t, projectName)
	t.Run("SetUpAccount", SetUpAccount)
	t.Run("ValidateAccount", ValidateAccount)
	t.Run("Network", SubtestNetwork)
}

func ValidateAccount(t *testing.T) {
	// TODO: update for Azure
	region := "us-east-1"
	ValidateAccountBackend(t, accountId, region, projectName)
	ValidateGithubActionsAuth(t, accountId, projectName)
}

func SubtestNetwork(t *testing.T) {
	defer TeardownNetwork(t)
	t.Run("SetUpNetwork", SetUpNetwork)
	t.Run("BuildRepository", SubtestBuildRepository)
}

func SubtestBuildRepository(t *testing.T) {
	// TODO: not relevant to Azure? Build repo is on the account layer?
	// defer TeardownBuildRepository(t)
	// t.Run("SetUpBuildRepository", SetUpBuildRepository)
	t.Run("ValidateBuildRepository", ValidateBuildRepository)
	t.Run("Service", SubtestDevEnvironment)
}

func SubtestDevEnvironment(t *testing.T) {
	defer TeardownDevEnvironment(t)
	t.Run("SetUpDevEnvironment", SetUpDevEnvironment)
	t.Run("ValidateDevEnvironment", ValidateDevEnvironment)
}

func SetUpProject(t *testing.T, projectName string) {
	fmt.Println("::group::Configuring project")
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"-f", "template-only.mak", "set-up-project"},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

func SetUpAccount(t *testing.T) {
	fmt.Println("::group::Setting up account")
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-set-up-account", "ACCOUNT_NAME=lowers", fmt.Sprintf("args=%s", accountId)},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

func SetUpNetwork(t *testing.T) {
	fmt.Println("::group::Creating network resources")
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-configure-network", "NETWORK_NAME=dev"},
		WorkingDir: "../",
	})
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-update-network", "NETWORK_NAME=dev"},
		Env:        map[string]string{"TF_CLI_ARGS_apply": "-input=false -auto-approve"},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

// func SetUpBuildRepository(t *testing.T) {
// 	fmt.Println("::group::Creating build repository resources")
// 	shell.RunCommand(t, shell.Command{
// 		Command:    "make",
// 		Args:       []string{"infra-configure-app-build-repository", fmt.Sprintf("APP_NAME=%s", appName)},
// 		WorkingDir: "../",
// 	})
// 	shell.RunCommand(t, shell.Command{
// 		Command:    "make",
// 		Args:       []string{"infra-update-app-build-repository", fmt.Sprintf("APP_NAME=%s", appName)},
// 		Env:        map[string]string{"TF_CLI_ARGS_apply": "-input=false -auto-approve"},
// 		WorkingDir: "../",
// 	})
// 	fmt.Println("::endgroup::")
// }

func SetUpDevEnvironment(t *testing.T) {
	fmt.Println("::group::Creating web service dev environment")
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-configure-app-service", fmt.Sprintf("APP_NAME=%s", appName), "ENVIRONMENT=dev"},
		WorkingDir: "../",
	})

	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-update-app-service", fmt.Sprintf("APP_NAME=%s", appName), "ENVIRONMENT=dev"},
		Env:        map[string]string{"TF_CLI_ARGS_apply": fmt.Sprintf("-input=false -auto-approve -var=image_tag=%s", imageTag)},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

func ValidateAccountBackend(t *testing.T, accountId string, region string, projectName string) {
	fmt.Println("::group::Validating terraform backend for account")
	// tfStateHash := GetMD5Hash(fmt.Sprintf("%s-%s-tf", accountId, projectName))
	// expectedTfStateBucket := fmt.Sprintf("tfst%s", tfStateHash)[:24]
	// expectedTfStateKey := "infra/account.tfstate"

	// TODO: update for Azure
	// aws.AssertS3BucketExists(t, region, expectedTfStateBucket)
	// _, err := aws.GetS3ObjectContentsE(t, region, expectedTfStateBucket, expectedTfStateKey)
	// assert.NoError(t, err, fmt.Sprintf("Failed to get tfstate object from tfstate bucket %s", expectedTfStateBucket))
	fmt.Println("::endgroup::")
}

func ValidateGithubActionsAuth(t *testing.T, accountId string, projectName string) {
	// TODO: update for Azure
	// fmt.Println("::group::Validating that GitHub actions can authenticate with AWS account")
	// // Check that GitHub Actions can authenticate with AWS
	// err := shell.RunCommandE(t, shell.Command{
	// 	Command:    "make",
	// 	Args:       []string{"infra-check-github-actions-auth", "ACCOUNT_NAME=lowers"},
	// 	WorkingDir: "../",
	// })
	// assert.NoError(t, err, "GitHub actions failed to authenticate")
	// fmt.Println("::endgroup::")
}

func ValidateBuildRepository(t *testing.T) {
	fmt.Println("::group::Validating ability to publish build artifacts to build repository")

	err := shell.RunCommandE(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-build", fmt.Sprintf("APP_NAME=%s", appName), fmt.Sprintf("IMAGE_TAG=%s", imageTag)},
		WorkingDir: "../",
	})
	assert.NoError(t, err, "Could not build release")

	err = shell.RunCommandE(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-publish", fmt.Sprintf("APP_NAME=%s", appName), fmt.Sprintf("IMAGE_TAG=%s", imageTag)},
		WorkingDir: "../",
	})
	assert.NoError(t, err, "Could not publish release")

	fmt.Println("::endgroup::")
}

func ValidateDevEnvironment(t *testing.T) {
	fmt.Println("::group::Validating ability to call web service endpoint")

	// Wait for service to be stable
	// serviceName := fmt.Sprintf("%s-%s", appName, environmentName)
	// TODO: update for Azure
	// shell.RunCommand(t, shell.Command{
	// 	Command:    "aws",
	// 	Args:       []string{"ecs", "wait", "services-stable", "--cluster", serviceName, "--services", serviceName},
	// 	WorkingDir: "../../",
	// })

	// Hit the service endpoint to see if it returns status 200
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fmt.Sprintf("../infra/%s/service/", appName),
	})
	serviceEndpoint := terraform.Output(t, terraformOptions, "service_endpoint")
	// Not checking the /health endpoint as we don't deploy the database for
	// this testing, so that endpoint will fail as currently coded
	http_helper.HttpGetWithRetryWithCustomValidation(t, serviceEndpoint, nil, 10, 3*time.Second, func(responseStatus int, responseBody string) bool {
		return responseStatus == 200
	})

	fmt.Println("::endgroup::")
}

func TeardownAccount(t *testing.T) {
	fmt.Println("::group::Destroying account resources")
	runCommandWithRetry(t, "Destroy account resources", maxRetries, sleepBetweenRetries, shell.Command{
		Command:    "make",
		Args:       []string{"-f", "template-only.mak", "destroy-account"},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

func TeardownNetwork(t *testing.T) {
	fmt.Println("::group::Destroying network resources")
	runCommandWithRetry(t, "Destroy network resources", maxRetries, sleepBetweenRetries, shell.Command{
		Command:    "make",
		Args:       []string{"-f", "template-only.mak", "destroy-network"},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

// TODO: not really relevant for Azure?
// func TeardownBuildRepository(t *testing.T) {
// 	fmt.Println("::group::Destroying build repository resources")
// 	runCommandWithRetry(t, "Destroy build repository resources", maxRetries, sleepBetweenRetries, shell.Command{
// 		Command:    "make",
// 		Args:       []string{"-f", "template-only.mak", "destroy-app-build-repository"},
// 		WorkingDir: "../",
// 	})
// 	fmt.Println("::endgroup::")
// }

func TeardownDevEnvironment(t *testing.T) {
	fmt.Println("::group::Destroying dev environment resources")
	runCommandWithRetry(t, "Destroy dev environment resources", maxRetries, sleepBetweenRetries, shell.Command{
		Command:    "make",
		Args:       []string{"-f", "template-only.mak", "destroy-app-service"},
		WorkingDir: "../",
	})
	fmt.Println("::endgroup::")
}

// runCommandWithRetry runs a shell command with retry logic
func runCommandWithRetry(t *testing.T, description string, maxRetries int, sleepBetweenRetries time.Duration, command shell.Command) {
	retry.DoWithRetry(t, description, maxRetries, sleepBetweenRetries, func() (string, error) {
		return "", shell.RunCommandE(t, command)
	})
}

func GetMD5Hash(text string) string {
   hash := md5.Sum([]byte(text))
   return hex.EncodeToString(hash[:])
}
