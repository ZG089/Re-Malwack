#!/system/bin/sh
# Re-Malwack Import Sources Script
# ALL respect for the developers of the mentioned modules/apps in this script.
# ZG089, Re-Malwack founder.

# ====== Variables ======
ABI="$(getprop ro.product.cpu.abi)"
PATH="$MODPATH/bin/$ABI:$PATH"
persistent_dir="/data/adb/Re-Malwack"
adaway_json="/sdcard/Download/adaway-backup.json"
import_done=0

# ====== Functions ======

# 1 - Vol key press detect
detect_key_press() {
    timeout_seconds=10
    total_options=$1
    recommended_option=$2
    [ -z "$total_options" ] && total_options=2
    [ -z "$recommended_option" ] && recommended_option=2

    current=1
    ui_print "[i] Use Vol+ to switch, Vol- to select. Timeout: $timeout_seconds sec (default: option $recommended_option)."
    ui_print "Current choice: $current"

    while :; do
        # Wait for a single input event with timeout
        ev="$(timeout "$timeout_seconds" getevent -qlc 1 2>/dev/null)"
        rc=$?

        # Timeout -> auto-select recommended option
        if [ "$rc" -ne 0 ] || [ -z "$ev" ]; then
            ui_print "[!] Timeout. Auto-selecting option: $recommended_option"
            return "$recommended_option"
        fi

        case "$ev" in
            # Volume Up PRESSED -> move selection (wrap), then wait for release
            *KEY_VOLUMEUP*1*|*KEY_VOLUMEUP*DOWN*)
                current=$(( current + 1 ))
                [ "$current" -gt "$total_options" ] && current=1
                ui_print "- Current choice: $current"
                # Flush until release
                while :; do
                    ev2="$(getevent -qlc 1 2>/dev/null)" || break
                    case "$ev2" in *KEY_VOLUMEUP*0*|*KEY_VOLUMEUP*UP*) break ;; esac
                done
                ;;

            # Volume Down PRESSED -> select current, then wait for release
            *KEY_VOLUMEDOWN*1*|*KEY_VOLUMEDOWN*DOWN*)
                ui_print "- Selected option: $current"
                # Flush until release
                while :; do
                    ev2="$(getevent -qlc 1 2>/dev/null)" || break
                    case "$ev2" in *KEY_VOLUMEDOWN*0*|*KEY_VOLUMEDOWN*UP*) break ;; esac
                done
                return "$current"
                ;;

            # Ignore other noise
            *) : ;;
        esac
    done
}

# 2 - Dedup helper function
dedup_file() {
    file="$@"
    for i in $file; do
        [ -f "$i" ] || continue;
        awk '!seen[$0]++' "$i" > "$i.tmp" && mv "$i.tmp" "$i"
    done
}

# 3 - bindhosts import
bindhosts_import() {
    bindhosts="/data/adb/bindhosts"
    bindhosts_sources="$bindhosts/sources.txt"
    dest_sources="$persistent_dir/sources.txt"

    ui_print "[i] How do you want to import your setup?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Use only bindhosts setup (replace)"
    ui_print "2 - Merge with Re-Malwack's default setup. [RECOMMENDED]"
    ui_print "3 - Skip importing. (Do not Import)"
    detect_key_press 3 2
    choice=$?
    sources_count=0
    whitelist_count=0
    blacklist_count=0

    case "$choice" in
        1)
            ui_print "[*] Replacing Re-Malwack setup with bindhosts setup..."
            echo " " > "$dest_sources"
            sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$bindhosts_sources" > "$dest_sources"
            sources_count=$(grep -c "$dest_sources")
            bindhosts_import_helper whitelist replace && whitelist_count=$(wc -l < "$persistent_dir/whitelist.txt")
            bindhosts_import_helper blacklist replace && blacklist_count=$(wc -l < "$persistent_dir/blacklist.txt")
            ;;
        2)
            ui_print "[*] Merging bindhosts setup with Re-Malwack's setup"
            grep -Ev '^[[:space:]]*#|^[[:space:]]*$' "$bindhosts_sources" >> "$dest_sources"
            sources_count=$(grep -vc '^[[:space:]]*#|^[[:space:]]*$' "$bindhosts_sources")
            bindhosts_import_helper whitelist merge && whitelist_count=$(wc -l < "$persistent_dir/whitelist.txt")
            bindhosts_import_helper blacklist merge && blacklist_count=$(wc -l < "$persistent_dir/blacklist.txt")
            ;;
        3|255) ui_print "[i] Skipped bindhosts import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped bindhosts import."; return ;;
    esac

    ui_print "[✓] Bindhosts setup imported successfully."
    ui_print "[i] Imported: $sources_count sources, $whitelist_count whitelist entries, $blacklist_count blacklist entries."
}

