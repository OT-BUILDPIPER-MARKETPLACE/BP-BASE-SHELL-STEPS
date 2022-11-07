#!/bin/bash

functions_dir="$(dirname "$0")"
source "$functions_dir/./log-functions.sh"

generateOutput() {
  Task=$1
  Status=$2
  Message=$3
  OUTPUT_DIR=/src/${EXECUTION_DIR}/${EXECUTION_TASK_ID}
  mkdir -p "${OUTPUT_DIR}"
  echo "{ \"${Task}\": {\"status\": \"${Status}\", \"message\": \"${Message}\"}}"  | jq . > ${OUTPUT_DIR}/summary.json
  echo "{ \"status\": \"${Status}\", \"message\": \"${Message}\"}"  | jq . > ${OUTPUT_DIR}/${Task}.json
}

function getComponentName() {
  COMPONENT_NAME=`cat /bp/data/environment_build | jq -r .build_detail.repository.name`
  echo "$COMPONENT_NAME"
}

function getRepositoryTag() {
  BUILD_REPOSITORY_TAG=`cat /bp/data/environment_build | jq -r .build_detail.repository.tag`
  echo "$BUILD_REPOSITORY_TAG"
}



