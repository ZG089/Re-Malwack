#!/system/bin/sh

# Variables
MODDIR="/data/adb/modules/Re-Malwack"
HOSTS_FILE="/system/etc/hosts"

while true; do
    # Current timestamp
    string="description=Status: Protection is enabled ✅ | Protection update date: $(date)"

    # Check if hosts file contains blocked entries
    if grep -q '0.0.0.0' "$HOSTS_FILE"; then
        # Update the module description
        sed -i "s/^description=.*/$string/g" "$MODDIR/module.prop"
    else
        # Update the module description if no entries are blocked
        sed -i "s/^description=.*/description=Status: disabled due to no blocked entries ❌/g" "$MODDIR/module.prop"
    fi

    # Wait for 5 minutes before the next refresh
    sleep 300
done
