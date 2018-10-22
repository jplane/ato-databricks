#!/usr/bin/env bash

log() {
  echo "[$(date)] $*" >&2
}

fetch_cluster_jars() {
  databricks libraries cluster-status --cluster-id="$1" | jq -r '.library_statuses | .[] | .library | .jar'
}

fetch_node_types() {
  databricks clusters list-node-types | jq -r '.node_types | .[] | .node_type_id'
}

fetch_cluster_id_for_name() {
  databricks clusters list | grep "$1" | cut -d' ' -f1 | head -1
}

fetch_job_id_for_name() {
  databricks jobs list --output=JSON | jq -r '.jobs | .[] | "\(.settings.name),\(.job_id)"' | grep "^$1," | cut -d',' -f2 | head -1
}

wait_for_cluster() {
  while :; do
    cluster_status="$(databricks clusters get --cluster-id="$1" | jq -r '.state')"
    if [ "$cluster_status" = "RUNNING" ]; then
      log "cluster with ID $1 is now available"
      break
    else
      log "waiting for cluster with ID $1 to spin up"
      sleep 5s
    fi
  done
}

command_exists() {
  command -v "$1" >/dev/null
}

get_sbt_value() {
  awk "/$1 :=/{print \$NF}" "$2" | tr -d '"'
}

readonly databricks_config="$HOME/.databrickscfg"
readonly DEPLOYMENT_ENVIRONMENT="$1"
readonly NOTEBOOK_TO_RUN="$2"
readonly JOB_ARGS="$3"

if [ -z "$DEPLOYMENT_ENVIRONMENT" ] || [ -z "$NOTEBOOK_TO_RUN" ]; then
  log "Missing script arguments"
  exit 1
fi

if [ ! -f "$databricks_config" ]; then
  if [ -z "$DBC_URL" ] || [ -z "$DBC_TOKEN" ]; then
    log "Missing databricks connection environment variables"
    exit 1
  fi
fi

if [ -z "$DBC_USERNAME" ] || [ -z "$DBC_NOTIFICATIONS_EMAIL" ]; then
  log "Missing databricks user environment variables"
  exit 1
fi

if [ -z "$DBC_JOB_SUBMIT_SKU_SIZE" ] || [ -z "$DBC_MIN_NODES" ] || [ -z "$DBC_MAX_NODES" ]; then
  exit 1
fi

if ! command_exists databricks; then
  log "databricks cli is not installed, unable to publish builds"
  exit 1
fi

if ! command_exists jq; then
  log "jq is not installed, unable to continue"
  exit 1
fi

if [ ! -f "$databricks_config" ]; then
  (echo "[DEFAULT]"
   echo "host = $DBC_URL"
   echo "token = $DBC_TOKEN") > "$databricks_config"
fi

log "verifying node sku type"

if ! fetch_node_types | grep -q "$DBC_JOB_SUBMIT_SKU_SIZE"; then
  log "unknown node type $DBC_JOB_SUBMIT_SKU_SIZE, must be one of $(fetch_node_types | paste -sd',')"
  exit 1
fi

readonly scriptdir="$(dirname "$0")"
readonly rootdir="$scriptdir/../../.."
readonly build_sbt_file="$rootdir/build.sbt"

readonly build_version="$(get_sbt_value "version" "$build_sbt_file")"
readonly project_name="$(get_sbt_value "name" "$build_sbt_file")"
readonly scala_version="$(get_sbt_value "scalaVersion" "$build_sbt_file" | cut -d'.' -f1,2)"
readonly spark_version_databricks="4.0.x"

readonly jar_name="$project_name-assembly-$build_version.jar"
readonly jar_path_local="$rootdir/target/scala-$scala_version/$jar_name"
readonly jar_checksum="$(md5sum --binary "$jar_path_local" | cut -d' ' -f1)"
readonly notebook_directory_local="$rootdir/src/main/notebooks"

readonly jar_path_databricks="dbfs:/lib/$DBC_USERNAME/$DEPLOYMENT_ENVIRONMENT/$jar_checksum-$jar_name"
readonly notebook_directory_databricks="/Users/$DBC_USERNAME/notebooks/$DEPLOYMENT_ENVIRONMENT/$build_version"

readonly cluster_name="$project_name-$DBC_USERNAME-cluster"

readonly tmproot="$(mktemp -d)"
cleanup() { rm -rf "$tmproot"; }
trap cleanup EXIT

log "setting up databricks workspace"
databricks fs cp --overwrite "$jar_path_local" "$jar_path_databricks"
databricks workspace import_dir --overwrite "$notebook_directory_local" "$notebook_directory_databricks"

log "setting up cluster"
cluster_id="$(fetch_cluster_id_for_name "$cluster_name")"

readonly create_cluster_args="$tmproot/create-cluster.json"
tee "$create_cluster_args" << EOM
{
  "cluster_name": "${cluster_name}",
  "spark_version": "${spark_version_databricks}-scala${scala_version}",
  "node_type_id": "${DBC_JOB_SUBMIT_SKU_SIZE}",
  "autoscale" : {
    "min_workers": ${DBC_MIN_NODES},
    "max_workers": ${DBC_MAX_NODES}
  }
}
EOM

if [ -z "$cluster_id" ]; then
  log "no existing cluster found, creating new cluster"
  cluster_id="$(databricks clusters create --json-file="$create_cluster_args" | jq -r '.cluster_id')"
fi

wait_for_cluster "$cluster_id"

if ! fetch_cluster_jars "$cluster_id" | grep -q "$jar_path_databricks"; then
  if databricks libraries uninstall --cluster-id="$cluster_id" --all; then
    log "cluster is not using the latest version of the shared library, uninstalled old version"
    databricks clusters restart --cluster-id="$cluster_id"
    wait_for_cluster "$cluster_id"
  fi
  log "installing shared library"
  databricks libraries install --cluster-id="$cluster_id" --jar "$jar_path_databricks"
fi

readonly notebook_checksum="$(md5sum --text "$notebook_directory_local/$NOTEBOOK_TO_RUN"* | cut -d' ' -f1)"
readonly job_name="$(basename "$NOTEBOOK_TO_RUN")-$notebook_checksum-$jar_checksum"
readonly create_job_args="$tmproot/create-job.json"
tee "$create_job_args" << EOM
{
  "name": "${job_name}",
  "existing_cluster_id": "${cluster_id}",
  "notebook_task": {
    "notebook_path": "${notebook_directory_databricks}/${NOTEBOOK_TO_RUN}"
  },
  "max_retries": "Unlimited",
  "max_concurrent_runs": 1,
  "email_notifications": {
    "on_start": ["${DBC_NOTIFICATIONS_EMAIL}"],
    "on_success": ["${DBC_NOTIFICATIONS_EMAIL}"],
    "on_failure": ["${DBC_NOTIFICATIONS_EMAIL}"]
  }
}
EOM

job_id="$(fetch_job_id_for_name "$job_name")"
if [ -z "$job_id" ]; then
  log "creating job $job_name on cluster with ID $cluster_id"
  job_id="$(databricks jobs create --json-file="$create_job_args" | jq -r '.job_id')"
fi

log "running job with ID $job_id on cluster with ID $cluster_id"
readonly run_job_args="$tmproot/run-job.json"
tee "$run_job_args" << EOM
${JOB_ARGS}
EOM
databricks jobs run-now --job-id="$job_id" --notebook-params="$(cat "$run_job_args")"
