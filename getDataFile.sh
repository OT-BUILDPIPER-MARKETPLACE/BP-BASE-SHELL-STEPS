#!/bin/bash

SOURCE_FILE_PATH="/bp/data/environment_build"
# SOURCE_DEPLOY_FILE_PATH="/bp/data/deploy_stateless_app"
SOURCE_DEPLOY_FILE_PATH=$1

# Function to get the dcoker image name
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

#-----------------------------------------Deploy ENVS-------------------------------------------------

# Function to get the service account name
function getServiceAccountName() {
  SERVICE_ACCOUNT_NAME=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "serviceaccount") | .metadata.name' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "Service Account Name: $SERVICE_ACCOUNT_NAME"
}

# Function to get the container image from the deployment
function getContainerImage() {
  CONTAINER_IMAGE=$(jq -r '.k8s_manifest[] | select(.k8s_manifest_type == "deployment") | .spec.template.spec.containers[0].image' < "$SOURCE_DEPLOY_FILE_PATH")
  echo "$CONTAINER_IMAGE"
}