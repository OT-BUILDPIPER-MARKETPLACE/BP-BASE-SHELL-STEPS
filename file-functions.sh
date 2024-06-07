#!/bin/bash

function isFileExist() {
    FILEPATH="$1"

    if [ -f "$FILEPATH" ]; then
        echo 0
    else
        echo 1
    fi
}

function fileContainsString() {
    FILEPATH="$1"
    TEXT="$2"
    grep -q "${TEXT}" "${FILEPATH}"
    echo $?
}

function getLineForAString() {
    FILEPATH="$1"
    TEXT="$2"
    grep "${TEXT}" "${FILEPATH}"
}

function textExistsInALine(){
    LINE="$1"
    TEXT="$2"
    # Split single comma separated string into array
    IFS="," read -r -a TEXT_ARRAY <<< "$TEXT"
    for ITEM in "${TEXT_ARRAY[@]}"; do
        if [ "$ITEM" == "$LINE" ]; then
            return 0
        fi
    done
    return 1
}

function encodeFileContent() {
    local FILE_PATH=$1
    base64 $FILE_PATH
}