[ "${RMLWK_LIB_AUTO_UPDATE:-0}" -eq 1 ] && return 0
RMLWK_LIB_AUTO_UPDATE=1

detect_cron_provider() {
    if command -v busybox >/dev/null 2>&1 && busybox crond --help >/dev/null 2>&1; then
        echo busybox
    elif command -v toybox >/dev/null 2>&1 && toybox crond --help >/dev/null 2>&1; then
        echo toybox
    else
        return 1
    fi
}

cron_cmd() {
    case "$CRON_PROVIDER" in
        busybox) echo "busybox $1" ;;
        toybox)  echo "toybox $1" ;;
    esac
}

auto_update_fallback() {
    FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
    cat > "$FALLBACK_SCRIPT" << 'EOF'
#!/system/bin/sh
LOGFILE="/data/adb/Re-Malwack/logs/auto_update-fallback.log"
PID=$$
echo $PID > /data/adb/Re-Malwack/logs/auto_update.pid
echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Fallback auto update script started with PID $PID" >> "$LOGFILE" 2>&1
while true; do
    sleep 86400
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto-update check started"
        if sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts --quiet 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto update completed successfully"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto update failed"
        fi
    } >> "$LOGFILE" 2>&1
done
EOF

    chmod +x "$FALLBACK_SCRIPT"
    nohup "$FALLBACK_SCRIPT" >/dev/null 2>&1 &
    sleep 1

    if ! kill -0 "$(cat "$persist_dir/logs/auto_update.pid" 2>/dev/null)" 2>/dev/null; then
        echo "[!] Failed to start fallback auto update script, We're officially cooked twin 🥀"
        log_message ERROR "Fallback auto update script failed to stay alive"
        rm -f "$FALLBACK_SCRIPT"
        exit 1
    fi
}

enable_auto_update() {
    JOB_DIR="$persist_dir/auto_update"
    JOB_FILE="$JOB_DIR/root"
    CRON_JOB='0 */12 * * * ( sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts --quiet 2>&1 || echo "Auto-update failed at $(date)" ) >> /data/adb/Re-Malwack/logs/auto_update-cron.log'
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local start_time
    start_time=$(get_current_time)

    log_message "Enabling auto update has been initiated."
    if [ "$daily_update" = "1" ]; then
        abort "Auto update is already enabled"
    fi

    if CRON_PROVIDER=$(detect_cron_provider); then
        CROND=$(cron_cmd crond)
        CRONTAB=$(cron_cmd crontab)

        echo "[*] Enabling auto update via cron."
        log_message "Enabling auto update via cron, Using $CRON_PROVIDER as cron provider."

        mkdir -p "$JOB_DIR" "$persist_dir/logs"
        echo "$CRON_JOB" > "$JOB_FILE"
        $CRONTAB "$JOB_FILE" -c "$JOB_DIR"
        log_message SUCCESS "Cron job added, running crond..."
        $CROND -b -c "$JOB_DIR" -L "$persist_dir/logs/auto_update-cron.log"
        log_message SUCCESS "Started crond successfully."
        sleep 1.5
        CROND_PID="$(busybox pgrep -f "crond.*$JOB_DIR" | head -n 1 || true)"

        if [ -n "$CROND_PID" ]; then
            log_message SUCCESS "crond started! (PID:$CROND_PID)"
        else
            log_message WARN "crond process was not found, falling back to script loop method."
            echo "[!] Crond failed to run in the background, falling back to script loop method."
            rm -rf "$JOB_DIR"
            auto_update_fallback
            log_message SUCCESS "Fallback auto update script started."
        fi
    else
        echo "[i] No cron provider detected, falling back to script loop method."
        log_message WARN "No cron provider detected, falling back to script loop method."
        auto_update_fallback
        log_message SUCCESS "Fallback auto update script started."
    fi

    set_prop daily_update 1 "$persist_dir/config.sh"
    log_message SUCCESS "Auto update has been enabled."
    local end_time
    end_time=$(get_current_time)
    log_duration "Enabling auto update" "$start_time" "$end_time"
    echo "[✓] Auto update has been enabled."
}

disable_auto_update() {
    JOB_DIR="$persist_dir/auto_update"
    FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local start_time
    start_time=$(get_current_time)

    if [ "$daily_update" = "0" ]; then
        abort "Auto update is already disabled"
    fi

    log_message "Disabling auto update has been initiated."
    echo "[*] Disabling auto hosts update"

    if CRON_PROVIDER=$(detect_cron_provider); then
        KILL=$(cron_cmd kill)
        PIDOF=$(cron_cmd pidof)

        log_message "Killing cron processes, Using $CRON_PROVIDER applets."
        for pid in $($PIDOF crond 2>/dev/null); do
            $KILL -9 "$pid" >/dev/null 2>&1
        done
        rm -rf "$JOB_DIR"
        log_message "Cron job removed."
    else
        log_message "Killing fallback auto update script."
        PID="$(cat "$persist_dir/logs/auto_update.pid" 2>/dev/null)"
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" >/dev/null 2>&1
            log_message SUCCESS "Fallback auto update script stopped (PID:$PID)"
        fi
        rm -f "$FALLBACK_SCRIPT"
        log_message "Fallback auto update script stopped and removed."
    fi

    set_prop daily_update 0 "$persist_dir/config.sh"
    local end_time
    end_time=$(get_current_time)
    log_message SUCCESS "Auto update has been disabled."
    log_duration "Disabling auto update" "$start_time" "$end_time"
    echo "[✓] Auto update has been disabled."
}
