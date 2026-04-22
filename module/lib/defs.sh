[ "${RMLWK_LIB_DEFS:-0}" -eq 1 ] && return 0
RMLWK_LIB_DEFS=1

if [ -z "$MODDIR" ]; then
    REALPATH=$(readlink -f "$0" 2>/dev/null)
    [ -n "$REALPATH" ] || REALPATH="$0"
    MODDIR=$(dirname "$REALPATH")
fi

quiet_mode=0
is_znhr_detected=0
persist_dir=/data/adb/Re-Malwack
znhr=/data/adb/modules/hostsredirect
system_hosts=/system/etc/hosts
tmp_hosts=/data/local/tmp/hosts

RMLWK_BLOCKLIST_TYPES="porn gambling fakenews social trackers safebrowsing"

rmlwk_source_config() {
    [ -f "$persist_dir/config.sh" ] && . "$persist_dir/config.sh" || touch "$persist_dir/config.sh"
}

rmlwk_prepare_runtime() {
    mkdir -p "$persist_dir" "$persist_dir/logs"
    rmlwk_source_config
    version=$(get_prop version "$MODDIR/module.prop")
    LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"
}

rmlwk_detect_hosts_target() {
    if [ -d "$znhr" ] && [ ! -f "$znhr/disable" ] && [ ! -f "$znhr/remove" ]; then
        is_znhr_detected=1
        hosts_file="/data/adb/hostsredirect/hosts"
        log_message "Zygisk host redirect module detected, using $hosts_file as target hosts file"
    else
        is_znhr_detected=0
        hosts_file="$MODDIR/system/etc/hosts"
        log_message "Using standard mount method with $hosts_file"
    fi
}

rmlwk_prepare_cli_flags() {
    quiet_mode=0
    for arg in "$@"; do
        [ "$arg" = "--quiet" ] && quiet_mode=1 && break
    done
}

rmlwk_setup_error_trap() {
    exec 2>>"$LOGFILE"
    set -e
    trap '
exit_code=$?
timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")

case $exit_code in
    0)   msg="Script ran successfully ✅ - No errors" ;;
    1)   msg="General error at line $LINENO ❌" ;;
    126) msg="Command at line $LINENO invoked cannot execute ❌" ;;
    127) msg="Command at line $LINENO not found ❌" ;;
    137) msg="Killed (SIGKILL / OOM) ❌" ;;
    *)   msg="Unknown error at line $LINENO ❌ (code $exit_code)" ;;
esac

echo "[$timestamp] - [$msg]" >> "$LOGFILE"
' EXIT
}
