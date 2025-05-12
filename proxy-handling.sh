# handling proxy and no-proxy cases

run_without_proxy_then_with_fallback() {
    # Usage: run_without_proxy_then_with_fallback <command> [args...]

    local retries=0
    local max_retries=2
    local exit_code

    # Save current proxy values
    local _http_proxy="${http_proxy}"
    local _https_proxy="${https_proxy}"
    local _HTTP_PROXY="${HTTP_PROXY}"
    local _HTTPS_PROXY="${HTTPS_PROXY}"

    echo "[INFO] Attempting to run without proxy: $*"

    # Try command without proxy first (max_retries times)
    while [ $retries -lt $max_retries ]; do
        env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY "$@"
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "[SUCCESS] Command succeeded without proxy."
            return 0
        fi
        echo "[WARN] Attempt $((retries + 1)) failed without proxy. Retrying..."
        ((retries++))
    done

    echo "[INFO] Retrying command with proxy: $*"
    
    # Retry command with proxy
    HTTP_PROXY="$_HTTP_PROXY" HTTPS_PROXY="$_HTTPS_PROXY" \
    http_proxy="$_http_proxy" https_proxy="$_https_proxy" \
    "$@"
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "[SUCCESS] Command succeeded with proxy."
    else
        echo "[ERROR] Command failed with and without proxy. Exit code: $exit_code"
    fi

    return $exit_code
}
