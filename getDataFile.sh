#!/bin/bash

SOURCE_FILE_PATH="/bp/data/environment_build"
SOURCE_DEPLOY_FILE_PATH="/bp/data/deploy_stateless_app"
SOURCE_POD_SHIFT_FILE_PATH="/bp/data/pod_shift"
# SOURCE_POD_SHIFT_FILE_PATH="/bp/data/pod_shift"
SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH="/bp/data/pipeline_context_param"
ROLLBACK_SOURCE_FILE_PATH="/bp/data/rollback_stateless_app"

# SOURCE_DEPLOY_FILE_PATH=$1

safe_jq_from_file() {
  local file_path="$1"
  local jq_filter="$2"
  local default_value="${3:-}"

  if [[ ! -f "$file_path" ]]; then
    echo "$default_value"
    return 0
  fi

  jq -r "$jq_filter" < "$file_path" 2>/dev/null || echo "$default_value"
}

# Function to get the docker image name
function getImageName() {
  BUILD_IMAGE_NAME=$(jq -r .build_detail.repository.name < "${SOURCE_FILE_PATH}")
  echo "$BUILD_IMAGE_NAME"
}

# Function to get the docker image tag
function getImageTag() {
  BUILD_IMAGE_TAG=$(jq -r .build_detail.repository.tag < "${SOURCE_FILE_PATH}")
  echo "$BUILD_IMAGE_TAG"
}


# Function to get the Dockerfile path
function getDockerfilePath() {
  DOCKERFILE_ENTRY=$(jq -r .build_detail.dockerfile_path < "${SOURCE_FILE_PATH}")
  echo "$DOCKERFILE_ENTRY"
}

# Function to get the Git branch name
function getGitBranch() {
  GIT_BRANCH_NAME=$(jq -r .git_repo.branch_name < "${SOURCE_FILE_PATH}")
  echo "$GIT_BRANCH_NAME"
}

# Function to get the service name
function getServiceName() {
  PROJECT_SVC_NAME=$(jq -r .component.name < "${SOURCE_FILE_PATH}")
  echo "$PROJECT_SVC_NAME"
}

# Function to get the master environment
function getMasterEnv() {
  PROJECT_MASTER_ENV=$(jq -r .environment.environment_master < "${SOURCE_FILE_PATH}")
  echo "$PROJECT_MASTER_ENV"
}

# Function to get the project environment
function getProjectEnv() {
  PROJECT_ENV=$(jq -r .environment.project_env < "${SOURCE_FILE_PATH}")
  echo "$PROJECT_ENV"
}

# Function to get the artifact or image registry name (configured by the user on buildpiper)
function getRegistryName() {
  REGISTRY_NAME=$(jq -r .registry.name < "${SOURCE_FILE_PATH}")
  echo "$REGISTRY_NAME"
}

# Function to get the artifact or image registry URL
function getRegistryURL() {
  REGISTRY_URL=$(jq -r .registry.url < "${SOURCE_FILE_PATH}")
  echo "$REGISTRY_URL"
}

# Function to get the artifact or image registry username
function getRegistryUsername() {
  REGISTRY_USERNAME=$(jq -r .registry.username < "${SOURCE_FILE_PATH}")
  echo "$REGISTRY_USERNAME"
}

# Function to get the artifact or image registry password
function getRegistryPassword() {
  REGISTRY_PASSWORD=$(jq -r .registry.password < "${SOURCE_FILE_PATH}")
  echo "$REGISTRY_PASSWORD"
}

# Function to get the Git repository URL
function getGitRepoURL() {
  GIT_REPO_URL=$(jq -r .git_repo.git_url < "${SOURCE_FILE_PATH}")
  echo "$GIT_REPO_URL"
}

# Function to get the Git provider name
function getGitProviderName() {
  GIT_PROVIDER_NAME=$(jq -r .git_repo.git_provider.name < "${SOURCE_FILE_PATH}")
  echo "$GIT_PROVIDER_NAME"
}

