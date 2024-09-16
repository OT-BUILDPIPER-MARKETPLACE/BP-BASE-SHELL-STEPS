#!/bin/bash

GREEN="32m"
RED="31m"
YELLOW="1;33m"
CYAN="36m"  # Color for debugging

COLOR_START="\e["
COLOR_END="\e[0m"

function logColoredMessage() {
    COLOR="$1"
    LOG_LEVEL="$2"
    MESSAGE="$3"

    CURRENT_DATE=$(date "+%D: %T")
    echo -e "[$CURRENT_DATE]"" ""${COLOR_START}""${COLOR}""[""$LOG_LEVEL""]""${COLOR_END}"" ""$MESSAGE"
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

# Function to log debug messages if DEBUG is enabled
function logDebugMessage() {
    if [[ "$(echo "$DEBUG" | tr '[:upper:]' '[:lower:]')" == "true" ]]; then
        logColoredMessage "${CYAN}" DEBUG "$1"
    fi
}