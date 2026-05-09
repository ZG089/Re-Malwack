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

# 1 - Dedup helper function
dedup_file() {
    file="$@"
    for i in $file; do
        [ -f "$i" ] || continue;
        awk '!seen[$0]++' "$i" > "$i.tmp" && mv "$i.tmp" "$i"
    done
}

# 2 - bindhosts import
bindhosts_import() {
    bindhosts="/data/adb/bindhosts"
    bindhosts_sources="$bindhosts/sources.txt"
    dest_sources="$persistent_dir/sources.txt"

    ui_print "[i] How do you want to import your setup?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Use only bindhosts setup (replace)"
    ui_print "2 - Skip importing. (Do not Import)"
    detect_key_press 2 1
    choice=$?
    sources_count=0
    whitelist_count=0
    blacklist_count=0
    custom_count=0

    case "$choice" in
        1)
            ui_print "[*] Replacing Re-Malwack setup with bindhosts setup..."
            echo " " > "$dest_sources"
            sources_to_add=$(grep -Ev '^[[:space:]]*#|^[[:space:]]*$' "$bindhosts_sources")
            echo "$sources_to_add" > "$dest_sources"
            sources_count=$(echo "$sources_to_add" | grep -Evc '^[[:space:]]*#|^[[:space:]]*$' 2>/dev/null || true)
            bindhosts_import_helper whitelist replace && whitelist_count=$(wc -l < "$persistent_dir/whitelist.txt")
            bindhosts_import_helper blacklist replace && blacklist_count=$(wc -l < "$persistent_dir/blacklist.txt")
            bindhosts_import_helper custom replace && custom_count=$(wc -l < "$persistent_dir/custom_rules.txt")
            ;;
        2|255) ui_print "[i] Skipped bindhosts import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped bindhosts import."; return ;;
    esac

    ui_print "[✓] Bindhosts setup imported successfully."
    ui_print "[i] Imported: $sources_count sources, $whitelist_count whitelist entries, $blacklist_count blacklist entries, $custom_count custom rules."
    
    # Create profile
    mkdir -p "$persistent_dir/profiles"
    cp -f "$dest_sources" "$persistent_dir/profiles/bindhosts.txt"
    sed -i '1i# DESC: Imported setup from bindhosts' "$persistent_dir/profiles/bindhosts.txt"
    grep -q '^profile=' "$config_file" || sed -i '$ a\profile="bindhosts"' "$config_file"
    ui_print "[i] Created 'bindhosts' profile from imported setup."
}

# 2.1 - bindhosts import helper
bindhosts_import_helper() {
    list_type="$1"
    mode="$2"
    bindhosts="/data/adb/bindhosts"

    if [ "$list_type" = "custom" ]; then
        src="$bindhosts/custom.txt"
        dest="$persistent_dir/custom_rules.txt"
    else
        src="$bindhosts/$list_type.txt"
        dest="$persistent_dir/$list_type.txt"
    fi

    [ ! -f "$src" ] && return
    if grep -vq '^[[:space:]]*#' "$src" && grep -vq '^[[:space:]]*$' "$src"; then
        ui_print "[i] Detected $list_type file with entries..."
        case "$mode" in
            replace) sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$src" > "$dest" ;;
        esac
    fi
}

# 4 - AdAway import
import_adaway_data() {
    src_file="$persistent_dir/sources.txt"
    whitelist_file="$persistent_dir/whitelist.txt"
    blacklist_file="$persistent_dir/blacklist.txt"

    ui_print "[i] AdAway Backup file has been detected."
    ui_print "[i] Do you want to import your setup from it?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Yes, use only AdAway setup (replace)"
    ui_print "2 - No, Do Not Import."

    detect_key_press 2 1
    choice=$?

    case "$choice" in
        1)
            ui_print "[*] Applying AdAway setup..."
            : > "$src_file"
            : > "$whitelist_file"
            : > "$blacklist_file"
            ;;
        2|255) ui_print "[i] Skipped AdAway import."; return ;;
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

    # Create profile
    mkdir -p "$persistent_dir/profiles"
    cp -f "$src_file" "$persistent_dir/profiles/AdAway.txt"
    sed -i '1i# DESC: Imported setup from AdAway backup' "$persistent_dir/profiles/AdAway.txt"
    grep -q '^profile=' "$config_file" || sed -i '$ a\profile="AdAway"' "$config_file"
    ui_print "[i] Created 'AdAway' profile from imported setup."
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
    [ -z "$module_id" ] && continue
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