ui_print "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝"
ui_print "    Welcome to Re-Malwack installation wizard!"
sleep 0.2
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.2
ui_print "- ⚙ Module Version: $(grep_prop version $TMPDIR/module.prop)"
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
ui_print "[INSTALLATION BEGINS]"
sleep 0.2

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
config_file="/data/adb/Re-Malwack/config.sh"
types="block_porn block_gambling block_fakenews block_social"
if [ -f "$config_file" ]; then
    for type in $types; do
        grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
    done
else
    mkdir -p "/data/adb/Re-Malwack"
    for type in $types; do
        echo "$type=0"
    done > "$config_file"
fi

mkdir /sdcard/Re-Malwack

# set permissions
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
chmod 755 $MODPATH/action.sh
chmod 755 "/data/adb/Re-Malwack/config.sh"

# Initialize hosts files
ui_print "- Preparing Shields 🛡️"
mkdir -p $MODPATH/system/etc

ui_print "- Preparing weapons to kill malware 🔫"
sh $MODPATH/system/bin/rmlwk --update-hosts

ui_print "- Your device is now armed against ads, malware and more 🛡"
