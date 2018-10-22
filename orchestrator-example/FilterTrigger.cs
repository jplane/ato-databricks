using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage.Blob;
using Newtonsoft.Json.Linq;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace IngestOrchestrator
{
    public static class FilterTrigger
    {
        [FunctionName("FilterTrigger")]
        [StorageAccount("storageAccountConnectionString")]
        public static async Task Run(
            [BlobTrigger("%storageContainer%/{blobName}")] CloudBlockBlob blob,
            string blobName,
            ExecutionContext context,
            ILogger log)
        {
            var config = new Config(context);

            var databricks = new DatabricksUtil(config);

            var args = new JObject();
            args["blob-account"] = config["storageAccountName"];
            args["blob-key"] = config["storageAccountKey"];
            args["blob-container"] = config["storageContainer"];
            args["blob-file"] = config["storageFile"];

            await databricks.RunJob("FilterMortgages", args);

            await databricks.RunJob("FilterLoans", args);
        }
    }
}
