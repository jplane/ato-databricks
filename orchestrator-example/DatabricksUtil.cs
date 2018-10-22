using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace IngestOrchestrator
{
    internal class DatabricksUtil
    {
        private readonly Config _config;
        private readonly Lazy<Dictionary<string, int>> _jobs;

        public DatabricksUtil(Config config)
        {
            _config = config;

            _jobs = new Lazy<Dictionary<string, int>>(() =>
            {
                var http = GetConnection();

                var json = http.GetStringAsync("api/2.0/jobs/list").Result;

                var jobsObj = JObject.Parse(json);

                return jobsObj["jobs"].Select(job =>
                {
                    var name = job["settings"].Value<string>("name");
                    var id = job.Value<int>("job_id");
                    return (name, id);
                })
                .ToDictionary(t => t.Item1, t => t.Item2);
            });
        }

        public async Task RunJob(string jobName, JObject args)
        {
            int jobId;

            if (_jobs.Value.TryGetValue(jobName, out jobId))
            {
                var http = GetConnection();

                var request = new JObject();

                request["job_id"] = jobId;
                request["notebook_params"] = args;

                var content = new StringContent(request.ToString());

                await http.PostAsync("api/2.0/jobs/run-now", content);
            }
            else
            {
                throw new Exception($"Unable to find job '{jobName}' in the Databricks environment.");
            }
        }

        private HttpClient GetConnection()
        {
            var http = new HttpClient();

            http.BaseAddress = new Uri(_config["databricksUri"]);

            var pat = _config["databricksPAT"];

            var token = Base64Encode($"token:{pat}");

            http.DefaultRequestHeaders.Add("Authorization", $"Basic {token}");

            return http;
        }

        private static string Base64Encode(string txt)
        {
            var bytes = Encoding.UTF8.GetBytes(txt);
            return Convert.ToBase64String(bytes);
        }
    }
}
