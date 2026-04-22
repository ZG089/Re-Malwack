[ "${RMLWK_LIB_LOGGING:-0}" -eq 1 ] && return 0
RMLWK_LIB_LOGGING=1

log_message() {
    timestamp() {
        date +"%Y-%m-%d %I:%M:%S %p"
    }

    case "$1" in
        INFO|WARN|ERROR|SUCCESS)
            level="$1"
            shift
            ;;
        *)
            level="INFO"
            ;;
    esac

    msg="$*"
    line="[$(timestamp)] - [$level] - $msg"
    echo "$line" >> "$LOGFILE"
}

rmlwk_banner() {
    [ "$quiet_mode" -eq 1 ] && return
    clear
    printf '\033[0;31m'
    if [ "$(date +%m%d)" = "0401" ]; then
        cat "$MODDIR/lib/banner/remalware"
    else
        cat "$MODDIR/lib/banner/banner"
    fi
    printf '\033[0m'
    update_status
    echo ""
    echo "$version - $status_msg"
    printf '\033[0;31m'
    echo "=================================================="
    printf '\033[0m'
}

export_logs() {
    log_message "Exporting logs..."
    VERSION=$(get_prop version "$MODDIR/module.prop")
    LOG_DATE="$(date +%Y-%m-%d__%H%M%S)"

    if echo "$VERSION" | grep -q "\-test.*#[0-9]*-[a-f0-9]*"; then
        base_version=$(echo "$VERSION" | sed 's/-test.*//')
        build_id=$(echo "$VERSION" | sed 's/.*#\([0-9]*-[a-f0-9]*\).*/\1/')
        tarFileName="Re-Malwack_${base_version}_${build_id}_logs_${LOG_DATE}.tar.gz"
    else
        tarFileName="Re-Malwack_${VERSION}_logs_${LOG_DATE}.tar.gz"
    fi

    log_message SUCCESS "Logs are going to be saved in: /sdcard/Download/$tarFileName"
    tar -czf "/sdcard/Download/$tarFileName" -C "$persist_dir" logs
    echo "Log saved to: /sdcard/Download/$tarFileName"
}