# 3.1 - bindhosts import helper
bindhosts_import_helper() {
    list_type="$1"
    mode="$2"
    bindhosts="/data/adb/bindhosts"
    src="$bindhosts/$list_type.txt"
    dest="$persistent_dir/$list_type.txt"

    [ ! -f "$src" ] && return
    if grep -vq '^[[:space:]]*#' "$src" && grep -vq '^[[:space:]]*$' "$src"; then
        ui_print "[i] Detected $list_type file with entries..."
        case "$mode" in
            replace) sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$src" > "$dest" ;;
            merge)   sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$src" >> "$dest" ;;
        esac
    fi
}

# 4 - cubic-adblock import
import_cubic_sources() {
    src_file="$persistent_dir/sources.txt"
    ui_print "[i] How would you like to import cubic-adblock hosts sources?"
    ui_print "1 - Replace default"
    ui_print "2 - Merge with default sources [RECOMMENDED]"
    ui_print "3 - Skip importing. (Do not Import)"

    detect_key_press 3 2
    choice=$?
    sources_added=0
    skipped=0

    case "$choice" in
        1) ui_print "[*] Replacing default..."; : > "$src_file" ;;
        2) ui_print "[*] Merging..." ;;
        3|255) ui_print "[i] Skipped Cubic-Adblock import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped Cubic-Adblock import."; return ;;
    esac

    # replace Hagezi pro with ultimate
    if grep -q 'https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt' "$src_file"; then
        ui_print "[*] Replacing Hagezi Pro Plus hosts with Ultimate version."
        sed -i 's|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt|https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt|' "$src_file"
    fi

    # cubic-adblock sources
    while IFS= read -r url; do
        [ -z "$url" ] && continue
        if grep -Fq "$url" "$src_file"; then
            ui_print "[!] Skipped (already present): $url"
            skipped=$((skipped + 1))
        else
            echo "$url" >> "$src_file"
            ui_print "[✓] Imported: $url"
            sources_added=$((sources_added + 1))
        fi
    done <<EOF
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/malware.hosts?ref_type=heads
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/trackers.hosts?ref_type=heads
https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt
https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt
EOF
    ui_print "[✓] Cubic-Adblock sources imported successfully."
    ui_print "[i] Imported: $sources_added new sources, Skipped: $skipped, Total processed: $((sources_added + skipped))."
}

