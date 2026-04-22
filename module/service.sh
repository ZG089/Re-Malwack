#!/system/bin/sh

MODDIR="${0%/*}"

. "$MODDIR/lib/defs.sh"
. "$MODDIR/lib/util.sh"
. "$MODDIR/lib/logging.sh"
. "$MODDIR/lib/status.sh"
. "$MODDIR/lib/auto_update.sh"

rmlwk_prepare_runtime
mkdir -p "$persist_dir/logs"
rm -rf "$persist_dir/logs/"*
LOGFILE="$persist_dir/logs/service.log"
exec 2>>"$LOGFILE"

log_message "service.sh Started"
log_message "Re-Malwack Version: $version"

rm -f "$persist_dir/reboot_required"

rmlwk_detect_hosts_target
mount_failed=0
remount_hosts || mount_failed=1

if [ "$dns_logging" = "1" ]; then
    touch "$persist_dir/dns.log"
    chmod 0666 "$persist_dir/dns.log"
    log_message "Initialized DNS logging"
else
    rm -f "$persist_dir/dns.log"
fi

refresh_blocked_counts

if [ -f "$persist_dir/mode_ready" ] && [ "$blocked_mod" -gt 0 ]; then
    rm -f "$persist_dir/mode_ready"
    log_message "Cleared mode_ready flag"
fi

if [ -f "$persist_dir/counts/sources.counts" ]; then
    while IFS='|' read -r url count; do
        [ -n "$url" ] && log_message "Source $url: $count entries"
    done < "$persist_dir/counts/sources.counts"
fi
if [ -f "$persist_dir/counts/blocklists.counts" ]; then
    while IFS='|' read -r bl count; do
        [ -n "$bl" ] && log_message "Blocklist $bl: $count entries"
    done < "$persist_dir/counts/blocklists.counts"
fi

update_status

if [ "$KSU" = "true" ]; then
    log_message "Root manager: KernelSU"
    [ -L "/data/adb/ksu/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ksu/bin/rmlwk"
elif [ "$APATCH" = "true" ]; then
    log_message "Root manager: APatch"
    [ -L "/data/adb/ap/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ap/bin/rmlwk"
else
    log_message "Root manager: Magisk"
    [ -w /sbin ] && magisktmp=/sbin
    [ -w /debug_ramdisk ] && magisktmp=/debug_ramdisk
    [ -n "$magisktmp" ] && ln -sf "$MODDIR/rmlwk.sh" "$magisktmp/rmlwk"
fi

if [ "$daily_update" = 1 ]; then
    FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
    JOB_DIR="$persist_dir/auto_update"
    JOB_FILE="$JOB_DIR/root"
    if [ -f "$FALLBACK_SCRIPT" ]; then
        log_message "Auto update enabled (fallback mode), ensuring fallback script is running."
        nohup "$FALLBACK_SCRIPT" >/dev/null 2>&1 &
        sleep 1
        if ! kill -0 "$(cat "$persist_dir/logs/auto_update.pid" 2>/dev/null)" 2>/dev/null; then
            log_message "Failed to start fallback auto update script, disabling auto update completely..."
            rm -f "$FALLBACK_SCRIPT"
            set_prop daily_update 0 "$persist_dir/config.sh"
        fi
    elif [ -f "$JOB_FILE" ]; then
        log_message "Auto update enabled (cron mode), verifying crond."
        CRON_PROVIDER=$(detect_cron_provider) || {
            log_message "No cron provider detected at boot."
            exit 0
        }
        CROND=$(cron_cmd crond)
        log_message "Auto update is enabled, starting crond..."
        log_message "Using $CRON_PROVIDER applets for cron management."
        $CROND -b -c "$JOB_DIR" -L "$persist_dir/logs/auto_update-cron.log"
        sleep 1.5
        CROND_PID="$(busybox pgrep -f "crond.*$JOB_DIR" | head -n 1 || true)"
        [ -n "$CROND_PID" ] && log_message "Crond started! PID: $CROND_PID" || log_message "Failed to start crond."
    fi
fi

[ "$mount_failed" -eq 1 ] && log_message WARN "Initial remount failed during boot"
log_message "service.sh Finished."