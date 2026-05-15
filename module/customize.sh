ui_print '          ____            __         __  '
ui_print '         / __ \____ ___  / /      __/ /__'
ui_print '        / /_/ / __ `__ \/ / | /| / / //_/'
ui_print '       / _, _/ / / / / / /| |/ |/ / ,<   '
ui_print '      /_/ |_/_/ /_/ /_/_/ |__/|__/_/|_|  '                   
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
persistent_dir="/data/adb/Re-Malwack"
config_file="$persistent_dir/config.sh"
if [ ! -d /data/adb/modules/Re-Malwack ]; then # if module not installed
    mkdir -p "$persistent_dir"
    touch "$persistent_dir/first_install_flag"
fi
mkdir -p "$persistent_dir/profiles"
touch "$config_file"
for type in block_porn block_gambling block_fakenews block_social block_trackers block_safebrowsing daily_update adblock_switch action_mode dns_logging; do
    grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
    touch "$persistent_dir/blacklist.txt"
    touch "$persistent_dir/whitelist.txt"
done

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


# Initialize hosts files
mkdir -p $MODPATH/system/etc
rm -rf $persistent_dir/logs/* 2>/dev/null
rm -rf $persistent_dir/cache/* 2>/dev/null

update_profile() {
    local prof_file="$1"
    local dest_file="$2"
    local profile_name="$3"
    
    if [ ! -s "$dest_file" ]; then
        cp -f "$prof_file" "$dest_file"
    else
        # Stage 1 & 2: Preserve OFF states from current sources.txt and apply to new profile
        awk '
        NR==FNR {
            if (/^# OFF # /) {
                off_urls[$4] = 1
            }
            next
        }
        {
            if (/^# OFF # /) {
                url = $4
            } else if ($1 !~ /^#/) {
                url = $1
                if (off_urls[url] == 1) {
                    $0 = "# OFF # " $0
                }
            } else {
                url = ""
            }
            
            if (url == "") {
                print $0
                next
            }
            
            if (!seen[url]++) {
                print $0
            }
        }
        ' "$dest_file" "$prof_file" > "${dest_file}.tmp"
        
        mv -f "${dest_file}.tmp" "$dest_file"
    fi

    # Stage 3: Apply customizations (removed and added sources)
    if [ -s "$persistent_dir/profiles/${profile_name}_removed.txt" ]; then
        awk '
        NR==FNR {
            dom = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
            removed[dom] = 1;
            next;
        }
        {
            dom = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
            if (!(dom in removed)) print $0;
        }' "$persistent_dir/profiles/${profile_name}_removed.txt" "$dest_file" > "${dest_file}.tmp"
        mv "${dest_file}.tmp" "$dest_file"
    fi
    if [ -s "$persistent_dir/profiles/${profile_name}_added.txt" ]; then
        [ -s "$dest_file" ] && tail -c1 "$dest_file" | grep -qv $'\n' && echo "" >> "$dest_file"
        cat "$persistent_dir/profiles/${profile_name}_added.txt" >> "$dest_file"
    fi
}

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

current_profile=$(grep "^profile=" "$config_file" 2>/dev/null | cut -d= -f2)

if [ "$current_profile" = "custom" ] && [ -f "$persistent_dir/sources.txt" ]; then
    mkdir -p "$persistent_dir/profiles"
    cp -f "$persistent_dir/sources.txt" "$persistent_dir/profiles/legacy_custom.txt"
    sed -i "s/^profile=.*/profile=legacy_custom/" "$config_file"
    current_profile="legacy_custom"
    ui_print "[*] Migrated legacy 'custom' profile to 'legacy_custom'"
fi

# Import from other ad-block modules (All respect to other ad-block modules developers)
. $MODPATH/import.sh

if [ "$import_done" != "1" ]; then
    if [ -z "$current_profile" ]; then
        cp -f "$MODPATH/profiles/${detected_profile}.txt" "$persistent_dir/sources.txt"
        if grep -q "^profile=" "$config_file"; then
            sed -i "s/^profile=.*/profile=$detected_profile/" "$config_file"
        else
            echo "profile=$detected_profile" >> "$config_file"
        fi
        ui_print "[✓] Auto-selected profile: $detected_profile"
    else
        if [ -f "$MODPATH/profiles/${current_profile}.txt" ]; then
            update_profile "$MODPATH/profiles/${current_profile}.txt" "$persistent_dir/sources.txt" "$current_profile"
            ui_print "[*] Updating hosts sources for your $current_profile profile."
        elif [ -f "$persistent_dir/profiles/${current_profile}.txt" ]; then
            ui_print "[*] Keeping existing custom profile: $current_profile"
        else
            ui_print "[!] Detected missing profile $current_profile, reverting to $detected_profile."
            cp -f "$MODPATH/profiles/${detected_profile}.txt" "$persistent_dir/sources.txt"
            if grep -q "^profile=" "$config_file"; then
                sed -i "s/^profile=.*/profile=$detected_profile/" "$config_file"
            else
                echo "profile=$detected_profile" >> "$config_file"
            fi
        fi
    fi
