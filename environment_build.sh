#!/bin/bash


function getFernetKey() {
    FERNET_KEY=$(jq -r .fernet_key < /etc/conf.d/buildpiper/api.json )
    echo "$FERNET_KEY"
}

function getBranchName() {
  BRANCH_NAME=$(jq -r .git_repo.branch_name < /bp/data/environment_build )
  echo "$BRANCH_NAME"
}

function getRepoUrl() {
    REPO_URL=$(jq -r .git_repo.git_url < /bp/data/environment_build )
     echo "$REPO_URL"
}

function getRepoName() {
    REPO_NAME=$(jq -r .git_repo.name < /bp/data/environment_build )
    echo "$REPO_NAME"
}

function getGitUsername() {
    ENCRYPTED_GIT_USERNAME=$(jq -r .git_repo.credential.username < /bp/data/environment_build )
    echo "$ENCRYPTED_GIT_USERNAME"
}

function getGitPassword() {
    ENCRYPTED_GIT_PASSWORD=$(jq -r .git_repo.credential.password < /bp/data/environment_build )
    echo "$ENCRYPTED_GIT_PASSWORD"
}


