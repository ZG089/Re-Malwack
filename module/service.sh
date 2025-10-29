#!/system/bin/sh
# This is the service script of Re-Malwack
# It is executed during device boot

# =========== Variables ===========
MODDIR="${0%/*}"
hosts_file="$MODDIR/system/etc/hosts"
persist_dir="/data/adb/Re-Malwack"
system_hosts="/system/etc/hosts"
last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file

# =========== Functions ===========

# Function to check hosts file reset state
# Becomes true in case of both hosts counts = 0
# And becomes also true in case of blocked entries in both module and system hosts equals the blacklist file
# AKA only blacklisted entries are active
is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ] \
    || { [ "$blocked_mod" -eq "$blacklist_count" ] && [ "$blocked_sys" -eq "$blacklist_count" ]; }
}

# Logging function
function log_message() {
    local message="$1"
    touch "$persist_dir/logs/service.log"
    echo "[$(date +"%Y-%m-%d %I:%M:%S %p")] - $message" >> "$persist_dir/logs/service.log"   
}

# function to check adblock pause
function is_protection_paused() {
    [ -f "$persist_dir/hosts.bak" ] && [ "$adblock_switch" -eq 1 ]
}

#  =========== Preparation ===========

# 1 - Sourcing config file
. $persist_dir/config.sh

# 2 - creating logs dir in case if not created
mkdir -p "$persist_dir/logs"
# 3 - Remove previous logs
rm -rf "$persist_dir/logs/"*

# 4 - Log errors
exec 2>>"$persist_dir/logs/service.log"

# 4.1 - Log module version and service start
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
log_message "service.sh Started"
log_message "Re-Malwack Version: $version"

# 5 - System hosts count
blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
echo "${blocked_sys:-0}" > "$persist_dir/counts/blocked_sys.count"
log_message "System hosts entries count: $blocked_sys"

# 6 - Module hosts count
blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
echo "${blocked_mod:-0}" > "$persist_dir/counts/blocked_mod.count"
log_message "Module hosts entries count: $blocked_mod"

# 7 - Count blacklisted entries (excluding comments and empty lines)
blacklist_count=0
[ -s "$persist_dir/blacklist.txt" ] && blacklist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/blacklist.txt")
log_message "Blacklist entries count: $blacklist_count"

# 8 - Count whitelisted entries (excluding comments and empty lines)
whitelist_count=0
[ -f "$persist_dir/whitelist.txt" ] && whitelist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/whitelist.txt")
log_message "Whitelist entries count: $whitelist_count"

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

# Here goes the part where we actually determine module status
if is_protection_paused; then
    status_msg="Status: Protection is paused ⏸️"
elif is_default_hosts; then
    if [ "$blacklist_count" -gt 0 ]; then
        plural="entries are active"
        [ "$blacklist_count" -eq 1 ] && plural="entry is active"
        status_msg="Status: Protection is disabled due to reset ❌ | Only $blacklist_count blacklist $plural"
    else
        status_msg="Status: Protection is disabled due to reset ❌"
    fi
elif [ "$blocked_mod" -ge 0 ]; then
    if [ "$blocked_sys" -eq 0 ] && [ "$blocked_mod" -gt 0 ]; then
        status_msg="Status: ❌ Critical Error Detected (Broken hosts mount). Please check your root manager settings and disable any conflicted module(s)."
    elif [ "$blocked_mod" -ne "$blocked_sys" ]; then # Only for cases if mount is broken between module hosts and system hosts
        status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
    else
        status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains"
        [ "$blacklist_count" -gt 0 ] && status_msg="Status: Protection is enabled ✅ | Blocking $((blocked_mod - blacklist_count)) domains + $blacklist_count (blacklist)"
        [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
        status_msg="$status_msg | Last updated: $last_mod"
    fi
fi

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

# Apply module status into module description
sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
log_message "$status_msg"