fi

awk '
{
    if (/^# OFF # /) {
        url = $4
    } else if ($1 !~ /^#/) {
        url = $1
    } else {
        url = ""
    }
    
    if (url == "") {
        print $0
        next
    }
    
    if (!seen[url]++) {
        print $0
    }
}' "$persistent_dir/sources.txt" > "$persistent_dir/sources.txt.tmp"
mv -f "$persistent_dir/sources.txt.tmp" "$persistent_dir/sources.txt"

# Initialize
. $config_file
[ "$adblock_switch" -eq 1 ] && {
    ui_print "[i] Detected adblock pause, auto resuming before updating hosts..."
    mv -f "$persistent_dir/hosts.bak" "/data/adb/modules/Re-Malwack/system/etc/hosts"
    sed -i "s/^adblock_switch=1/adblock_switch=0/" $persistent_dir/config.sh
}

# First time installation
if [ ! -d /data/adb/modules/Re-Malwack ]; then
    # Check internet connection
    if ping -c 1 -w 5 8.8.8.8 &>/dev/null; then
        ui_print "[i] Initializing hosts for first time installation 🏰"
        if ! sh $MODPATH/rmlwk.sh --update-hosts --quiet; then
            ui_print "[✗] Failed to initialize script"
            # Extract version from module.prop
            module_version=$(grep_prop version $MODPATH/module.prop)
            # Check if it's a test release and extract PR/commit info
            if echo "$module_version" | grep -q "\-test.*(.*@.*)"; then
                # Extract base version commit hash & branch (ex: 5ex77xx@main) from version string
                base_version=$(echo "$module_version" | sed 's/-test.*//')
                build_id=$(echo "$module_version" | sed 's/.*(\(.*\)).*/\1/' | sed 's/\//_/g')
                tarFileName="/sdcard/Download/Re-Malwack_${base_version}-${build_id}_install_log_$(date +%Y-%m-%d_%H%M%S).tgz"
            else
                # Regular release version
                clean_version=$(echo "$module_version" | sed 's/\//_/g')
                tarFileName="/sdcard/Download/Re-Malwack_${clean_version}_install_log_$(date +%Y-%m-%d_%H%M%S).tgz"
            fi
            # Bundle all logs and zip them
            tar -czvf "${tarFileName}" --exclude="$persistent_dir" -C $persistent_dir logs
            # cleanup in case of failure
            rm -rf /data/adb/Re-Malwack 2>/dev/null
            abort "[i] Logs are saved in ${tarFileName}"
        fi
    else
        ui_print "[i] No internet connection, skipping hosts initialization."
        ui_print "[i] It is recommended to initialize hosts update after reboot."
        # Create empty hosts file
        printf "127.0.0.1 localhost\n::1 localhost" > $MODPATH/system/etc/hosts
        status_msg="Status: Reboot required [Offline Mode] 🔃"
        touch "$persistent_dir/mode_ready"
        sed -i "s/^description=.*/description=$status_msg/" "$MODPATH/module.prop"
    fi
else
    ui_print "[*] migrating existing hosts file to module directory"
    mv -f /data/adb/modules/Re-Malwack/system/etc/hosts $MODPATH/system/etc/
    status_msg="Status: Reboot required to apply module updates 🔃"
    sed -i "s/^description=.*/description=$status_msg/" "$MODPATH/module.prop"
fi
chmod 0644 $MODPATH/system/etc/hosts

# Create symlink on install for ksu/ap
for i in /data/adb/ap/bin /data/adb/ksu/bin; do
    [ -d "$i" ] && ln -sf "$MODPATH/rmlwk.sh" "$i/rmlwk"
done

# Zygisk Setup
if [ "$dns_logging" = "1" ] && [ -d "$MODPATH/zygisk_opt" ]; then
    ui_print "[*] Preparing Zygisk binaries..."
    mv "$MODPATH/zygisk_opt" "$MODPATH/zygisk"
fi

# Cleanup
rm -f $MODPATH/import.sh && rm -rf $MODPATH/bin