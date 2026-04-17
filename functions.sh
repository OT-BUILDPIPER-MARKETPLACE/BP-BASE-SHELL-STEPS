#!/bin/bash

generateOutput() {
    ACTIVITY_SUB_TASK_CODE="$1"
    Status="$2"
    Message="$3"

    EXECUTION_DIR="/bp/execution_dir"
    OUTPUT_DIR="${EXECUTION_DIR}/${EXECUTION_TASK_ID}"
    file_name="$OUTPUT_DIR/summary.json"

    mkdir -p "$OUTPUT_DIR"

    file_content=""
    if [[ -f "$file_name" ]]; then
        file_content=$(<"$file_name")
    fi
    [[ "$file_content" != "["* ]] && file_content="[$file_content]"
    updated_content=$(jq -c ". += [{ \"$ACTIVITY_SUB_TASK_CODE\": { \"status\": \"$Status\", \"message\": \"$Message\" } }]" <<< "$file_content")
    echo "$updated_content" | jq "." > "$file_name"
    # echo "{ \"$ACTIVITY_SUB_TASK_CODE\": { \"status\": \"$Status\", \"message\": \"$Message\" } }" | jq "." > "${OUTPUT_DIR}/${ACTIVITY_SUB_TASK_CODE}.json"
    echo "Job step response updated in: $file_name"
}

init_file() {
   EXECUTION_DIR="/bp/execution_dir"
    OUTPUT_DIR="${EXECUTION_DIR}/${EXECUTION_TASK_ID}"
    STEP_NAME="$ACTIVITY_SUB_TASK_CODE"
    FILE="${OUTPUT_DIR}/${STEP_NAME}_output.json"
   if [ ! -f "$FILE" ]; then
        mkdir -p "$OUTPUT_DIR"
        echo '{"events": {}}' > "$FILE"
  fi
}
add_event() {
    EXECUTION_DIR="/bp/execution_dir"
    OUTPUT_DIR="${EXECUTION_DIR}/${EXECUTION_TASK_ID}"
    STEP_NAME="$ACTIVITY_SUB_TASK_CODE"
    FILE="${OUTPUT_DIR}/${STEP_NAME}_output.json"
  EVENT_NAME="$1"
  STATUS="$2"
  REASON="$3"
  MESSAGE="$4"

  init_file

  jq --arg event "$EVENT_NAME" \
     --arg status "$STATUS" \
     --arg reason "$REASON" \
     --arg message "$MESSAGE" \
     '.events[$event] = {
        status: $status,
        reason: $reason,
        message: $message
     }' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
}

function getComponentName() {
  COMPONENT_NAME=$(jq -r .build_detail.repository.name < /bp/data/environment_build )
  echo "$COMPONENT_NAME"
}

function getRepositoryTag() {
  BUILD_REPOSITORY_TAG=$(jq -r .build_detail.repository.tag < /bp/data/environment_build)
  echo "$BUILD_REPOSITORY_TAG"
}

function saveTaskStatus() {
  TASK_STATUS=$1
  ACTIVITY_SUB_TASK_CODE=$2  

  if [ "$TASK_STATUS" -eq 0 ]
  then
    logInfoMessage "Congratulations ${ACTIVITY_SUB_TASK_CODE} succeeded!!!"
    generateOutput "${ACTIVITY_SUB_TASK_CODE}" true "Congratulations ${ACTIVITY_SUB_TASK_CODE} succeeded!!!"
  elif [ "$VALIDATION_FAILURE_ACTION" == "FAILURE" ]
    then
      logErrorMessage "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      generateOutput "${ACTIVITY_SUB_TASK_CODE}" false "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      exit 1
    else
      logWarningMessage "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
      generateOutput "${ACTIVITY_SUB_TASK_CODE}" true "Please check ${ACTIVITY_SUB_TASK_CODE} failed!!!"
  fi
}


