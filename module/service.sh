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

# function to check adblock pause
function is_adblock_paused() {
    if [ -f "$persist_dir/hosts.bak" ] && [ "adblock_switch" -eq 1 ] ; then
        return 0
    else
        return 1
    fi
}

log_message "=========== [service.sh Logs] ==========="

# symlink rmlwk to manager path
if [ "$KSU" = "true" ]; then
    [ -L "/data/adb/ksud/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ksud/bin/rmlwk"
elif [ "$APATCH" = "true" ]; then
    [ -L "/data/adb/apd/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/apd/bin/rmlwk"
else
    [ -w /sbin ] && magisktmp=/sbin
    [ -w /debug_ramdisk ] && magisktmp=/debug_ramdisk
    ln -sf "$MODDIR/rmlwk.sh" "$magisktmp/rmlwk" && log_message "symlink created at $magisktmp/rmlwk"
fi

start_time=$(date +%s)
log_message "Fetching last hosts file update"
last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1)

# From here we fetch blocked entries in both system hosts file and module hosts file
blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
# Fallback (in worst cases)
blocked_sys=${blocked_sys:-0}
log_message "System hosts entries count: $blocked_sys"
# Detect reset state or missing hosts file
if [ ! -s "$hosts_file" ]; then
    blocked_mod=0
    log_message "Hosts file is reset or not initialized."
else
    blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
    # Fallback (in worst cases)
    blocked_mod=${blocked_mod:-0}
fi
log_message "module hosts entries count: $blocked_mod"

# Here goes the part where we actually determine module status
if is_adblock_paused && [ "$blocked_mod" -gt 0 ]; then
    status_msg="Status: Ad-block is paused ⏸️"
elif [ "$blocked_mod" -gt 10 ]; then
    if [ "$blocked_mod" -ne "$blocked_sys" ]; then # Only for cases when mount breaks between module hosts and system hosts
        status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
    else
        status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains | Last updated: $last_mod"
    fi
elif [ "$blocked_sys" -eq 0 ]; then
    status_msg="Status: Need to reboot once again 🔃 (If still showing same then report to developer)"
else
    status_msg="Status: Protection is disabled due to reset ❌"
fi

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