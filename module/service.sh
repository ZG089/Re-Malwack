#!/system/bin/sh
# This is the service script of Re-Malwack
# It is executed during device boot

# =========== Variables ===========
MODDIR="${0%/*}"
hosts_file="$MODDIR/system/etc/hosts"
persist_dir="/data/adb/Re-Malwack"
system_hosts="/system/etc/hosts"
last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file

#  =========== Preparation ===========
. $persist_dir/config.sh
mkdir -p "$persist_dir/logs"
rm -rf "$persist_dir/logs/"*

# =========== Functions ===========

# Function to check hosts file reset state
function is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ]
}

# Logging function
function log_message() {
    local message="$1"
    touch "$persist_dir/logs/service.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> "$persist_dir/logs/service.log"   
}

# function to check adblock pause
function is_protection_paused() {
    [ -f "$persist_dir/hosts.bak" ] && [ "adblock_switch" -eq 1 ]
}

# =========== Main script logic ===========

# symlink rmlwk to manager path
if [ "$KSU" = "true" ]; then
    [ -L "/data/adb/ksud/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ksud/bin/rmlwk" && log_message "symlink created at /data/adb/ksud/bin/rmlwk"
elif [ "$APATCH" = "true" ]; then
    [ -L "/data/adb/apd/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/apd/bin/rmlwk" && log_message "symlink created at /data/adb/apd/bin/rmlwk"
else
    [ -w /sbin ] && magisktmp=/sbin
    [ -w /debug_ramdisk ] && magisktmp=/debug_ramdisk
    ln -sf "$MODDIR/rmlwk.sh" "$magisktmp/rmlwk" && log_message "symlink created at $magisktmp/rmlwk"
fi

# System hosts count
blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
echo "${blocked_sys:-0}" > "$persist_dir/counts/blocked_sys.count"
log_message "System hosts entries count: $blocked_sys"

# Module hosts count
blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
echo "${blocked_mod:-0}" > "$persist_dir/counts/blocked_mod.count"
log_message "Module hosts entries count: $blocked_mod"

# Here goes the part where we actually determine module status
if is_protection_paused; then
    status_msg="Status: Protection is paused ⏸️"
elif [ "$blocked_mod" -gt 10 ]; then
    if [ "$blocked_mod" -ne "$blocked_sys" ]; then # Only for cases if mount is broken between module hosts and system hosts
        status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
    else
        status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains | Last updated: $last_mod"
    fi
elif is_default_hosts; then
    status_msg="Status: Protection is disabled due to reset ❌"
fi

# Apply module status into module description
sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
log_message "$status_msg"

# Check if auto-update is enabled
if [ "$daily_update" = 1 ]; then
    # Check if crond is running
    if ! pgrep -x crond >/dev/null; then
        log_message "Auto-update is enabled, but crond is not running. Starting crond..."
        busybox crond -c "/data/adb/Re-Malwack/auto_update" -L "/data/adb/Re-Malwack/logs/auto_update.log"
        log_message "Crond started."
    else
        log_message "Crond is already running."
    fi
fi