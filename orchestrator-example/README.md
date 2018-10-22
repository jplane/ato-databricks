# Orchestrator Example

## What's this?

A .NET Core Function app to orchestrate Databricks jobs based on blob triggers.

## Setup instructions

### One-time system configuration

1. Install Visual Studio 2017 and ensure that the [Azure development workload](https://docs.microsoft.com/en-us/azure/azure-functions/functions-develop-vs) is configured and installed.

1. Note that this project will likely also work with VS Code + Azure Tools for VS Code, but has not been tested with that configuration.

1. Be sure to perform any pending Visual Studio updates, including any for Azure tools.

1. Clone the [repo](https://github.com/jplane/allthingsopen-databricks)

1. Create a new storage account in Azure, and create three blob containers within:

    * rawdata
    * input
    * output

1. Copy template.settings.json into a file called local.settings.json and replace the values within using known values for your Azure environment.

1. You will need to create a Databricks environment in Azure, or find one you can re-use. [Create a personal access token](https://docs.databricks.com/api/latest/authentication.html) and add it to local.settings.json.

1. You'll need to import the [notebooks](https://github.com/jplane/allthingsopen-databricks/tree/master/orchestrator-example/notebooks) for the project into Databricks. More info [here](https://docs.databricks.com/user-guide/notebooks/notebook-manage.html#notebook-external-formats).

1. You will need to [configure](https://docs.databricks.com/user-guide/jobs.html#create-a-job) the following jobs on the Databricks environment (or ensure they're already configured):

    * FilterLoans - use the FilterLoans notebook
    * FilterMortgages - use the FilterMortgages notebook

   You may also optionally configure the jobs to use an existing cluster vs. creating a new one. Any standard cluster should work fine.

1. Download the Consumer Complaint CSV data [here](https://www.consumerfinance.gov/data-research/consumer-complaints/#download-the-data). Note the file is about 600 MB in size.

1. Once downloaded, upload the complaint CSV to your 'rawdata' Azure blob storage container. An easy way to manage blobs in Azure is with the [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/) tool

### Running the project

#### Build and publish the code

1. Build the function project in Visual Studio.

1. Right click the project node and select 'Publish'. Configure the publish wizard to point to the Azure App Service of your choice.

1. Within the publish wizard, use the 'Manage Application Settings' link to synchronize settings from local.settings.json to your Azure App Service.

1. Finalize the deployment by clicking the 'Publish' button.

#### Kick off the processing pipeline

Copy the 'Consumer_Complaints.csv' file from the 'rawdata' blob container to the 'input' container. Assuming your configuration settings are set up correctly, you should soon see the function execute and then each Databricks job run in turn.
