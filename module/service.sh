#!/system/bin/sh

# Logging function
function log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> "/sdcard/Re-Malwack/logs.txt"
}
# Variables
MODDIR="/data/adb/modules/Re-Malwack"
HOSTS_FILE="/system/etc/hosts"
string="description=Status: Protection is enabled ✅ | Last updated: $(date)"

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