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

# Detect Root Manager 
root_manager=""
root_version=""
if command -v magisk >/dev/null 2>&1; then
    root_manager="Magisk/Variants"
    root_version="$(magisk -v 2>/dev/null)"
elif command -v ksud >/dev/null 2>&1; then
    root_manager="KernelSU/Variants"
    root_version="$(ksud -V 2>/dev/null | awk '{print $2}')"
elif command -v apd >/dev/null 2>&1 || [ -f "/data/adb/ap/bin/apd" ]; then
    root_manager="APatch"
    root_version="$(/data/adb/ap/bin/apd --version 2>/dev/null | head -n 1)"
else
    root_manager="Unknown"
    root_version=""
fi
# Output
if [ -n "$root_version" ]; then
    ui_print "- 🔓 Root Manager: $root_manager ($root_version)"
else
    ui_print "- 🔓 Root Manager: $root_manager"
fi
sleep 0.2
ui_print "- ⌛ Current Time: $(date "+%d, %b - %H:%M %Z")"
sleep 0.2
ui_print ""
sleep 0.2
ui_print "                                    /"
ui_print " ----------------------------------"
ui_print " "

# abort if we are in recovery mode.
[ $BOOTMODE == true ] || abort "[✗] Not supported to install in recovery"

# check if adaway is detected or not.
pm list packages | grep -q org.adaway && abort "[✗] Adaway is detected, Please uninstall it to prevent conflicts."

# iterrate throughout the /data/adb/modules and
# - Skip if we stumbled upon on our own module
# - And skip if the module is disabled.
for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    [ "$module_id" == "Re-Malwack" ] && continue
    if [ -f "${module}/system/etc/hosts" ]; then
        [ -f "/data/adb/modules/$module_id/disable" ] && continue
        module_name="$(grep_prop name "${module}/module.prop")"
        touch "/data/adb/modules/$module_id/disable"
        ui_print "[i] Disabled conflicting module: $module_name"
    fi
done

# let's check do we have internet or not.
ping -c 1 -w 5 8.8.8.8 &>/dev/null || abort "[✗] Failed to connect to the internet"

# Add a persistent directory to save configuration
ui_print "[*] Preparing Re-Malwack environment"
persistent_dir="/data/adb/Re-Malwack"
config_file="$persistent_dir/config.sh"
mkdir -p "$persistent_dir"
touch "$config_file"
for type in block_porn block_gambling block_fakenews block_social daily_update adblock_switch; do
    grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
done

# Handle source file
if [ ! -s "$persistent_dir/sources.txt" ]; then
    mv -f $MODPATH/common/sources.txt $persistent_dir/sources.txt
else
    rm -f $MODPATH/common/sources.txt
    # Replace some hosts sources with recommended ones
    sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/multi.txt|' $persistent_dir/sources.txt
    sed -i 's|https://o0.pages.dev/Pro/hosts.txt|https://badmojr.github.io/1Hosts/Lite/hosts.txt|' $persistent_dir/sources.txt
fi

# set permissions
chmod 0755 $persistent_dir/config.sh $MODPATH/action.sh $MODPATH/rmlwk.sh $MODPATH/uninstall.sh

# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persistent_dir/logs/* 2>/dev/null
rm -rf $persistent_dir/cache/* 2>/dev/null
if ! sh $MODPATH/rmlwk.sh --update-hosts --quiet; then
    ui_print "[✗] Failed to initialize host files"
    tarFileName="/sdcard/Download/Re-Malwack_install_log_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    tar -czvf ${tarFileName} --exclude="$persistent_dir" -C $persistent_dir logs
    abort "[i] Logs are saved in ${tarFileName}"
fi

# Create symlink on install for ksu/ap
for i in /data/adb/ap/bin /data/adb/ksu/bin; do
    [ -d "$i" ] && ln -sf "/data/adb/modules/Re-Malwack/rmlwk.sh" "$i/rmlwk"
done