# Function to get pre-hooks commands
function getPreHooks() {
  jq -r '.pre_hooks[] | .command' < "${SOURCE_FILE_PATH}"
}

# Function to get post-hooks commands
function getPostHooks() {
  jq -r '.post_hooks[] | .command' < "${SOURCE_FILE_PATH}"
}

# Function to get Docker image cleanup enabled status
function isDockerCleanupEnabled() {
  DOCKER_CLEANUP_ENABLED=$(jq -r .docker_image_cleanup.enabled < "${SOURCE_FILE_PATH}")
  echo "$DOCKER_CLEANUP_ENABLED"
}

# Function to get Docker image retention count
function getDockerCleanupRetention() {
  DOCKER_CLEANUP_RETENTION=$(jq -r .docker_image_cleanup.retention_count < "${SOURCE_FILE_PATH}")
  echo "$DOCKER_CLEANUP_RETENTION"
}

# Function to get the environment variables
function getEnvVariables() {
  jq -r '.build_detail.env_variables | to_entries | .[] | "\(.key)=\(.value)"' < "${SOURCE_FILE_PATH}"
}

# Function to get the docker image name
function getRepoCloneDepth() {
  REPO_CLONE_DEPTH=$(jq -r .git_repo.depth < "${SOURCE_FILE_PATH}")
  echo "$REPO_CLONE_DEPTH"
}

#-----------------------------------------Deploy ENVS-------------------------------------------------

# Function to get the deployment service account name
function getServiceAccountName() {
  DEPLOY_SERVICE_ACCOUNT_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "serviceaccount") | .metadata.name' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$DEPLOY_SERVICE_ACCOUNT_NAME"
}

# Function to get the deployment service name
function getDeploymentServiceName() {
  DEPLOY_SERVICE_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "service") | .metadata.name' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$DEPLOY_SERVICE_NAME"
}

# Function to get the deployment name
function getDeploymentName() {
  DEPLOYMENT_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "deployment") | .metadata.name' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$DEPLOYMENT_NAME"
}

# Function to get the container image from the deployment
function getContainerImage() {
  CONTAINER_IMAGE=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "deployment") | .spec.template.spec.containers[0].image' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$CONTAINER_IMAGE"
}

# Function to get the number of replicas from the deployment
function getReplicas() {
  REPLICAS=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "deployment") | .spec.replicas' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "Replicas: $REPLICAS"
}

# Function to get the deployment service account name
function getDeploymentNamespace() {
  DEPLOYMENT_NAMESPACE=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "serviceaccount") | .metadata.namespace' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$DEPLOYMENT_NAMESPACE"
}

extract_service() {
    name="$1"
    echo "$name" | grep -oP '^(?:v-[0-9]+)?\K[a-zA-Z0-9-]+(?=-prod|-dev|-staging|-uat|-qa)'
}

function getDeploymentServiceName() {
  SERVICE_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "service") | .metadata.name' < "$SOURCE_DEPLOY_FILE_PATH")
  EXTRACTED_SERVICE_NAME=$(extract_service "$SERVICE_NAME")
  echo "$EXTRACTED_SERVICE_NAME"
}

#-----------------------------------------POD SHIFT ENVS-------------------------------------------------

# Function to get the Canary Status
function canary_status() {
  CANARY_STATUS=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary' "false")
  echo "$CANARY_STATUS"
}

function get_version() {
  VERSION=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.version')
  echo "$VERSION"
}
function get_previous_version() {
  PREVIOUS_VERSION=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.previous_version')
  echo "$PREVIOUS_VERSION"
}

# Function to get the canary_parent_global_task_id
function get_canary_parent_global_task_id() {
  CANARY_PARENT_GLOBAL_TASK_ID=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary_parent_global_task_id')
  echo "$CANARY_PARENT_GLOBAL_TASK_ID"
}

# Function to get the Canary Deployment Strategy
function canary_deployment_strategy() {
  CANARY_DEPLOYMENT_STRATEGY=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary_deployment_strategy')
  echo "$CANARY_DEPLOYMENT_STRATEGY"
}

