#!/system/bin/sh
# Re-Malwack Import Sources Script
# All respect for the developers of the mentioned modules/apps in this script.
# ZG089, Re-Malwack founder.

persistent_dir="/data/adb/Re-Malwack"
adaway_json="/sdcard/Download/adaway-backup.json"
import_done=0

# Vol key press detect
detect_key_press() {
    timeout_seconds=7
    total_options=$1
    recommended_option=$2

    current=1
    ui_print "[i] Use Vol+ to switch, Vol- to select. Timeout: $timeout_seconds sec (default: $recommended_option)."

    end=$((SECONDS + timeout_seconds))

    while [ $SECONDS -lt $end ]; do
        event=$(getevent -qlc 1 2>/dev/null)
        case "$event" in
            *KEY_VOLUMEUP*) 
                current=$((current + 1))
                [ "$current" -gt "$total_options" ] && current=1
                ui_print "  > Option $current"
                ;;
            *KEY_VOLUMEDOWN*)
                ui_print "- Selected option: $current"
                return "$current"
                ;;
        esac
    done

    ui_print "[!] Timeout. Auto-selecting option: $recommended_option"
    return "$recommended_option"
}

# bindhosts import
bindhosts_import_sources() {
    bindhosts="/data/adb/bindhosts"
    bindhosts_sources="$bindhosts/sources.txt"
    dest_sources="$persistent_dir/sources.txt"

    ui_print "[i] How do you want to import your setup?"
    sleep 0.5
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    sleep 0.5
    ui_print "1 - Use only bindhosts setup (replace)"
    sleep 0.2
    ui_print "2 - Merge with Re-Malwack's default setup. [RECOMMENDED]"
    sleep 0.2
    ui_print "3 - Cancel"
    sleep 0.2

    detect_key_press 3 2
    choice=$?

    case "$choice" in
        1)
            ui_print "[*] Replacing Re-Malwack setup with bindhosts setup..."
            echo " " > "$dest_sources"
            sed '/^\s*#/d; /^\s*$/d' "$bindhosts_sources" | sort -u > "$dest_sources"
            bindhosts_import_list whitelist replace
            bindhosts_import_list blacklist replace
            ui_print "[✓] Bindhosts setup imported successfully."
            ;;
        2)
            ui_print "[*] Merging bindhosts setup with Re-Malwack's setup"
            grep -Ev '^#|^$' "$bindhosts_sources" | sort -u >> "$dest_sources"
            bindhosts_import_list whitelist merge
            bindhosts_import_list blacklist merge
            ui_print "[✓] Bindhosts setup imported successfully."
            ;;
        3|255) ui_print "[i] Skipped bindhosts import." ;;
        *) ui_print "[!] Invalid selection. Skipping bindhosts import." ;;
    esac
}

bindhosts_import_list() {
    list_type="$1"
    mode="$2"
    bindhosts="/data/adb/bindhosts"
    src="$bindhosts/$list_type.txt"
    dest="$persistent_dir/$list_type.txt"

    [ ! -f "$src" ] && return
    if grep -vq '^\s*#' "$src" && grep -vq '^\s*$' "$src"; then
        ui_print "[i] Detected $list_type file with entries..."
        case "$mode" in
            replace) sed '/^\s*#/d; /^\s*$/d' "$src" | sort -u > "$dest" ;;
            merge)   sed '/^\s*#/d; /^\s*$/d' "$src" | sort -u >> "$dest" ;;
        esac
    fi
}

# cubic import
import_cubic_sources() {
    src_file="$persistent_dir/sources.txt"
    ui_print "[i] How would you like to import cubic-adblock sources?"
    sleep 0.5
    ui_print "1 - Replace Re-Malwack sources with Cubic-Adblock sources"
    sleep 0.2
    ui_print "2 - Merge Cubic-Adblock sources with Re-Malwack default sources [RECOMMENDED]"
    sleep 0.2
    ui_print "3 - No, Do Not Import"
    sleep 0.2

    detect_key_press 3 2
    choice=$?

    case "$choice" in
        1) ui_print "[*] Replacing Re-Malwack sources with Cubic-Adblock..."; echo -n > "$src_file" ;;
        2) ui_print "[*] Merging Cubic-Adblock sources with Re-Malwack..." ;;
        3|255) ui_print "[*] Skipping Cubic-Adblock import."; return ;;
        *) ui_print "[!] Invalid selection. Skipping Cubic-Adblock import."; return ;;
    esac

    # replace pro with ultimate
    if grep -q 'hagezi/dns-blocklists/main/hosts/pro.txt' "$src_file"; then
        ui_print "[*] Replacing Hagezi Pro Plus with Ultimate..."
        sed -i 's|hagezi/dns-blocklists/main/hosts/pro.txt|hagezi/dns-blocklists/main/hosts/ultimate.txt|' "$src_file"
    fi

    # cubic sources
    cat <<EOF | while IFS= read -r url; do
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/malware.hosts?ref_type=heads
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/trackers.hosts?ref_type=heads
https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt
https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts
https://o0.pages.dev/Pro/hosts.txt
EOF
        [ -z "$url" ] && continue
        if grep -Fqx "$url" "$src_file"; then
            ui_print "- Skipped (already present): $url"
        else
            echo "$url" >> "$src_file"
            ui_print "- Imported: $url"
        fi
    done
    ui_print "[✓] Cubic-Adblock sources imported successfully."
}

