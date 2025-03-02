#!/bin/sh

MODDIR="${0%/*}"
HOSTS_FILE="/system/etc/hosts"
string="description=Status: Protection is enabled ✅ | Last updated: $(date)"
persist_dir="/data/adb/Re-Malwack"

mkdir -p "$persist_dir/logs"
rm -rf "$persist_dir/logs/"*

# Logging function
function log_message() {
    local message="$1"
    touch "$persist_dir/logs/service.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> "$persist_dir/logs/service.log"
}

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

# Check if hosts file contains blocked entries
if grep -q '0.0.0.0' "$HOSTS_FILE"; then
    # Update the module description
    sed -i "s/^description=.*/$string/g" "$MODDIR/module.prop"
    log_message "Protection is enabled ✅ | Last updated: $(date)"

else
    if [ -f "$MODDIR/disable" ]; then
        log_message "Status: Module is disabled"
        string="description=status: Disabled ❌ | $(date)"
        sed -i "s/^description=.*/$string/g" "$MODDIR/module.prop"
        return  # Exit the else block early
    else
        # Update the module description if no entries are blocked
        sed -i "s/^description=.*/description=Status: Protection disabled due to no blocked entries ❌/g" "$MODDIR/module.prop"
        log_message "Status: Protection disabled due to no blocked entries"
    fi
fi