# Function to get the Desired Replica Count
function desired_replica() {
  DESIRED_REPLICA=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.desired_replica')
  echo "$DESIRED_REPLICA"
}

# Function to get the Canary Deployment Deploy Artifact
function canary_deployment_deploy_artifact() {
  CANARY_DEPLOY_ARTIFACT=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary_deployment_deploy_artifact')
  echo "$CANARY_DEPLOY_ARTIFACT"
}

# Function to get the Canary Deployment Name
function canary_deployment_name() {
  CANARY_DEPLOYMENT_NAME=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary_deployment_name')
  echo "$CANARY_DEPLOYMENT_NAME"
}

# Function to get the Canary Deployment Pod Shift Percentage
function canary_deployment_pod_shift_percentage() {
  CANARY_DEPLOYMENT_POD_SHIFT_PERCENTAGE=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.canary_deployment_pod_shift_percentage')
  echo "$CANARY_DEPLOYMENT_POD_SHIFT_PERCENTAGE"
}

# Function to get the Baseline Deployment Deploy Artifact
function baseline_deployment_deploy_artifact() {
  BASELINE_DEPLOY_ARTIFACT=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.baseline_deployment_deploy_artifact')
  echo "$BASELINE_DEPLOY_ARTIFACT"
}

# Function to get the Baseline Deployment Name
function baseline_deployment_name() {
  BASELINE_DEPLOYMENT_NAME=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.baseline_deployment_name')
  echo "$BASELINE_DEPLOYMENT_NAME"
}

# Function to get the Namespace
function canary_namespace() {
  CANARY_NAMESPACE=$(safe_jq_from_file "$SOURCE_POD_SHIFT_FILE_PATH" '.namespace')
  echo "$CANARY_NAMESPACE"
}

#-----------------------------------------PIPELINE CONTEXT PARAMETERS-------------------------------------------------

# Function to get the Application ID
function application_id() {
  APPLICATION_ID=$(safe_jq_from_file "$SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH" '.application_id')
  echo "$APPLICATION_ID"
}

# Function to get the Pipeline ID
function pipeline_id() {
  PIPELINE_ID=$(safe_jq_from_file "$SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH" '.pipeline_id')
  echo "$PIPELINE_ID"
}

# Function to get the Pipeline Execution ID
function pipeline_execution_id() {
  PIPELINE_EXECUTION_ID=$(safe_jq_from_file "$SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH" '.pipeline_execution_id')
  echo "$PIPELINE_EXECUTION_ID"
}

function pipeline_execution_ChangeRequestID() {
  PIPELINE_EXECUTION_CHANGE_REQUEST_ID=$(safe_jq_from_file "$SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH" 'to_entries[] | select(.key | endswith("servicenow_id.key")) | .value')
  # default to NA if empty/null/n/a
  if [[ -z "$PIPELINE_EXECUTION_CHANGE_REQUEST_ID" || "$PIPELINE_EXECUTION_CHANGE_REQUEST_ID" == "null" || "$PIPELINE_EXECUTION_CHANGE_REQUEST_ID" == "n/a" || "$PIPELINE_EXECUTION_CHANGE_REQUEST_ID" == "NA" ]]; then
    PIPELINE_EXECUTION_CHANGE_REQUEST_ID="NA"
  fi
  echo "$PIPELINE_EXECUTION_CHANGE_REQUEST_ID"
}

function pipeline_execution_jira_ticket_id() {
  PIPELINE_EXECUTION_JIRA_TICKET_ID=$(safe_jq_from_file "$SOURCE_PIPELINE_CONTEXT_PARAMETERS_FILE_PATH" '.release_ticket')
  echo "$PIPELINE_EXECUTION_JIRA_TICKET_ID"
}

#-----------------------------------ROLLBACK STATELESS APP--------------------------------------------

# Common jq base path
JQ_BASE='.buildpiper_meta_data.rollback'

