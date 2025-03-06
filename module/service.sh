#!/bin/sh

MODDIR="${0%/*}"
HOSTS_FILE="/system/etc/hosts"
string="description=Status: Protection is enabled ✅ | Last updated: $(date)"
persist_dir="/data/adb/Re-Malwack"
source $persist_dir/config.sh
mkdir -p "$persist_dir/logs"
rm -rf "$persist_dir/logs/"*

# Logging function
function log_message() {
    local message="$1"
    touch "$persist_dir/logs/service.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> "$persist_dir/logs/service.log"
}

# Check if auto-update is enabled
if [ "$daily_update" = "1" ]; then
    # Check if crond is running
    if ! pgrep -x crond >/dev/null; then
        log_message "Auto-update is enabled, but crond is not running. Starting crond..."
        busybox crond -c "/data/adb/Re-Malwack/auto_update" -L "/data/adb/Re-Malwack/logs/auto_update.log"
        log_message "Crond started."
    else
        log_message "Crond is already running."
    fi
fi