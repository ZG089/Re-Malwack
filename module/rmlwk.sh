#!/system/bin/sh

# Welcome to the main script of the module :)
# Side notes: Literally everything in this module relies on this script you're checking right now.
# customize.sh (installer script), action script and even WebUI!
# Now enjoy reading the code
# - ZG089, Founder of Re-Malwack.

# patch works:
# shellcheck disable=SC2112
# shellcheck disable=SC3043
# shellcheck disable=SC3009
# shellcheck disable=SC2068

# global vars
quiet_mode=0
is_zn_detected=0
persist_dir="/data/adb/Re-Malwack"
zn_module_dir="/data/adb/modules/hostsredirect"
REALPATH=$(readlink -f "$0")
MODDIR=$(dirname "$REALPATH")
system_hosts="/system/etc/hosts"
tmp_hosts="/data/local/tmp/hosts"
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"
rmlwkExec=true

############################### TODOS! DON'T EDIT ANY ONE OF THESE
# 1 - Sourcing config file
. $persist_dir/config.sh
# 2 - sourcing functions script
. $MODDIR/rmlwk_functions.sh
# 3 - creating logs + profiles dir in case if not created
mkdir -p "$persist_dir/logs" "$persist_dir/profiles"

# 4 - Determine target hosts (zn-hostsredirect / default)
if [ -d "$zn_module_dir" ] && [ ! -f "$zn_module_dir/disable" ] && [ ! -f "$zn_module_dir/remove" ]; then
    is_zn_detected=1
    hosts_file="/data/adb/hostsredirect/hosts"
    log_message "Zygisk host redirect module detected, using /data/adb/hostsredirect/hosts as target hosts file"
else
    hosts_file="$MODDIR/system/etc/hosts"
    log_message "Using standard mount method with $MODDIR/system/etc/hosts"
fi

# 5 - Refreshing module status
update_status
############################### TODOS! DON'T EDIT ANY ONE OF THESE

# 6 - log module version
log_message "Running Re-Malwack version $version"

# 3 - Trigger force stats refresh on WebUI
if [ "$WEBUI" = "true" ]; then
    refresh_blocked_counts
    update_status
fi
# 4 - Error logging lore

# 4.1 - Log errors
exec 2>>"$LOGFILE"

# 4.2 - Trap errors (logs failing command line no. + exit code)
set -e
trap '
exit_code=$?
timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")

case $exit_code in
    0)   msg="Script ran successfully ✅ - No errors" ;;
    1)   msg="General error at line $LINENO ❌" ;;
    126) msg="Command at line $LINENO invoked cannot execute ❌" ;;
    127) msg="Command at line $LINENO not found ❌" ;;
    137) msg="Killed (SIGKILL / OOM) ❌" ;;
    *)   msg="Unknown error at line $LINENO ❌ (code $exit_code)" ;;
esac

echo "[$timestamp] - [$msg]" >> "$LOGFILE"
' EXIT

# 5 - Check for --quiet argument
for arg in "$@"; do
    if [ "$arg" = "--quiet" ]; then
        quiet_mode=1
        break
    fi
done

# 6 - Show banner if not running from Magisk Manager / quiet mode is disabled
[ -z "$MAGISKTMP" ] && [ "$quiet_mode" = 0 ] && rmlwk_banner

log_message INFO "========== End of pre-main logic =========="