# ----------------------------------------------------
# rollback version
# ----------------------------------------------------
getRollbackVersion() {
  jq -r "${JQ_BASE}.rollback_version" "$ROLLBACK_SOURCE_FILE_PATH"
}

# ----------------------------------------------------
# previous deployment name + tag
# ----------------------------------------------------
get_previous_deployment_name_and_tag() {
  local name tag
  name=$(jq -r "${JQ_BASE}.previous_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  tag=$(jq -r "${JQ_BASE}.previous_deployment_tag" "$ROLLBACK_SOURCE_FILE_PATH")
  echo "${name}:${tag}"
}

# ----------------------------------------------------
# previous deployment name
# ----------------------------------------------------
get_previous_deployment_name() {
  local name
  name=$(jq -r "${JQ_BASE}.previous_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  echo $name
}

# ----------------------------------------------------
# previous deployment tag
# ----------------------------------------------------
get_previous_deployment_tag() {
  local tag
  tag=$(jq -r "${JQ_BASE}.previous_deployment_tag" "$ROLLBACK_SOURCE_FILE_PATH")
  echo $tag
}

# ----------------------------------------------------
# current deployment name + tag
# ----------------------------------------------------
get_current_deployment_name_and_tag() {
  local name tag
  name=$(jq -r "${JQ_BASE}.current_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  tag=$(jq -r "${JQ_BASE}.current_deployment_tag" "$ROLLBACK_SOURCE_FILE_PATH")
  echo "${name}:${tag}"
}

# ----------------------------------------------------
# current deployment name
# ----------------------------------------------------
get_current_deployment_name() {
  local name
  name=$(jq -r "${JQ_BASE}.current_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  echo $name
}

# ----------------------------------------------------
# current deployment tag
# ----------------------------------------------------
get_current_deployment_tag() {
  local tag
  tag=$(jq -r "${JQ_BASE}.current_deployment_tag" "$ROLLBACK_SOURCE_FILE_PATH")
  echo $tag
}

# ----------------------------------------------------
# last pod shift percentage
# ----------------------------------------------------
get_last_pod_shift_percentage() {
  jq -r "${JQ_BASE}.current_deployment_last_pod_shift" "$ROLLBACK_SOURCE_FILE_PATH"
}

# ----------------------------------------------------
# application and env
# ----------------------------------------------------
get_application_and_env() {
  local app env
  app=$(jq -r "${JQ_BASE}.application" "$ROLLBACK_SOURCE_FILE_PATH")
  env=$(jq -r "${JQ_BASE}.application_env" "$ROLLBACK_SOURCE_FILE_PATH")
  echo "${app}:${env}"
}

# ----------------------------------------------------
# application name
# ----------------------------------------------------
get_application_name() {
  local app
  app=$(jq -r "${JQ_BASE}.application" "$ROLLBACK_SOURCE_FILE_PATH")
  echo $app
}

# ----------------------------------------------------
# namespace
# ----------------------------------------------------
get_namespace() {
  jq -r "${JQ_BASE}.namespace" "$ROLLBACK_SOURCE_FILE_PATH"
}

# ----------------------------------------------------
# versions
# ----------------------------------------------------
get_versions() {
  local prev curr
  prev=$(jq -r "${JQ_BASE}.previous_version" "$ROLLBACK_SOURCE_FILE_PATH")
  curr=$(jq -r "${JQ_BASE}.current_version" "$ROLLBACK_SOURCE_FILE_PATH")
  echo "previous=${prev}, current=${curr}"
}


# ----------------------------------------------------
# deployment names only
# ----------------------------------------------------
get_deployment_names() {
  local prev curr
  prev=$(jq -r "${JQ_BASE}.previous_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  curr=$(jq -r "${JQ_BASE}.current_deployment_name" "$ROLLBACK_SOURCE_FILE_PATH")
  echo "previous=${prev}, current=${curr}"
}

get_is_canary_deployment() {
  jq -r '.buildpiper_meta_data.rollback.current_deployment_is_canary' "$ROLLBACK_SOURCE_FILE_PATH"
}
