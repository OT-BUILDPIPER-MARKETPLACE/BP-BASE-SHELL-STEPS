function isStrNonEmpty() {
    STR=$1
    if [ -z "$STR" ]; then
        return 1
    else
        return 0
    fi
}