# 5 - AdAway import
import_adaway_data() {
    src_file="$persistent_dir/sources.txt"
    whitelist_file="$persistent_dir/whitelist.txt"
    blacklist_file="$persistent_dir/blacklist.txt"

    ui_print "[i] AdAway Backup file has been detected."
    ui_print "[i] Do you want to import your setup from it?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Yes, But use only AdAway setup (replace)"
    ui_print "2 - Yes, Also merge AdAway setup with Re-Malwack's [RECOMMENDED]"
    ui_print "3 - No, Do Not Import."

    detect_key_press 3 2
    choice=$?

    case "$choice" in
        1)
            ui_print "[*] Applying AdAway setup..."
            : > "$src_file"
            : > "$whitelist_file"
            : > "$blacklist_file"
            ;;
        2) ui_print "[*] Merging AdAway setup..." ;;
        3|255) ui_print "[i] Skipped AdAway import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped AdAway import."; return ;;
    esac

    # Import enabled sources
    tmp_sources="$persistent_dir/tmp.sources.$$"
    jq -r '.sources[] | select(.enabled == true) | .url' "$adaway_json" > "$tmp_sources"
    sources_count=0
    while IFS= read -r url; do
        [ -n "$url" ] || continue
        if ! grep -Fqx "$url" "$src_file"; then
            echo "$url" >> "$src_file"
            sources_count=$((sources_count + 1))
        fi
    done < "$tmp_sources"
    rm -f "$tmp_sources"

    # Import enabled whitelist
    tmp_white="$persistent_dir/tmp.white.$$"
    jq -r '.allowed[] | select(.enabled == true) | .host' "$adaway_json" > "$tmp_white"
    whitelist_count=0
    while IFS= read -r domain; do
        [ -n "$domain" ] || continue
        if ! grep -Fqx "$domain" "$whitelist_file"; then
            echo "$domain" >> "$whitelist_file"
            whitelist_count=$((whitelist_count + 1))
        fi
    done < "$tmp_white"
    rm -f "$tmp_white"

    # Import enabled blacklist
    tmp_black="$persistent_dir/tmp.black.$$"
    jq -r '.blocked[] | select(.enabled == true) | .host' "$adaway_json" > "$tmp_black"
    blacklist_count=0
    while IFS= read -r domain; do
        [ -n "$domain" ] || continue
        if ! grep -Fqx "$domain" "$blacklist_file"; then
            echo "$domain" >> "$blacklist_file"
            blacklist_count=$((blacklist_count + 1))
        fi
    done < "$tmp_black"
    rm -f "$tmp_black"

    ui_print "[✓] AdAway import completed."
    ui_print "[i] Imported: $sources_count sources, $whitelist_count whitelist entries, $blacklist_count blacklist entries."
}

# ====== Main Script ======

# Exec perms for jq
chmod +x $MODPATH/bin/$ABI/jq
# AdAway import if backup exists
if [ -f "$adaway_json" ]; then
    import_adaway_data
    import_done=1
fi

# Detect other modules and run imports (only if not already imported)
for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    module_name="$(grep_prop name "${module}/module.prop")"
    # skip if we got into our own module or any other module that 
    # is disabled already.
    if [ "${module_id}" == "Re-Malwack" ] || [ -f "/data/adb/modules/$module_id/disable" ] || [ ! -f "/data/adb/modules/$module_id/system/etc/hosts" ]; then
        continue;
    fi
    # force disable systemless hosts module
    [ "$module_id" = "hosts" ] && touch /data/adb/modules/hosts/disable
    if [ "$import_done" -eq 0 ]; then
        ui_print "[i] $module_name detected. Import setup?"
        ui_print "1 - YES | 2 - NO"
        detect_key_press 2 1
        choice=$?
        case "$choice" in
            1)
                case "$module_id" in
                    bindhosts)
                        bindhosts_import
                    ;;
                    cubic-adblock)
                        import_cubic_sources
                    ;;

                    *)
                        ui_print "[!] Importing from $module_id unsupported."
                    ;;
                esac
                # i feel like this variable does nothing - @bocchi-the-dev
                import_done=1
            ;;
            2)
                ui_print "[i] Skipped import from $module_id."
            ;;
            255)
                ui_print "[!] Timeout, skipping import from $module_id."
            ;;
            *)
                ui_print "[!] Invalid selection. Skipping import from $module_id."
            ;;
        esac
    fi
    # Always disable module, even if already imported
    ui_print "[*] Disabling: $module_name"
    touch "/data/adb/modules/$module_id/disable"
done

# Dedup everything at the end just in case
dedup_file $persistent_dir/{sources,whitelist,blacklist}.txt