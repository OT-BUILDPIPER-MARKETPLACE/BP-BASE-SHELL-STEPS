generateOutput() {
  Task=$1
  Status=$2
  Message=$3
  OUTPUT_DIR=/src/${EXECUTION_DIR}/${EXECUTION_TASK_ID}
  mkdir -p ${OUTPUT_DIR}
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

function logInfoMessage() {
    MESSAGE="$1"
    CURRENT_DATE=`date "+%D: %T"`
    COLOUR_GREEN="\e[32m[INFO]\e[0m"
    echo -e "[$CURRENT_DATE] $COLOUR_GREEN $MESSAGE"

}

function logErrorMessage() {
    MESSAGE="$1"
    CURRENT_DATE=`date "+%D: %T"`
    COLOUR_RED="\e[31m[ERROR]\e[0m"
    echo -e "[$CURRENT_DATE] $COLOUR_RED $MESSAGE"
}

function logWarningMessage() {
    MESSAGE="$1"
    CURRENT_DATE=`date "+%D: %T"`
    COLOUR_YELLOW="\e[1;33m[WARNING]\e[0m"
    echo -e "[$CURRENT_DATE] $COLOUR_YELLOW $MESSAGE"
}


