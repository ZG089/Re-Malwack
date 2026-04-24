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
    CURRENT_SCRIPT="defs.sh"; CURRENT_FUNC="rmlwk_prepare_runtime"
    mkdir -p "$persist_dir" "$persist_dir/logs"
    rmlwk_source_config
    version=$(get_prop version "$MODDIR/module.prop")
    LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"
}

rmlwk_detect_hosts_target() {
    CURRENT_SCRIPT="defs.sh"; CURRENT_FUNC="rmlwk_detect_hosts_target"
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

script="${CURRENT_SCRIPT:-rmlwk.sh}"
func_ctx=""
[ -n "$CURRENT_FUNC" ] && func_ctx=" in $CURRENT_FUNC"

case $exit_code in
    0)   msg="Script ran successfully ✅ - No errors" ; level="SUCCESS" ;;
    1)   msg="General error at line $LINENO${func_ctx} ❌" ; level="ERROR" ;;
    126) msg="Cannot execute command at line $LINENO${func_ctx} ❌" ; level="ERROR" ;;
    127) msg="Command not found at line $LINENO${func_ctx} ❌" ; level="ERROR" ;;
    137) msg="Killed (SIGKILL / OOM) ❌" ; level="ERROR" ;;
    *)   msg="Unknown error (code $exit_code) at line $LINENO${func_ctx} ❌" ; level="ERROR" ;;
esac

echo "[$timestamp] - [$level] - $script: $msg" >> "$LOGFILE"

if [ "$exit_code" -ne 0 ] && [ "$quiet_mode" -eq 0 ]; then
    echo "[!] Script aborted unexpectedly."
    echo "[!] $msg"
    echo "[i] Please export logs to share with developer"
fi
' EXIT
}