# AdAway import
import_adaway_data() {
    src_file="$persistent_dir/sources.txt"
    whitelist_file="$persistent_dir/whitelist.txt"
    blacklist_file="$persistent_dir/blacklist.txt"

    ui_print "[i] AdAway Backup has been detected, Do you want to import your setup from it?"
    sleep 0.5
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    sleep 0.5
    ui_print "1 - Yes, But use only AdAway setup"
    sleep 0.2
    ui_print "2 - Yes, Also merge AdAway setup with Re-Malwack's [RECOMMENDED]"
    sleep 0.2
    ui_print "3 - No, Do Not Import."
    sleep 0.2

    detect_key_press 3 2
    choice=$?

    case "$choice" in
        1)
            ui_print "- Replacing Re-Malwack setup with AdAway backup..."
            echo -n > "$src_file" "$whitelist_file" "$blacklist_file"
            ;;
        2) ui_print " [*] Merging AdAway backup with Re-Malwack..." ;;
        3|255) ui_print "- Skipping AdAway import."; return ;;
        *) ui_print "- Invalid selection. Skipping AdAway import."; return ;;
    esac

    # import sources
    grep -A3 '"enabled": true' "$adaway_json" | grep '"url":' | sed 's/.*"url": "\(.*\)",*/\1/' | while read -r url; do
        grep -Fqx "$url" "$src_file" || echo "$url" >> "$src_file"
    done

    # import whitelist
    awk '/"allowed": \[/{flag=1; next} /\]/{flag=0} flag && /"/' "$adaway_json" | sed 's/[^"]*"\([^"]*\)".*/\1/' | while read -r domain; do
        grep -Fqx "$domain" "$whitelist_file" || echo "$domain" >> "$whitelist_file"
    done

    # import blacklist
    awk '/"blocked": \[/{flag=1; next} /\]/{flag=0} flag && /"/' "$adaway_json" | sed 's/[^"]*"\([^"]*\)".*/\1/' | while read -r domain; do
        grep -Fqx "$domain" "$blacklist_file" || echo "$domain" >> "$blacklist_file"
    done

    ui_print "- AdAway import completed."
}

# AdAway import if backup exists
if [ -f "$adaway_json" ]; then
    import_adaway_data
    import_done=1
fi

# Detect other modules and run imports (only if not already imported)
if [ "$import_done" -eq 0 ]; then
    for module in /data/adb/modules/*; do
        module_id="$(grep_prop id "${module}/module.prop")"
        # Skip our own module
        [ "$module_id" = "Re-Malwack" ] && continue
        # Skip disabled modules
        [ -f "/data/adb/modules/$module_id/disable" ] && continue
        if [ -f "${module}/system/etc/hosts" ]; then
            [ "$module_id" = "hosts" ] && touch /data/adb/modules/hosts/disable
            module_name="$(grep_prop name "${module}/module.prop")"
            ui_print "- $module_id detected. Import setup?"
            sleep 0.2
            ui_print "1- YES | 2- NO"
            detect_key_press 2 1
            choice=$?
            case "$choice" in
                1)
                    case "$module_id" in
                        bindhosts) bindhosts_import_sources ;;
                        cubic-adblock) import_cubic_sources ;;
                        StevenBlock) ui_print "[i] StevenBlock sources already included." ;;
                        *) ui_print "[!] Importing from $module_id unsupported." ;;
                    esac
                    import_done=1
                    ;;
                2) ui_print "- Skipped import from $module_id." ;;
                255) ui_print "- Timeout, skipping import from $module_id." ;;
                *) ui_print "- Invalid selection. Skipping import from $module_id." ;;
            esac
            ui_print "[*] Disabling: $module_name"
            touch "/data/adb/modules/$module_id/disable"
            [ "$import_done" -eq 1 ] && break
        fi
    done
fi