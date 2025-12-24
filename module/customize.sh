ui_print '           ____            __         __  '
ui_print '          / __ \____ ___  / /      __/ /__'
ui_print '         / /_/ / __ `__ \/ / | /| / / //_/'
ui_print '        / _, _/ / / / / / /| |/ |/ / ,<   '
ui_print '       /_/ |_/_/ /_/ /_/_/ |__/|__/_/|_|  '                   
ui_print " "
ui_print "   Welcome to Re-Malwack installation wizard!"
sleep 0.2
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.2
ui_print "- ⚙️ Module Version: $(grep_prop version $MODPATH/module.prop)"
sleep 0.2
ui_print "- 📱 Device Brand: $(getprop ro.product.brand)"
sleep 0.2
ui_print "- 📱 Device Model: $(getprop ro.product.model)"
sleep 0.2
ui_print "- 🤖 Android Version: $(getprop ro.build.version.release)"
sleep 0.2
ui_print "- 🏹 Device Arch: $(getprop ro.product.cpu.abi)"
sleep 0.2
ui_print "- 🛠 Kernel version: $(uname -r)"
sleep 0.2

# Detect Root Manager
root_manager=""
root_version=""
command -v magisk >/dev/null 2>&1 && root_manager="Magisk/Variants" && root_version="$MAGISK_VER"
[ "$KSU" = "true" ] && root_manager="KernelSU" && root_version="$KSU_VER_CODE"
[ "$APATCH" = "true" ] && root_manager="APatch" && root_version="$(cat "/data/adb/ap/version")"

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

# abort in recovery
$BOOTMODE || abort "[!] Not supported to install in recovery"

# check if adaway is detected or not.
pm list packages | grep -q org.adaway && abort "[✗] Adaway detected, Please uninstall to prevent conflicts, backup your setup optionally before uninstalling in case you want to import your setup."

# let's check do we have internet or not.
ping -c 1 -w 5 8.8.8.8 &>/dev/null || abort "[✗] Failed to connect to the internet"

# Add a persistent directory to save configuration
ui_print "[*] Preparing Re-Malwack environment"
persistent_dir="/data/adb/Re-Malwack"
config_file="$persistent_dir/config.sh"
mkdir -p "$persistent_dir"
touch "$config_file"
for type in block_porn block_gambling block_fakenews block_social block_trackers daily_update adblock_switch; do
    grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
done

# Import from other ad-block modules (All respect to other ad-block modules developers)
. $MODPATH/import.sh

# set permissions
chmod 0755 $persistent_dir/config.sh $MODPATH/action.sh $MODPATH/rmlwk.sh $MODPATH/uninstall.sh

# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persistent_dir/logs/* 2>/dev/null
rm -rf $persistent_dir/cache/* 2>/dev/null


# Handle hosts sources file
# Function to add URL only if it doesn't exist
add_url_if_not_exists() {
    local url="$1"
    if ! grep -q "^$url$" "$persistent_dir/sources.txt"; then
        echo "$url" >> "$persistent_dir/sources.txt"
    fi
}
if [ ! -s "$persistent_dir/sources.txt" ]; then
    mv -f $MODPATH/common/sources.txt $persistent_dir/sources.txt
else
    rm -f $MODPATH/common/sources.txt
    # update sources
    sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt|' $persistent_dir/sources.txt
    sed -i 's|https://o0.pages.dev/Pro/hosts.txt|https://badmojr.github.io/1Hosts/Lite/hosts.txt|' $persistent_dir/sources.txt
    add_url_if_not_exists "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.tiktok.txt"
    add_url_if_not_exists "https://hosts.rem01gaming.dev/adblock"
    add_url_if_not_exists "https://blocklistproject.github.io/Lists/ads.txt"
fi

# Initialize
if ! sh $MODPATH/rmlwk.sh --update-hosts --quiet; then
    ui_print "[✗] Failed to initialize script"
    tarFileName="/sdcard/Download/Re-Malwack_install_log_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    tar -czvf ${tarFileName} --exclude="$persistent_dir" -C $persistent_dir logs
    # cleanup in case of failure (in worst cases on first install)
    [ -d /data/adb/modules/Re-Malwack ] || rm -rf /data/adb/Re-Malwack
    abort "[i] Logs are saved in ${tarFileName}"
fi

# Create symlink on install for ksu/ap
for i in /data/adb/ap/bin /data/adb/ksu/bin; do
    [ -d "$i" ] && ln -sf "/data/adb/modules/Re-Malwack/rmlwk.sh" "$i/rmlwk"
done

# Cleanup
rm -f $MODPATH/import.sh