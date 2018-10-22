using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json.Linq;

namespace IngestOrchestrator
{
    internal class Config
    {
        private static IConfiguration _config;

        public Config(ExecutionContext context)
        {
            _config = new ConfigurationBuilder()
                .SetBasePath(context.FunctionAppDirectory)
                .AddEnvironmentVariables()
                .AddJsonFile("local.settings.json")
                .Build();
        }

        public string this[string key]
        {
            get { return _config[key]; }
        }

        public void SetArgFromConfig(string key, JObject args)
        {
            args[key] = _config[key];
        }
    }
}
