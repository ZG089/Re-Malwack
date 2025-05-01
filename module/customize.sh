ui_print "    ____             __  ___      __                    __            "
ui_print "   / __ \___        /  |/  /___ _/ /      ______ ______/ /__          "
ui_print "  / /_/ / _ \______/ /|_/ / __ \`/ / | /| / / __ \`/ ___/ //_/"       
ui_print " / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<             "
ui_print "/_/ |_|\___/     /_/  /_/\__,_/_/ |__/|__/\__,_/\___/_/|_|           "
ui_print " "
ui_print "          Welcome to Re-Malwack installation wizard!               "
sleep 0.2
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.2
ui_print "- ⚙ Module Version: $(grep_prop version $MODPATH/module.prop)"
sleep 0.2
ui_print "- 📱 Device Brand: $(getprop ro.product.brand)"
sleep 0.2
ui_print "- 📱 Device Model: $(getprop ro.product.model)"
sleep 0.2
ui_print "- 🤖 Android Version: $(getprop ro.build.version.release)"
sleep 0.2
ui_print "- ⚙ Device Arch: $(getprop ro.product.cpu.abi)"
sleep 0.2
ui_print "- 🛠 Kernel version: $(uname -r)"
sleep 0.2
ui_print "- ⌛ Current Time: $(date "+%d, %b - %H:%M %Z")"
ui_print ""
sleep 0.2
ui_print "                                    /"
ui_print " ----------------------------------"
ui_print " "


# abort in recovery
if ! $BOOTMODE; then
	abort "! Not supported to install in recovery"
fi

# Check for conflicts
pm list packages | grep -q org.adaway && abort "- Adaway is detected, Please disable to prevent conflicts."

for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    # Skip our own module
    [ "$module_id" == "Re-Malwack" ] && continue

    # Check for conflict by looking for a hosts file in the module
    if [ -f "${module}/system/etc/hosts" ]; then
        # Check if the module is already disabled
        if [ -f "/data/adb/modules/$module_id/disable" ]; then
            continue
        fi
        module_name="$(grep_prop name "${module}/module.prop")"
        ui_print "- Disabling conflicting module: $module_name"
        touch "/data/adb/modules/$module_id/disable"
    fi
done

# let's check do we have internet or not.
ping -c 1 -w 5 google.com &>/dev/null || abort "- This module requires internet connection to download protections."

# Add a persistent directory to save configuration
persistent_dir="/data/adb/Re-Malwack"
config_file="$persistent_dir/config.sh"
types="block_porn block_gambling block_fakenews block_social daily_update"
mkdir -p "$persistent_dir"
touch "$config_file"
for type in $types; do
    grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
done

# Handle source file
if [ ! -s "$persistent_dir/sources.txt" ]; then
    mv -f $MODPATH/common/sources.txt $persistent_dir/sources.txt
else
    rm -f $MODPATH/common/sources.txt

    # Replace previously used compression hosts source if found
    sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt|' $persistent_dir/sources.txt
fi

# set permissions
chmod 755 $MODPATH/rmlwk.sh
chmod 755 $MODPATH/action.sh
chmod 755 "$persistent_dir/config.sh"

# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persistent_dir/logs/*
sh $MODPATH/rmlwk.sh --update-hosts || {
    ui_print "- Failed to initialize hosts files"
    ui_print "- Log saved in /sdcard/Download/Re-Malwack_install_log_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    tar -czvf /sdcard/Download/Re-Malwack_install_log_$(date +%Y-%m-%d_%H%M%S).tar.gz --exclude="$persistent_dir" -C $persistent_dir logs
    abort
}

# Create symlink on install for ksu/ap
manager_paths="/data/adb/ap/bin /data/adb/ksu/bin"
for i in $manager_paths; do
    if [ -d "$i" ]; then
        ln -sf "/data/adb/modules/Re-Malwack/rmlwk.sh" "$i/rmlwk"
    fi
done