# ====== Main Logic ======
case "$(tolower "$1")" in
    --profile|-p)
        profile_name="$2"
        
        # Dynamically get available profiles
        available_profiles=""
        for p in "$MODDIR/profiles/"*.txt "$persist_dir/profiles/"*.txt; do
            [ -f "$p" ] || continue
            name=$(basename "$p" .txt)
            echo "$name" | grep -qE "_(added|removed)$" && continue
            available_profiles="$available_profiles $name"
        done
        
        if [ -z "$profile_name" ] || { [ ! -f "$MODDIR/profiles/${profile_name}.txt" ] && [ ! -f "$persist_dir/profiles/${profile_name}.txt" ]; }; then
            echo "[!] Invalid profile or missing argument."
            echo "[i] Available profiles:$available_profiles"
            exit 1
        fi

        if [ -f "$persist_dir/profiles/${profile_name}.txt" ]; then
            cp -f "$persist_dir/profiles/${profile_name}.txt" "$persist_dir/sources.txt"
        else
            cp -f "$MODDIR/profiles/${profile_name}.txt" "$persist_dir/sources.txt"
        fi
            
        # Apply customizations
        if [ -s "$persist_dir/profiles/${profile_name}_removed.txt" ]; then
            awk '
            NR==FNR {
                dom = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
                removed[dom] = 1;
                next;
            }
            {
                dom = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
                if (!(dom in removed)) print $0;
            }' "$persist_dir/profiles/${profile_name}_removed.txt" "$persist_dir/sources.txt" > "$persist_dir/sources.tmp"
            mv "$persist_dir/sources.tmp" "$persist_dir/sources.txt"
        fi
        if [ -s "$persist_dir/profiles/${profile_name}_added.txt" ]; then
            [ -s "$persist_dir/sources.txt" ] && tail -c1 "$persist_dir/sources.txt" | grep -qv $'\n' && echo "" >> "$persist_dir/sources.txt"
            # Only append entries whose URL isn't already in sources.txt (base/dev wins on conflict)
            awk 'NR==FNR {
                actual = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
                existing[actual] = 1;
                next;
            }
            {
                actual = ($1 == "#" && $2 == "OFF" && $3 == "#") ? $4 : $1;
                if (!(actual in existing)) print $0;
            }' "$persist_dir/sources.txt" "$persist_dir/profiles/${profile_name}_added.txt" >> "$persist_dir/sources.txt"
        fi
  
        grep -q "^profile=" "$persist_dir/config.sh" && sed -i "s/^profile=.*/profile=$profile_name/" "$persist_dir/config.sh"
        log_message SUCCESS "Profile switched to $profile_name."
        echo "[✓] Profile switched to $profile_name. Please update hosts to apply changes."
        update_status
        ;;
    --reset-profile|-rp)
        profile_name="$2"
        if [ -z "$profile_name" ]; then
            echo "[!] Missing argument. Usage: rmlwk --reset-profile <profile_name>"
            exit 1
        fi
        rm -f "$persist_dir/profiles/${profile_name}_added.txt" "$persist_dir/profiles/${profile_name}_removed.txt"
        log_message SUCCESS "Reset customizations for profile $profile_name."
        echo "[✓] Reset customizations for profile $profile_name."
        ;;
    --adblock-switch|-as)
        pause_protections
        ;;
    --reset|-r)
        start_time=$(get_current_time)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        is_default_hosts && abort "Hosts has been already reset."
        log_message "Resetting hosts command triggered, resetting..."
        echo "[*] Reverting the changes..."
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"

        # Re-add blacklist entries after reset if they exist
        if [ -s "$persist_dir/blacklist.txt" ]; then
            echo "[*] Reinserting blacklist entries after reset..."
            grep -vFxf "$persist_dir/blacklist.txt" "$hosts_file" > "${tmp_hosts}_b"
            while read -r line; do
                echo "0.0.0.0 $line"
            done < "$persist_dir/blacklist.txt" >> "${tmp_hosts}_b"
            cat "${tmp_hosts}_b" > "$hosts_file"
            rm -f "${tmp_hosts}_b"
        fi
        apply_custom_rules
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Successfully reset hosts."
        end_time=$(get_current_time)
        log_duration "Resetting hosts" "$start_time" "$end_time"
	    echo "[✓] Successfully reverted hosts."
        ;;
    --export-logs|-e)
        export_logs
        ;;
    --dns-logging|-dl)
        status="$2"
        if [ "$status" = "enable" ]; then
            if [ "$dns_logging" = "1" ]; then
                echo "[i] DNS logging is already enabled"
                exit 0
            fi
            echo "[*] Enabling DNS Logging..."
            log_message "Enabling DNS Logging"
            grep -q "^dns_logging=" "$persist_dir/config.sh" && sed -i 's/^dns_logging=.*/dns_logging=1/' "$persist_dir/config.sh"
            if [ -d "/data/adb/modules/Re-Malwack/zygisk_opt" ]; then
                mv "/data/adb/modules/Re-Malwack/zygisk_opt" "/data/adb/modules/Re-Malwack/zygisk"
            fi
            touch "$persist_dir/logs/dns.log"
            chmod 666 "$persist_dir/logs/dns.log"
            touch "$persist_dir/reboot_required"
            echo "[✓] DNS logging enabled. Please reboot your device."
            log_message SUCCESS "DNS logging enabled, zygisk setup complete."
            update_status
        elif [ "$status" = "disable" ]; then
            if [ "$dns_logging" = "0" ]; then
                echo "[i] DNS logging is already disabled"
                exit 0
            fi
            echo "[*] Disabling DNS Logging..."
            log_message "Disabling DNS Logging"
            grep -q "^dns_logging=" "$persist_dir/config.sh" && sed -i 's/^dns_logging=.*/dns_logging=0/' "$persist_dir/config.sh"
            if [ -d "/data/adb/modules/Re-Malwack/zygisk" ]; then
                mv "/data/adb/modules/Re-Malwack/zygisk" "/data/adb/modules/Re-Malwack/zygisk_opt"
            fi
            touch "$persist_dir/reboot_required"
            echo "[✓] DNS logging disabled. Please reboot your device."
            log_message SUCCESS "DNS logging disabled, zygisk components removed."
            update_status
        else
            echo "[!] Invalid argument for --dns-logging. Please use 'enable' or 'disable'."
            exit 1
        fi
        ;;
    --query-domain|-q)
        start_time=$(get_current_time)
        domain="$2"
        query_domain "$domain"
        end_time=$(get_current_time)
        log_duration "Querying domain: $domain" "$start_time" "$end_time"
        ;;
    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs|--block-trackers|-bt|--block-safebrowsing|-bsb)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        start_time=$(get_current_time)
        case "$1" in
            --block-porn|-bp) block_type="porn" ;;
            --block-gambling|-bg) block_type="gambling" ;;
            --block-fakenews|-bf) block_type="fakenews" ;;
            --block-social|-bs) block_type="social" ;;
            --block-trackers|-bt) block_type="trackers" ;;
            --block-safebrowsing|-bsb) block_type="safebrowsing" ;;
        esac
        status="$2"
        if [ "$block_type" = "trackers" ]; then
            # Handle trackers with its own function
            block_trackers "$status"
        else
            eval "block_toggle=\"\$block_${block_type}\""

            if [ "$status" = "disable" ] || [ "$status" = 0 ]; then
                if [ "$block_toggle" = 0 ]; then
                    echo "[i] $block_type block is already disabled"
                    exit 0
                else
                    log_message "Disabling ${block_type} blocklist has been initiated."
                    echo "[*] Disabling ${block_type} blocklist has been initiated."
                    block_content "$block_type" 0
                    log_message SUCCESS "Disabled ${block_type} blocklist successfully."
                    echo "[✓] Disabled ${block_type} blocklist successfully."
                fi
            else
                if [ "$block_toggle" = 1 ]; then
                    echo "[!] ${block_type} block is already enabled"
                    exit 0
                else
                    log_message "Enabling block entries for $block_type has been initiated."
                    echo "[*] Enabling block entries for ${block_type} has been initiated."
                    block_content "$block_type" 1
                    log_message SUCCESS "Enabled ${block_type} blocklist successfully."
                    echo "[✓] Enabled ${block_type} blocklist successfully."
                fi
            fi
        fi
        refresh_blocked_counts
        update_status
        end_time=$(get_current_time)
        log_duration "Toggling ${block_type} blocklist" "$start_time" "$end_time"
        ;;

    --whitelist|-w)
        start_time=$(get_current_time)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        [ -f "$persist_dir/mode_ready" ] && abort "Idle protection is active. Please update hosts to apply changes and disable idle mode."
        is_default_hosts && abort "You cannot whitelist links while hosts is reset."
        action="$2"
        shift 2
        if [ -z "$action" ] || [ $# -eq 0 ] || { [ "$action" != "add" ] && [ "$action" != "remove" ]; }; then
            echo "[!] Invalid arguments for --whitelist|-w"
            echo "[i] Usage: rmlwk --whitelist|-w <add|remove> [domain1] [domain2] ..."
            echo "[i] Examples:"
            echo "  rmlwk -w add example.com           # Add domain to the whitelist"
            echo "  rmlwk --whitelist add *.example.com # Add subdomain wildcard to whitelist"
            echo "  rmlwk -w add *something            # Add suffix wildcard to whitelist"
            echo "  rmlwk --whitelist add something*   # Add prefix wildcard to whitelist"
            echo "  rmlwk --whitelist remove example.com # Remove domain from whitelist"
            echo "  rmlwk -w add domain1.com domain2.com domain3.com # Add multiple domains to whitelist"
            display_whitelist=$(cat "$persist_dir/whitelist.txt" 2>/dev/null || true )
            [ -n "$display_whitelist" ] && echo -e "Current whitelist:\n$display_whitelist" || echo "Current whitelist: no saved whitelist"
            exit 1
        fi

        if [ "$action" = "add" ]; then
            added_total=""
            for raw_input in "$@"; do
                # Extract host if a URL was passed
                if printf '%s' "$raw_input" | grep -qE '^https?://'; then
                    host=$(printf '%s' "$raw_input" | awk -F[/:] '{print $4}')
                else
                    host="$raw_input"
                fi

                # Validate domain format (Special cases for wildcards)
                if ! printf '%s' "$host" | grep -qE '(\*|\.)'; then
                    echo "[!] Invalid domain input: $raw_input"
                    echo "[i] Valid domain input examples: 'domain.com', '*.domain.com', '*something', 'something*'"
                    continue
                fi

                # Ensure the domain is not already blacklisted
                if grep -Fxq "$host" "$persist_dir/blacklist.txt"; then
                    echo "[!] Cannot whitelist $raw_input, it already exists in blacklist."
                    continue
                fi

                # Check if already whitelisted
                if grep -qxF "$raw_input" "$persist_dir/whitelist.txt"; then
                    echo "[i] $raw_input is already whitelisted"
                    continue
                fi

                # Detect input type
                case "$raw_input" in
                    \*\.*) # Subdomain: *.domain.com
                        domain="${raw_input#*.}"
                        esc_domain=$(printf '%s' "$domain" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')
                        pattern="^0\.0\.0\.0 [^.]+\\.${esc_domain}\$"
                        match_type="subdomain"
                        ;;
                    \**) # Suffix: *something
                        suffix="${raw_input#\*}"
                        esc_suffix=$(printf '%s' "$suffix" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')
                        pattern="^0\.0\.0\.0 .*${esc_suffix}\$"
                        match_type="suffix"
                        ;;
                    *\*) # Prefix: something*
                        prefix="${raw_input%\*}"
                        esc_prefix=$(printf '%s' "$prefix" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')
                        pattern="^0\.0\.0\.0 ${esc_prefix}.*\$"
                        match_type="prefix"
                        ;;
                    *) # Exact
                        domain="$raw_input"
                        esc_domain=$(printf '%s' "$domain" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')
                        pattern="^0\.0\.0\.0 ${esc_domain}\$"
                        match_type="exact"
                        ;;
                esac

                # Collect matches
                matched_domains=$(grep -E "$pattern" "$hosts_file" | awk '{print $2}' | sort -u)
                if [ -z "$matched_domains" ]; then
                    echo "[i] No matches found for $raw_input"
                    continue
                fi

                # Remove blacklisted entries from the match set
                if [ -s "$persist_dir/blacklist.txt" ]; then
                    matched_domains=$(printf '%s\n' "$matched_domains" | grep -Fvxf "$persist_dir/blacklist.txt")
                fi

                if [ -z "$matched_domains" ]; then
                    echo "[i] All matched domains are already blacklisted, nothing to whitelist."
                    continue
                fi

                # Add matched domains to whitelist file
                echo "[*] Whitelisting ($match_type): $raw_input"
                for md in $matched_domains; do
                    if ! grep -qxF "$md" "$persist_dir/whitelist.txt"; then
                        echo "$md" >> "$persist_dir/whitelist.txt"
                    fi
                done

                # Rewrite hosts file excluding matched domains
                tmp_hosts="$persist_dir/tmp.hosts.$$"
                grep -Ev "$pattern" "$hosts_file" > "$tmp_hosts"
                cat "$tmp_hosts" > "$hosts_file"
                rm -f "$tmp_hosts"

                added_total="$added_total $raw_input"
                log_message "Whitelisted ($match_type): $raw_input. Domains: $matched_domains"
                echo "[✓] Whitelisted ($match_type): $raw_input"
                echo "[i] Added the following domain(s) to whitelist and removed from hosts:"
                printf " - %s\n" $matched_domains
            done

            if [ -z "$added_total" ]; then
                abort "Nothing was whitelisted."
            fi

            # Deduplicate whitelist file
            tmpf="$persist_dir/.whitelist.sorted.$$"
            sort -u "$persist_dir/whitelist.txt" > "$tmpf" && mv "$tmpf" "$persist_dir/whitelist.txt"

            # Finalize
            log_message SUCCESS "Whitelisted multiple entries:$added_total"
            update_status
            end_time=$(get_current_time)
            log_duration "Adding to whitelist bulk" "$start_time" "$end_time"
        else  # remove
            shift 2  # move past: --whitelist remove
            if [ $# -lt 1 ]; then
                echo "[!] No domains/patterns provided to remove."
                exit 1
            fi

            removed_total=""
            for raw in "$@"; do
                # Extract host (strip protocol if URL)
                if printf '%s' "$raw" | grep -qE '^https?://'; then
                    host=$(printf '%s' "$raw" | awk -F[/:] '{print $4}')
                else
                    host="$raw"
                fi

                # Skip invalid inputs quickly
                if [ -z "$host" ]; then
                    echo "[!] Invalid input: $raw"
                    continue
                fi

                # Determine pattern → build regex exactly like ADD mode
                suffix_wildcard=0
                glob_mode=0
                if printf '%s' "$host" | grep -qE '^\*\.|^\.'; then
                    suffix_wildcard=1
                elif printf '%s' "$host" | grep -q '\*'; then
                    glob_mode=1
                fi

                base="$host"
                [ "$suffix_wildcard" -eq 1 ] && base="${base#*.}"

                esc_base=$(printf '%s' "$base" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')

                if [ "$suffix_wildcard" -eq 1 ]; then
                    dom_re="(^|.*\.)${esc_base}$"
                elif [ "$glob_mode" -eq 1 ]; then
                    esc_glob=$(printf '%s' "$esc_base" | sed 's/\*/.*/g')
                    dom_re="^${esc_glob}$"
                else
                    dom_re="^${esc_base}$"
                fi

                # Find matches inside whitelist
                matches=$(grep -E "$dom_re" "$persist_dir/whitelist.txt" || true)
                if [ -z "$matches" ]; then
                    echo "[i] No whitelist matches for: $raw"
                    continue
                fi

                echo "[*] Removing from whitelist: $raw"
                removed_total="$removed_total $matches"

                # Remove from whitelist
                tmpf="$persist_dir/.whitelist.$$"
                grep -Ev "$dom_re" "$persist_dir/whitelist.txt" > "$tmpf" || true
                mv "$tmpf" "$persist_dir/whitelist.txt"
            done

            if [ -z "$removed_total" ]; then
                echo "[!] Nothing was removed from whitelist."
                exit 1
            fi

            # Re-block once at the end
            for dom in $removed_total; do
                if ! grep -qE "^0\.0\.0\.0[[:space:]]+$dom\$" "$hosts_file"; then
                    echo "0.0.0.0 $dom" >> "$hosts_file"
                fi
            done
            log_message SUCCESS "Whitelist multi-remove: $removed_total"
            echo "[✓] Removed the selected domain(s) from whitelist and re-blocked them."
            update_status
            end_time=$(get_current_time)
            log_duration "Removing from whitelist: $raw_input" "$start_time" "$end_time"
        fi
        ;;

    --blacklist|-b)
        start_time=$(get_current_time)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        option="$2"
        shift 2 # Remove script name and option from arguments

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ $# -eq 0 ]; then
            echo "Usage: rmlwk --blacklist, -b <add/remove> <domain1> [domain2] [domain3] ..."
            display_blacklist=$(cat "$persist_dir/blacklist.txt" 2>/dev/null || true)
            [ ! -z "$display_blacklist" ] && echo -e "Current blacklist:\n$display_blacklist" || echo "Current blacklist: no saved blacklist"
            exit 1
        fi
        if [ "$option" = "add" ]; then
            added_total=""
            for raw_input in "$@"; do
                # Sanitize input
                if printf "%s" "$raw_input" | grep -qE '^https?://'; then
                    domain=$(printf "%s" "$raw_input" | awk -F[/:] '{print $4}')
                else
                    domain="$raw_input"
                fi

                # Validate domain format
                if ! printf '%s' "$domain" | grep -qiE '^[a-z0-9.-]+\.[a-z]{2,}$'; then
                    echo "[!] Invalid domain: $domain"
                    echo "Example valid domain: example.com"
                    continue
                fi

                # Ensure domain not already whitelisted
                if grep -Fxq "$domain" "$persist_dir/whitelist.txt"; then
                    echo "[!] Cannot blacklist $domain, it already exists in whitelist."
                    continue
                fi

                # Add to hosts file if not already present
                if grep -qE "^0\.0\.0\.0[[:space:]]+$domain\$" "$hosts_file"; then
                    echo "[i] $domain is already blocked."
                    continue
                else
                    echo "[*] Blacklisting $domain..."
                    log_message "Blacklisting $domain..."
                    # Add to blacklist.txt if not already there
                    grep -qxF "$domain" "$persist_dir/blacklist.txt" || echo "$domain" >> "$persist_dir/blacklist.txt"
                    # Ensure newline at end before appending
                    [ -s "$hosts_file" ] && tail -c1 "$hosts_file" | grep -qv $'\n' && echo "" >> "$hosts_file"
                    echo "0.0.0.0 $domain" >> "$hosts_file" && echo "[✓] Blacklisted $domain."
                    added_total="$added_total $domain"
                fi
            done

            if [ -z "$added_total" ]; then
                echo "[!] No domains were blacklisted."
                exit 1
            fi
            log_message SUCCESS "Done added$added_total to hosts file and blacklist."
            update_status
            end_time=$(get_current_time)
            log_duration "Adding to blacklist bulk" "$start_time" "$end_time"
        else
            # Remove multiple domains from blacklist
            log_message "Removing multiple domains from blacklist: $*"

            total_removed=0
            failed_removals=""

            for domain_to_remove in "$@"; do
                # Sanitize input
                if printf "%s" "$domain_to_remove" | grep -qE '^https?://'; then
                    domain=$(printf "%s" "$domain_to_remove" | awk -F[/:] '{print $4}')
                else
                    domain="$domain_to_remove"
                fi

                echo "[*] Removing $domain from blacklist..."
                log_message "Removing $domain from blacklist..."
                if grep -qxF "$domain" "$persist_dir/blacklist.txt"; then
                    sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/blacklist.txt"
                    tmp_hosts="$persist_dir/tmp.hosts.$$"
                    grep -vF "0.0.0.0 $domain" "$hosts_file" > "$tmp_hosts"
                    cat "$tmp_hosts" > "$hosts_file"
                    rm -f "$tmp_hosts"
                    log_message "Removed $domain from blacklist and unblocked."
                    echo "[✓] $domain has been removed from blacklist and unblocked."
                    total_removed=$((total_removed + 1))
                else
                    echo "[!] $domain isn't found in blacklist."
                    failed_removals="$failed_removals $domain_to_remove"
                    log_message WARN "$domain not found in blacklist"
                fi
            done

            # Summary
            if [ $total_removed -gt 0 ]; then
                echo "[i] Successfully removed $total_removed domain(s) from blacklist"
                log_message SUCCESS "Successfully removed $total_removed domains from blacklist"
                update_status
                end_time=$(get_current_time)
                log_duration "Removing from blacklist: $*" "$start_time" "$end_time"
            fi
            
            if [ -n "$failed_removals" ]; then
                echo "[i] Failed to remove:$failed_removals"
                log_message WARN "Failed to remove domains:$failed_removals"
            fi

            if [ $total_removed -eq 0 ]; then
                echo "[!] No domains were removed from blacklist"
                exit 1
            fi
        fi
        ;;

	--custom-source|-c)
        option="$2"
        shift 2 # Remove script name and option from arguments        
        if [ -z "$option" ] || [ $# -eq 0 ]; then
            echo "[!] Missing arguments."
            echo "Usage: rmlwk --custom-source <add/remove> <domain1> [domain2] [domain3] ..."
            display_sources=$(cat "$persist_dir/sources.txt" 2>/dev/null)
            [ -n "$display_sources" ] && echo -e "Current sources:\n$display_sources" || echo "Current sources: no saved sources"
            exit 1
        fi

        if [ "$option" != "add" ] && [ "$option" != "remove" ] && [ "$option" != "enable" ] && [ "$option" != "disable" ] && [ "$option" != "edit" ]; then
            echo "[!] Invalid option: Use 'add', 'remove', 'edit', 'enable', or 'disable'."
            echo "Usage: rmlwk --custom-source <add/remove/edit/enable/disable> <domain1> [domain2] [domain3] ..."
            exit 1
        fi
        touch "$persist_dir/sources.txt"
        if [ "$option" = "add" ]; then
            # For add, process the first argument as domain and the rest as the name
            domain="$1"
            shift
            name="$*"

            # Clean up the name by removing any leading '#' characters and spaces coming from WebUI
            name=$(printf '%s' "$name" | sed 's/^#[[:space:]]*//')
            
            # Validate URL format (accept http/https)
            if ! printf '%s' "$domain" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})' ; then
                echo "[!] Invalid domain: $domain"
                echo "Example valid domain: example.com, https://example.com or https://example.com/hosts.txt"
                exit 1
            fi

            # Ensure the file ends with a newline to prevent concatenation
            if [ -s "$persist_dir/sources.txt" ]; then
                last_char=$(tail -c 1 "$persist_dir/sources.txt")
                [ -n "$last_char" ] && echo "" >> "$persist_dir/sources.txt"
            fi

            # Check if domain already exists, ignoring the comment part
            if awk '{print $1}' "$persist_dir/sources.txt" 2>/dev/null | grep -qx "$domain"; then
                echo "[!] $domain is already in sources."
            else
                if [ -n "$name" ]; then
                    echo "$domain # $name" >> "$persist_dir/sources.txt"
                    is_builtin_profile && echo "$domain # $name" >> "$persist_dir/profiles/${profile}_added.txt"
                    log_message SUCCESS "Added $domain ($name) to sources."
                    echo "[✓] Added $domain ($name) to sources."
                else
                    echo "$domain" >> "$persist_dir/sources.txt"
                    is_builtin_profile && echo "$domain" >> "$persist_dir/profiles/${profile}_added.txt"
                    log_message SUCCESS "Added $domain to sources."
                    echo "[✓] Added $domain to sources."
                fi
            fi
        elif [ "$option" = "edit" ]; then
            # Args: $1=old_url  $2=new_url  $3=new_name (each a single clean arg, no spaces)
            old_url="$1"
            new_url="$2"
            new_name="$3"

            old_url=$(printf '%s' "$old_url" | tr -d '\r' | sed 's/[[:space:]]*$//')
            new_url=$(printf '%s' "$new_url" | tr -d '\r' | sed 's/[[:space:]]*$//')
            new_name=$(printf '%s' "$new_name" | tr -d '\r' | sed 's/[[:space:]]*$//')

            if [ -z "$old_url" ] || [ -z "$new_url" ]; then
                echo "[!] Missing arguments for edit."
                echo "Usage: rmlwk --custom-source edit <old_url> <new_url> [new_name]"
                exit 1
            fi

            if [ -n "$new_name" ]; then
                new_line="$new_url # $new_name"
            else
                new_line="$new_url"
            fi

            # Replace matching line in sources.txt
            # grep -F for existence check, then two separate sed calls with || true
            # BusyBox sed -i exits non zero when a pattern matches nothing, which kills set -e
            if grep -qF "$old_url" "$persist_dir/sources.txt"; then
                esc_old=$(printf '%s' "$old_url" | sed 's|[&/\\]|\\&|g')
                esc_new=$(printf '%s' "$new_line" | sed 's|[&/\\]|\\&|g')
                sed -i "s|^${esc_old}.*|${esc_new}|" "$persist_dir/sources.txt" || true
                sed -i "s|^# OFF # ${esc_old}.*|# OFF # ${esc_new}|" "$persist_dir/sources.txt" || true
                log_message SUCCESS "Edited source: $old_url -> $new_line"
                echo "[✓] Edited source entry."
            else
                echo "[!] $old_url was not found in sources."
                exit 1
            fi

            # Sync _added.txt for builtin profiles
            if is_builtin_profile; then
                if [ -f "$persist_dir/profiles/${profile}_added.txt" ] && \
                   grep -qF "$old_url" "$persist_dir/profiles/${profile}_added.txt" 2>/dev/null; then
                    # Source was user-added: just update it in _added.txt
                    esc_old=$(printf '%s' "$old_url" | sed 's|[&/\\]|\\&|g')
                    esc_new=$(printf '%s' "$new_line" | sed 's|[&/\\]|\\&|g')
                    sed -i "s|^${esc_old}.*|${esc_new}|" "$persist_dir/profiles/${profile}_added.txt" || true
                    sed -i "s|^# OFF # ${esc_old}.*|# OFF # ${esc_new}|" "$persist_dir/profiles/${profile}_added.txt" || true
                    log_message SUCCESS "Synced edit to _added.txt for builtin profile $profile."
                else
                    # Source came from the base profile (not in _added.txt yet):
                    # tombstone the original URL so it won't be re-applied on profile switch,
                    # then track the edited version as a user addition.
                    echo "$old_url" >> "$persist_dir/profiles/${profile}_removed.txt"
                    [ -s "$persist_dir/profiles/${profile}_added.txt" ] && \
                        tail -c1 "$persist_dir/profiles/${profile}_added.txt" | grep -qv $'\n' && \
                        echo "" >> "$persist_dir/profiles/${profile}_added.txt"
                    echo "$new_line" >> "$persist_dir/profiles/${profile}_added.txt"
                    log_message SUCCESS "Tracked base-profile source edit for $profile: removed $old_url, added $new_line."
                fi
            fi
        elif [ "$option" = "enable" ] || [ "$option" = "disable" ]; then
            total_processed=0
            failed_process=""
            for domain in "$@"; do
                # Validate URL format
                if ! printf '%s' "$domain" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})' ; then
                    echo "[!] Invalid domain: $domain"
                    failed_process="$failed_process $domain"
                    continue
                fi

                if awk '{print $1}' "$persist_dir/sources.txt" 2>/dev/null | grep -qx "#" || awk '{print $1}' "$persist_dir/sources.txt" 2>/dev/null | grep -qx "$domain" || awk '{print $4}' "$persist_dir/sources.txt" 2>/dev/null | grep -qx "$domain"; then
                    if [ "$option" = "enable" ]; then
                        sed -i "s|^# OFF # $domain|$domain|g" "$persist_dir/sources.txt"
                        log_message SUCCESS "Enabled $domain in sources."
                        echo "[✓] Enabled $domain in sources."
                    else
                        sed -i "s|^$domain|# OFF # $domain|g" "$persist_dir/sources.txt"
                        log_message SUCCESS "Disabled $domain in sources."
                        echo "[✓] Disabled $domain in sources."
                    fi
                    total_processed=$((total_processed + 1))
                else
                    echo "[!] $domain was not found in sources."
                    log_message WARN "$domain not found in sources"
                    failed_process="$failed_process $domain"
                fi
            done
            
            # Summary
            [ $total_processed -gt 0 ] && echo "[i] Successfully processed $total_processed source(s)"
            [ -n "$failed_process" ] && echo "[i] Failed to process:$failed_process"
            if [ $total_processed -eq 0 ]; then
                echo "[!] No sources were processed"
                exit 1
            fi
        else
            # Remove multiple domains from sources
            log_message "Removing multiple domains from sources: $*"
            total_removed=0
            failed_removals=""
            for domain_to_remove in "$@"; do
                # Validate URL format
                if ! printf '%s' "$domain_to_remove" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})' ; then
                    echo "[!] Invalid domain format: $domain_to_remove"
                    failed_removals="$failed_removals $domain_to_remove"
                    continue
                fi

                # Check correctly by filtering out the prefix if present
                if grep -E "^(# OFF # )?$domain_to_remove" "$persist_dir/sources.txt" >/dev/null 2>&1; then
                    # Remove the line matching the domain (even if it has a comment after it or # OFF # prefix)
                    
                    removed_line=$(awk -v dom="$domain_to_remove" '{actual=$1; if (actual=="#") actual=$4; if (actual == dom) print $0}' "$persist_dir/sources.txt" | head -n 1)
                    if [ -n "$removed_line" ] && is_builtin_profile; then
                        echo "$removed_line" >> "$persist_dir/profiles/${profile}_removed.txt"
                    fi
                    
                    awk -v dom="$domain_to_remove" '{
                        actual=$1; 
                        if (actual=="#") actual=$4; 
                        if (actual != dom) print $0
                    }' "$persist_dir/sources.txt" > "$persist_dir/sources.tmp"
                    mv "$persist_dir/sources.tmp" "$persist_dir/sources.txt"
                    
                    if is_builtin_profile && [ -f "$persist_dir/profiles/${profile}_added.txt" ]; then
                        awk -v dom="$domain_to_remove" '{actual=$1; if (actual=="#") actual=$4; if (actual != dom) print $0}' "$persist_dir/profiles/${profile}_added.txt" > "$persist_dir/profiles/${profile}_added.tmp"
                        mv "$persist_dir/profiles/${profile}_added.tmp" "$persist_dir/profiles/${profile}_added.txt"
                    fi

                    log_message SUCCESS "Removed $domain_to_remove from sources."
                    echo "[✓] Removed $domain_to_remove from sources."
                    total_removed=$((total_removed + 1))
                else
                    echo "[!] $domain_to_remove was not found in sources."
                    failed_removals="$failed_removals $domain_to_remove"
                    log_message WARN "$domain_to_remove not found in sources"
                fi
            done
            
            # Summary
            if [ $total_removed -gt 0 ]; then
                echo "[i] Successfully removed $total_removed source(s)"
                log_message SUCCESS "Successfully removed $total_removed sources"
            fi
            
            if [ -n "$failed_removals" ]; then
                echo "[i] Failed to remove:$failed_removals"
                log_message WARN "Failed to remove sources:$failed_removals"
            fi
            
            if [ $total_removed -eq 0 ]; then
                echo "[!] No sources were removed"
                exit 1
            fi
        fi
        
        # Sync user profile changes directly
        if is_user_profile; then
            cp -f "$persist_dir/sources.txt" "$persist_dir/profiles/${profile}.txt"
            log_message SUCCESS "Synced changes directly to user profile $profile."
        fi
        ;;

    --custom-rule|-cr)
        start_time=$(get_current_time)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        option="$2"
        shift 2

        if [ -z "$option" ] || [ $# -eq 0 ]; then
            echo "[!] Missing arguments."
            echo "Usage: rmlwk --custom-rule <add|remove> <IP> <domain>"
            display_rules=$(cat "$persist_dir/custom_rules.txt" 2>/dev/null)
            [ -n "$display_rules" ] && echo -e "Current custom rules:\n$display_rules" || echo "Current custom rules: no saved custom rules"
            exit 1
        fi

        if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
            echo "[!] Invalid option: Use 'add' or 'remove'."
            echo "Usage: rmlwk --custom-rule <add/remove> <IP> <domain>"
            exit 1
        fi

        touch "$persist_dir/custom_rules.txt"
        if [ "$option" = "add" ]; then
            if [ $# -lt 2 ]; then
                echo "[!] Incomplete input."
                echo "[i] Usage: rmlwk --custom-rule add <IP> <domain>"
                exit 1
            fi
            ip="$1"
            domain="$2"

            # Validate IP format
            if ! printf '%s' "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$'; then
                echo "[!] Invalid IP format: $ip"
                exit 1
            fi

            # Validate Domain or IP format
            if ! printf '%s' "$domain" | grep -qiE '^[a-z0-9.-]+\.[a-z]{2,}$|^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$'; then
                echo "[!] Invalid domain or IP format: $domain"
                exit 1
            fi

            # Check if domain already has a custom rule
            if awk '{print $2}' "$persist_dir/custom_rules.txt" 2>/dev/null | grep -qx "$domain"; then
                echo "[!] Domain $domain already has a custom rule."
                exit 1
            else
                echo "$ip $domain" >> "$persist_dir/custom_rules.txt"
                log_message SUCCESS "Added custom rule: $ip $domain"
                echo "[✓] Added custom rule: $ip $domain"

                # Append to active hosts immediately if not present
                if [ -s "$hosts_file" ]; then
                    last_line=$(tail -n 1 "$hosts_file")
                    if [ -n "$last_line" ]; then
                        echo "" >> "$hosts_file"
                    fi
                fi
                echo "$ip $domain" >> "$hosts_file"
            fi

        elif [ "$option" = "remove" ]; then
            log_message "Removing multiple domains from custom rules: $*"
            total_removed=0
            failed_removals=""
            for domain_to_remove in "$@"; do
                if grep -qw "$domain_to_remove" "$persist_dir/custom_rules.txt"; then
                    awk -v dom="$domain_to_remove" '$2 != dom' "$persist_dir/custom_rules.txt" > "$persist_dir/custom_rules.tmp"
                    mv "$persist_dir/custom_rules.tmp" "$persist_dir/custom_rules.txt"

                    # Remove from active hosts too
                    tmp_hosts="$persist_dir/tmp.hosts.$$"
                    grep -vE "^[0-9a-fA-F:.]+ $domain_to_remove\$" "$hosts_file" > "$tmp_hosts" || true
                    cat "$tmp_hosts" > "$hosts_file"
                    rm -f "$tmp_hosts"

                    log_message SUCCESS "Removed custom rule for $domain_to_remove."
                    echo "[✓] Removed custom rule for $domain_to_remove."
                    total_removed=$((total_removed + 1))
                else
                    echo "[!] $domain_to_remove was not found in custom rules."
                    failed_removals="$failed_removals $domain_to_remove"
                    log_message WARN "$domain_to_remove not found in custom rules"
                fi
            done

            if [ $total_removed -gt 0 ]; then
                echo "[i] Successfully removed $total_removed custom rule(s)"
            fi
            if [ -n "$failed_removals" ]; then
                echo "[i] Failed to remove rules for:$failed_removals"
            fi
            if [ $total_removed -eq 0 ]; then
                echo "[!] No custom rules were removed"
                exit 1
            fi
        fi

        update_status
        end_time=$(get_current_time)
        log_duration "Custom rule action: $option" "$start_time" "$end_time"
        ;;

    --auto-update|-a)
        case "$2" in
            enable)
                enable_auto_update
                ;;
            disable)
                disable_auto_update
                ;;
            *)
                echo "[!] Invalid option for --auto-update / -a"
                echo "Usage: rmlwk <--auto-update|-a> <enable|disable>"
                ;;
        esac
        ;;

    --update-hosts|-u)
        start_time=$(get_current_time)
        awk '!/^#|^$/' $persist_dir/sources.txt | grep http > /dev/null || abort "No hosts sources were found, Aborting."
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."

        [ -d /data/adb/modules/Re-Malwack ] && echo "[*] Upgrading Anti-Ads fortress 🏰" && log_message "Updating protections..."
        check_internet
        combined_file="${tmp_hosts}_all"
        > "$combined_file"

        # 1 - Download base hosts from sources.txt with limited parallelism to prevent resource exhaustion
        customized_label=""
        { [ -s "$persist_dir/profiles/${profile}_added.txt" ] || [ -s "$persist_dir/profiles/${profile}_removed.txt" ]; } && customized_label=" (customized)"
        echo "[i] Using profile: $profile${customized_label}"
        echo "[*] Fetching base hosts..."
        log_message "Starting download of base hosts"
        # Extract only the URLs for fetching (ignore inline comments too)
        hosts_list=$(awk '!/^#|^$/ {print $1}' "$persist_dir/sources.txt" | sort -u)
        counter=0
        download_limit=3
        download_count=0
        for host in $hosts_list; do
            counter=$((counter + 1))
            # Save the url mapping for this counter for later counting
            echo "$host" > "${tmp_hosts}${counter}.url"
            fetch "${tmp_hosts}${counter}" "$host" &
            download_count=$((download_count + 1))
            # Limit concurrent downloads
            [ "$download_count" -ge "$download_limit" ] && { wait; download_count=0; sleep 0.5; }
        done
        wait
        log_message SUCCESS "Completed download hosts from $counter source(s)"

        # 1.1 - Process in parallel with conservative limits
        job_limit=3
        job_count=0
        mkdir -p "$persist_dir/counts"
        > "$persist_dir/counts/sources.counts"
        for i in $(seq 1 $counter); do
            (
                if [ -f "${tmp_hosts}${i}" ]; then
                    host_process "${tmp_hosts}${i}"
                    # Count block entries and save it
                    if [ -f "${tmp_hosts}${i}.url" ]; then
                        host_url=$(cat "${tmp_hosts}${i}.url")
                        entries_count=$(wc -l < "${tmp_hosts}${i}")
                        echo "${host_url}|${entries_count}" >> "$persist_dir/counts/sources.counts"
                        log_message SUCCESS "Downloaded $entries_count entries from $host_url"
                    fi
                    cat "${tmp_hosts}${i}" >> "$combined_file"
                fi
            ) &
            job_count=$((job_count + 1))
            [ "$job_count" -ge "$job_limit" ] && { wait; job_count=0; sleep 0.25; }
        done
        wait
        log_message "Completed processing of all base source files"

        # 2 - Download & process blocklists with small delays to prevent resource starvation
        > "$persist_dir/counts/blocklists.counts"
        for bl in porn gambling fakenews social trackers safebrowsing; do
            block_var="block_${bl}"
            eval enabled=\$$block_var

            # 2.1 - Skip if not enabled
            [ "$enabled" = "0" ] && continue

            # 2.1 - Prepare blocklist fetch
            echo "[*] Fetching blocklist: $bl"
            log_message "Fetching blocklist: $bl"
            mkdir -p "$persist_dir/cache/$bl"

            # 2.3 - Fetch blocklists
            fetch_blocklist "$bl"

            # 2.4 - Process blocklists
            bl_count=0
            for file in "$persist_dir/cache/$bl/hosts"*; do
                if [ -f "$file" ]; then
                    host_process "$file"
                    file_count=$(wc -l < "$file")
                    bl_count=$((bl_count + file_count))
                fi
            done
            echo "${bl}|${bl_count}" >> "$persist_dir/counts/blocklists.counts"

            # 2.5 - Append to combined file
            cat "$persist_dir/cache/$bl/hosts"* >> "$combined_file"
            log_message "Added $bl ($bl_count) hosts entries to combined hosts"
        done

        # 3 - Install hosts
        echo "[*] Installing hosts"
        log_message "Writing new hosts file"
        install_hosts "all"

        # 4 - Done
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Successfully updated all hosts."
        [ ! "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ] && echo "[✓] Everything is now Good!"
        end_time=$(get_current_time)
        log_duration "Updating hosts" "$start_time" "$end_time"
        ;;

    --help|-h|*)
        help_menu
        ;;
esac