#!/bin/bash

GREEN="32m"
RED="31m"
YELLOW="1;33m"

COLOR_START="\e["
COLOR_END="\e[0m"

# Resolve log file path using same convention as events/output files
# Can be overridden by setting BP_LOG_FILE externally
_get_log_file() {
    if [[ -n "$BP_LOG_FILE" ]]; then
        echo "$BP_LOG_FILE"
    else
        local EXECUTION_DIR="/bp/execution_dir"
        local OUTPUT_DIR="${EXECUTION_DIR}/${EXECUTION_TASK_ID}"
        echo "${OUTPUT_DIR}/${ACTIVITY_SUB_TASK_CODE}.log"
    fi
}

function logColoredMessage() {
    COLOR="$1"
    LOG_LEVEL="$2"
    MESSAGE="$3"

    CURRENT_DATE=$(date "+%D: %T")

    # 1. Write colored output to stdout (existing behaviour)
    echo -e "[$CURRENT_DATE] ${COLOR_START}${COLOR}[${LOG_LEVEL}]${COLOR_END} ${MESSAGE}"

    # 2. Also write plain-text entry to log file so BuildPiper can read it
    #    from disk even if the container exits before the log agent flushes
    local LOG_FILE
    LOG_FILE=$(_get_log_file)
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$CURRENT_DATE] [$LOG_LEVEL] $MESSAGE" >> "$LOG_FILE"
}

function logInfoMessage() {
    MESSAGE="$1"

    logColoredMessage "${GREEN}" INFO "${MESSAGE}"
}

function logErrorMessage() {
    MESSAGE="$1"

    logColoredMessage "${RED}" ERROR "${MESSAGE}"
}

function logWarningMessage() {
    MESSAGE="$1"
    logColoredMessage "${YELLOW}" WARNING "${MESSAGE}"
}
