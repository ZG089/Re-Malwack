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

# Add a persistent directory to save configuration
ui_print "[*] Preparing Re-Malwack environment"
. "$MODPATH/lib/defs.sh"
. "$MODPATH/lib/util.sh"
rmlwk_prepare_runtime
config_file="$persist_dir/config.sh"

for type in block_porn block_gambling block_fakenews block_social block_trackers block_safebrowsing daily_update adblock_switch action_mode dns_logging; do
    get_prop "$type" "$config_file" >/dev/null 2>&1 || set_prop "$type" "0" "$config_file"
done

touch "$persist_dir/blacklist.txt"
touch "$persist_dir/whitelist.txt"
touch "$persist_dir/custom_rules.txt"

# Migration logic: sources.txt -> custom_source.txt
if [ -f "$persist_dir/sources.txt" ] && [ ! -f "$persist_dir/custom_source.txt" ]; then
    ui_print "[*] Migrating user custom sources to new format..."
    awk '
    /^# OFF # / { url = $4 }
    $1 !~ /^#/ { url = $1 }
    {
        if (url != "") {
            print $0 >> "'"$persist_dir"'/custom_source.txt"
        }
        url = ""
    }'"$persist_dir/sources.txt"
    
    ui_print "[✓] Custom sources migrated to custom_source.txt"
fi

touch "$persist_dir/custom_source.txt"

detect_key_press() {
    timeout_seconds=10
    total_options=${1:-2}
    recommended_option=${2:-1}

    current=1
    start_time=$(date +%s)

    ui_print "[i] Vol+ = switch, Vol- = select (timeout ${timeout_seconds}s, default: $recommended_option)"
    ui_print "Current choice: $current"

    while :; do
        now=$(date +%s)
        if [ $((now - start_time)) -ge "$timeout_seconds" ]; then
            ui_print "[!] Timeout. Auto-selecting option: $recommended_option"
            return "$recommended_option"
        fi

        # Block until we get any input
        ev="$(getevent -qlc 1 2>/dev/null)" || continue

        case "$ev" in
            *KEY_VOLUMEUP*DOWN*)
                current=$((current + 1))
                [ "$current" -gt "$total_options" ] && current=1
                ui_print "- Current choice: $current"
                ;;

            *KEY_VOLUMEDOWN*DOWN*)
                ui_print "- Selected option: $current"
                return "$current"
                ;;

            # Ignore other noise
            *) : ;;
        esac
    done
}

# set permissions
chmod +x $MODPATH/*.sh
chmod +x $MODPATH/lib/*.sh

# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persist_dir/logs/* 2>/dev/null
rm -rf $persist_dir/cache/* 2>/dev/null

mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ -z "$mem_kb" ]; then
    mem_kb=4000000
fi

if [ "$mem_kb" -lt 3145728 ]; then
    detected_profile="lite"
elif [ "$mem_kb" -lt 6291456 ]; then
    detected_profile="balanced"
else
    detected_profile="aggressive"
fi

current_profile=$(get_prop profile "$config_file")

if [ -z "$current_profile" ]; then
    ui_print "[*] Auto-selected profile: $detected_profile"
    set_prop profile "$detected_profile" "$config_file"
else
    ui_print "[*] Current profile: $current_profile"
fi

# Import from other ad-block modules (All respect to other ad-block modules developers)
. $MODPATH/import.sh

if ping -c 1 -w 5 8.8.8.8 &>/dev/null; then
    # Initialize
    . $persist_dir/config.sh
    [ "$adblock_switch" -eq 1 ] && {
        echo "[i] Detected adblock pause, auto resuming before updating hosts..."
        mv -f "$persist_dir/hosts.bak" "/data/adb/modules/Re-Malwack/system/etc/hosts"
        set_prop adblock_switch 0 "$persist_dir/config.sh"
    }
    if ! sh $MODPATH/rmlwk.sh --update-hosts --quiet; then
        ui_print "[✗] Failed to initialize script"
        module_version=$(grep_prop version $MODPATH/module.prop | tr -d '\r')

        # Strip any -test suffix for the filename
        clean_version=$(echo "$module_version" | sed 's/-test.*//')

        # Check if there is a build id (-test_hash@branch)
        if echo "$module_version" | grep -q "\-test_"; then
            build_id=$(echo "$module_version" | sed 's/.*-test_\(.*\)/\1/')
            tarFileName="/sdcard/Download/Re-Malwack_${clean_version}_${build_id}_install_log_$(date +%Y-%m-%d_%H%M%S).tgz"
        else
            tarFileName="/sdcard/Download/Re-Malwack_${clean_version}_install_log_$(date +%Y-%m-%d_%H%M%S).tgz"
        fi

        tar -czf "$tarFileName" -C "$persist_dir" logs
        # cleanup in case of failure (in worst cases on first install)
        [ -d /data/adb/modules/Re-Malwack ] || rm -rf /data/adb/Re-Malwack
        abort "[i] Logs are saved in ${tarFileName}"
    fi
else
    ui_print "[i] No internet connection, skipping hosts initialization. You may initialize it later after reboot."
    # In case of module update without internet while there's an existing hosts file
        # We don't want to delete user's existing hosts file, so we just move it to the new location if it exists
        # otherwise we just create an empty hosts file to prevent potential issues.
    if [ ! -f /data/adb/modules/Re-Malwack/system/etc/hosts ]; then
        printf "127.0.0.1 localhost\n::1 localhost" > $MODPATH/system/etc/hosts
        status_msg="Status: Awaiting reboot 🔃"
        touch "$persist_dir/mode_ready"
    else
        ui_print "[*] migrating existing hosts file to module directory"
        mv -f /data/adb/modules/Re-Malwack/system/etc/hosts $MODPATH/system/etc/hosts
        status_msg="Status: Reboot required to apply updates 🔃"
    fi
    chmod 0644 $MODPATH/system/etc/hosts
    sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
fi

# Create symlink on install for ksu/ap
for i in /data/adb/ap/bin /data/adb/ksu/bin; do
    [ -d "$i" ] && ln -sf "/data/adb/modules/Re-Malwack/rmlwk.sh" "$i/rmlwk"
done

# Zygisk Setup
. "$config_file"
if [ "$dns_logging" = "1" ] && [ -d "$MODPATH/zygisk_opt" ]; then
    ui_print "[*] Preparing Zygisk binaries..."
    mv "$MODPATH/zygisk_opt" "$MODPATH/zygisk"
fi

# Cleanup
rm -f $MODPATH/import.sh && rm -rf $MODPATH/bin