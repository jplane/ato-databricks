## What's this?

A Databricks dev loop that streamlines local dev + test, and Azure-based deployment and execution.

## Setup instructions

### One-time system configuration

1. Install the [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) and [Docker](https://www.docker.com/get-docker) on your Windows machine.
1. Enter the WSL Ubuntu shell.
1. Ensure you set up WSL and Docker to [work together correctly](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly)
1. Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt) on WSL.
1. Log into Azure via `az login`
1. Clone the BigCorpProj repository
1. Create a Databricks workspace in the Azure portal, or use an existing one.
1. Navigate to your Databricks resource in the Azure Portal, click on "Launch Workspace", [create a personal access token](https://docs.databricks.com/api/latest/authentication.html#token-management) and add it to the `dev.env` file under the `DBC_TOKEN` key. Also update the `DBC_USERNAME` and `DBC_NOTIFICATIONS_EMAIL` keys with your email address.

### Running the project

#### Build and verify the code

1. Execute `docker build . -t local/scala-base -f Dockerfile.base` to build the Spark/Scala base image.
1. Execute `docker build . -t bigcorp-builder --target=builder` to build the builder environment.
1. Execute `docker build . -t bigcorp-runner` to build the runtime exection environment.
1. Execute `docker run --rm bigcorp-builder 'sbt scalastyle test'` to lint the code and run the tests.
1. Execute `docker run --rm bigcorp-builder 'shellcheck $(find . -type f -name "*.sh")'` to lint the scripts.

#### Run the Fibonacci job in Azure

Execute `docker run --env-file=dev.env --rm bigcorp-runner "Fibonacci" "{ \"x\": \"5\" }"` to run the Fibonacci job on Databricks. If you have email notifications configured in your Databricks environment, you should receive an email upon job completion.

Note that the `bigcorp-runner` Docker container automatically takes care of creating a new cluster on Databricks if one doesn't exist, uploading all the required files to the cluster, restarting the cluster when required, etc.
