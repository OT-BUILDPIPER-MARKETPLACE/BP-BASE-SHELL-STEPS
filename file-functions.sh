function isFileExist() {
    FILEPATH=$1

    if [ -f "$FILEPATH" ]; then
        return 0
    else
        return 1
    fi
}