[ "${RMLWK_LIB_COMMANDS:-0}" -eq 1 ] && return 0
RMLWK_LIB_COMMANDS=1

cmd_profile() {
    action="$1"
    
    if [ -z "$action" ]; then
        echo "[!] Missing argument for --profile."
        exit 1
    fi

    if [ "$action" = "create" ]; then
        name="$2"
        desc="$3"
        if [ -z "$name" ]; then
            echo "[!] Missing profile name."
            echo "[i] Usage: rmlwk --profile create <name> [description]"
            exit 1
        fi
        if ! echo "$name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
            echo "[!] Invalid profile name: $name (Use only alphanumeric, _, and -)"
            exit 1
        fi
        
        if [ -f "$MODDIR/profiles/${name}.txt" ]; then
            echo "[!] A built-in profile with the name '$name' already exists."
            exit 1
        fi
        
        user_profile="$persist_dir/profiles/${name}.txt"
        if [ -f "$user_profile" ]; then
            echo "[!] Profile '$name' already exists."
            exit 1
        fi
        
        mkdir -p "$persist_dir/profiles"
        echo "# profile-name: $name" > "$user_profile"
        [ -n "$desc" ] && echo "# profile-desc: $desc" >> "$user_profile"
        
        current_profile=$(get_prop profile "$persist_dir/config.sh" || echo "default")
        current_profile_file=$(resolve_profile_file "$current_profile")
        if [ -f "$current_profile_file" ]; then
            grep -vE '^# profile-name:|^# profile-desc:' "$current_profile_file" >> "$user_profile"
        fi
        
        log_message SUCCESS "Created new profile $name."
        echo "[✓] Profile '$name' created."
        return 0
    elif [ "$action" = "delete" ]; then
        name="$2"
        if [ -z "$name" ]; then
            echo "[!] Missing profile name to delete."
            exit 1
        fi
        if [ -f "$MODDIR/profiles/${name}.txt" ] && [ ! -f "$persist_dir/profiles/${name}.txt" ]; then
            echo "[!] Cannot delete built-in profile '$name'."
            exit 1
        fi
        user_profile="$persist_dir/profiles/${name}.txt"
        if [ -f "$user_profile" ]; then
            rm -f "$user_profile"
            log_message SUCCESS "Deleted profile $name."
            echo "[✓] Profile '$name' deleted."
            
            current_profile=$(get_prop profile "$persist_dir/config.sh")
            if [ "$current_profile" = "$name" ]; then
                echo "[i] Active profile deleted. Switching to default profile."
                cmd_profile default
            fi
        else
            echo "[!] Profile '$name' not found."
            exit 1
        fi
        return 0
    elif [ "$action" = "list" ]; then
        echo "[*] Available Profiles:"
        echo ""
        echo "Built-in profiles:"
        for p in "$MODDIR/profiles/"*.txt; do
            [ -f "$p" ] || continue
            pname=$(basename "$p" .txt)
            echo "  - $pname"
        done
        echo ""
        echo "User profiles:"
        if [ -d "$persist_dir/profiles" ]; then
            for p in "$persist_dir/profiles/"*.txt; do
                [ -f "$p" ] || continue
                pname=$(basename "$p" .txt)
                desc=$(grep "^# profile-desc:" "$p" | sed 's/^# profile-desc: //')
                [ -n "$desc" ] && echo "  - $pname ($desc)" || echo "  - $pname"
            done
        else
            echo "  (None)"
        fi
        return 0
    else
        profile_name="$action"
        profile_file=$(resolve_profile_file "$profile_name")
        if [ -z "$profile_file" ]; then
            echo "[!] Invalid profile '$profile_name'."
            cmd_profile list
            exit 1
        fi

        echo "[*] Switching to $profile_name profile..."
        set_prop profile "$profile_name" "$persist_dir/config.sh"
        cp -f "$profile_file" "$persist_dir/sources.txt"
        log_message SUCCESS "Profile switched to $profile_name."
        echo "[✓] Profile switched to $profile_name. Please update hosts to apply changes."
    fi
}

cmd_reset() {
    start_time=$(get_current_time)
    is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
    is_default_hosts && abort "Hosts has been already reset."
    log_message "Resetting hosts command triggered, resetting..."
    echo "[*] Reverting the changes..."
    reset_hosts

    if [ -s "$persist_dir/blacklist.txt" ]; then
        echo "[*] Reinserting blacklist entries after reset..."
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            case "$line" in
                \#*) continue ;;
            esac
            append_hosts_entry "$hosts_file" 0.0.0.0 "$line"
        done < "$persist_dir/blacklist.txt"
    fi

    apply_custom_rules
    chmod 644 "$hosts_file"
    for bl in $RMLWK_BLOCKLIST_TYPES; do
        set_prop "block_${bl}" 0 "$persist_dir/config.sh"
    done
    refresh_blocked_counts
    update_status
    log_message SUCCESS "Successfully reset hosts."
    end_time=$(get_current_time)
    log_duration "Resetting hosts" "$start_time" "$end_time"
    echo "[✓] Successfully reverted hosts."
}

build_whitelist_regex() {
    host="$1"
    suffix_wildcard=0
    glob_mode=0

    if echo "$host" | grep -qE '^\*\.|^\.'; then
        suffix_wildcard=1
    elif echo "$host" | grep -q '\*'; then
        glob_mode=1
    fi

    base="$host"
    [ "$suffix_wildcard" -eq 1 ] && base="${base#*.}"
    esc_base=$(echo "$base" | sed -e 's/[.[\^$+?(){}|\\]/\\&/g')

    if [ "$suffix_wildcard" -eq 1 ]; then
        echo "(^|.*\.)${esc_base}$"
    elif [ "$glob_mode" -eq 1 ]; then
        esc_glob=$(echo "$esc_base" | sed 's/\*/.*/g')
        echo "^${esc_glob}$"
    else
        echo "^${esc_base}$"
    fi
}

cmd_whitelist_add() {
    for raw_input in "$@"; do
        if echo "$raw_input" | grep -qE '^https?://'; then
            raw_input=$(echo "$raw_input" | awk -F[/:] '{print $4}')
        fi
        host="$raw_input"

        if ! echo "$host" | grep -qE '(\*|\.)'; then
            echo "[!] Invalid domain input: $raw_input"
            echo "[i] Valid domain input examples: 'domain.com', '*.domain.com', '*something', 'something*'"
            continue
        fi

        if grep -Fxq "$host" "$persist_dir/blacklist.txt" 2>/dev/null; then
            echo "[!] Cannot whitelist $raw_input, it already exists in blacklist."
            continue
        fi

        dom_re=$(build_whitelist_regex "$host")
        touch "$persist_dir/whitelist.txt"
        if grep -qxF "$raw_input" "$persist_dir/whitelist.txt"; then
            echo "[i] $raw_input is already whitelisted"
            continue
        fi

        matched_domains=$(awk -v regex="$dom_re" '$2 ~ regex { print $2 }' "$hosts_file" 2>/dev/null | sort -u)
        if [ -z "$matched_domains" ]; then 
            echo "[!] No matches found for $raw_input"
            continue
        fi

        if [ -s "$persist_dir/blacklist.txt" ]; then
            matched_domains=$(echo "$matched_domains" | grep -Fvxf "$persist_dir/blacklist.txt" || true)
        fi
        if [ -z "$matched_domains" ]; then 
            echo "[!] All matched domains are already blacklisted, nothing to whitelist."
            continue
        fi

        log_message "Whitelisting: $raw_input. Domains: $matched_domains"
        echo "[*] Whitelisting: $raw_input"
        for md in $matched_domains; do
            add_entry "$md" "$persist_dir/whitelist.txt"
        done

        tmp_hosts_file="$persist_dir/tmp.hosts.$$"
        awk -v regex="$dom_re" '
            $1 == "0.0.0.0" && $2 ~ regex { next }
            { print }
        ' "$hosts_file" > "$tmp_hosts_file"
        mv "$tmp_hosts_file" "$hosts_file"
        sort -u "$persist_dir/whitelist.txt" > "$persist_dir/.whitelist.sorted.$$"
        mv "$persist_dir/.whitelist.sorted.$$" "$persist_dir/whitelist.txt"

        echo "[✓] Whitelisted: $raw_input"
        echo "[i] Added the following domain(s) to whitelist and removed from hosts:"
        echo " - $matched_domains"
    done
}

cmd_whitelist_remove() {
    shift 2
    [ $# -ge 1 ] || { echo "[!] No domains/patterns provided to remove."; exit 1; }

    removed_total=""
    for raw in "$@"; do
        if echo "$raw" | grep -qE '^https?://'; then
            raw=$(echo "$raw" | awk -F[/:] '{print $4}')
        fi
        host="$raw"
        [ -n "$host" ] || { echo "[!] Invalid input: $raw"; continue; }

        dom_re=$(build_whitelist_regex "$host")
        matches=$(grep -E "$dom_re" "$persist_dir/whitelist.txt" 2>/dev/null || true)
        if [ -z "$matches" ]; then
            echo "[i] No whitelist matches for: $raw"
            continue
        fi

        echo "[*] Removing from whitelist: $raw"
        removed_total="$removed_total $matches"
        tmpf="$persist_dir/.whitelist.$$"
        grep -Ev "$dom_re" "$persist_dir/whitelist.txt" > "$tmpf" 2>/dev/null || :
        mv "$tmpf" "$persist_dir/whitelist.txt"
    done

    [ -n "$removed_total" ] || { echo "[!] Nothing was removed from whitelist."; exit 1; }

    for dom in $removed_total; do
        if ! grep -qE "^0\.0\.0\.0[[:space:]]+$dom$" "$hosts_file"; then
            append_hosts_entry "$hosts_file" 0.0.0.0 "$dom"
        fi
    done
    log_message SUCCESS "Whitelist multi-remove:$removed_total"
    echo "[✓] Removed the selected domain(s) from whitelist and re-blocked them."
}

cmd_whitelist() {
    start_time=$(get_current_time)
    is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
    is_default_hosts && abort "You cannot whitelist links while hosts is reset."
    action="$2"
    shift 2
    if [ -z "$action" ] || [ $# -eq 0 ] || { [ "$action" != "add" ] && [ "$action" != "remove" ]; }; then
        echo "[!] Invalid arguments for --whitelist|-w"
        echo "[i] Usage: rmlwk --whitelist|-w <add|remove> [domain2] [domain3] ..."
        display_whitelist=$(cat "$persist_dir/whitelist.txt" 2>/dev/null || true)
        if [ -n "$display_whitelist" ]; then
            echo "Current whitelist:"
            echo "$display_whitelist"
        else
            echo "Current whitelist: no saved whitelist"
        fi
        exit 1
    fi

    if [ "$action" = "add" ]; then
        cmd_whitelist_add "$@"
    else
        # Pass dummy first args to match original shift 2 behavior
        cmd_whitelist_remove dummy dummy "$@"
    fi
    refresh_blocked_counts
    update_status
    end_time=$(get_current_time)
    log_duration "Whitelist action: $action" "$start_time" "$end_time"
}

cmd_blacklist() {
    start_time=$(get_current_time)
    is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
    option="$2"
    shift 2

    if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ $# -eq 0 ]; then
        echo "Usage: rmlwk --blacklist, -b <add/remove> <domain1> [domain2] [domain3] ..."
        display_blacklist=$(cat "$persist_dir/blacklist.txt" 2>/dev/null || true)
        if [ -n "$display_blacklist" ]; then
            echo "Current blacklist:"
            echo "$display_blacklist"
        else
            echo "Current blacklist: no saved blacklist"
        fi
        exit 1
    fi

    touch "$persist_dir/blacklist.txt"
    if [ "$option" = "add" ]; then
        raw_input="$1"
        if echo "$raw_input" | grep -qE '^https?://'; then
            raw_input=$(echo "$raw_input" | awk -F[/:] '{print $4}')
        fi
        domain="$raw_input"

        if ! echo "$domain" | grep -qiE '^[a-z0-9.-]+\.[a-z]{2,}$'; then
            echo "[!] Invalid domain: $domain"
            echo "Example valid domain: example.com"
            exit 1
        fi
        if grep -Fxq "$domain" "$persist_dir/whitelist.txt" 2>/dev/null; then
            echo "[!] Cannot blacklist $domain, it already exists in whitelist."
            exit 1
        fi
        if grep -qE "^0\.0\.0\.0[[:space:]]+$domain$" "$hosts_file"; then
            echo "[!] $domain is already blocked."
            exit 1
        fi

        echo "[*] Blacklisting $domain..."
        log_message "Blacklisting $domain..."
        add_entry "$domain" "$persist_dir/blacklist.txt"
        append_hosts_entry "$hosts_file" 0.0.0.0 "$domain"
        echo "[✓] Blacklisted $domain."
        log_message SUCCESS "Done added $domain to hosts file and blacklist."
    else
        total_removed=0
        failed_removals=""
        for domain_to_remove in "$@"; do
            if echo "$domain_to_remove" | grep -qE '^https?://'; then
                domain_to_remove=$(echo "$domain_to_remove" | awk -F[/:] '{print $4}')
            fi
            domain="$domain_to_remove"

            echo "[*] Removing $domain from blacklist..."
            log_message "Removing $domain from blacklist..."
            if grep -qxF "$domain" "$persist_dir/blacklist.txt"; then
                remove_entry "$domain" "$persist_dir/blacklist.txt"
                tmp_hosts_file="$persist_dir/tmp.hosts.$$"
                grep -vF "0.0.0.0 $domain" "$hosts_file" > "$tmp_hosts_file" || :
                mv "$tmp_hosts_file" "$hosts_file"
                log_message "Removed $domain from blacklist and unblocked."
                echo "[✓] $domain has been removed from blacklist and unblocked."
                total_removed=$((total_removed + 1))
            else
                echo "[!] $domain isn't found in blacklist."
                failed_removals="$failed_removals $domain_to_remove"
                log_message WARN "$domain not found in blacklist"
            fi
        done

        [ "$total_removed" -gt 0 ] || { echo "[!] No domains were removed from blacklist"; exit 1; }
        [ -n "$failed_removals" ] && { echo "[i] Failed to remove:$failed_removals"; log_message WARN "Failed to remove domains:$failed_removals"; }
    fi

    refresh_blocked_counts
    update_status
    end_time=$(get_current_time)
    log_duration "Blacklist action: $option" "$start_time" "$end_time"
}

cmd_custom_source() {
    option="$2"
    shift 2
    if [ -z "$option" ] || [ $# -eq 0 ]; then
        echo "[!] Missing arguments."
        echo "Usage: rmlwk --custom-source <add/remove> <domain1> [domain2] [domain3] ..."
        display_sources=$(cat "$persist_dir/custom_source.txt" 2>/dev/null)
        if [ -n "$display_sources" ]; then
            echo "Current custom sources:"
            echo "$display_sources"
        else
            echo "Current custom sources: no saved sources"
        fi
        exit 1
    fi

    if [ "$option" != "add" ] && [ "$option" != "remove" ] && [ "$option" != "edit" ] && [ "$option" != "enable" ] && [ "$option" != "disable" ]; then
        echo "[!] Invalid option: Use 'add', 'remove', 'edit', 'enable', or 'disable'."
        exit 1
    fi

    touch "$persist_dir/custom_source.txt"
    case "$option" in
        add)
            domain="$1"
            shift
            name="$*"
            if ! echo "$domain" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})'; then
                echo "[!] Invalid domain: $domain"
                exit 1
            fi
            if source_url_exists_in_file "$domain" "$persist_dir/custom_source.txt"; then
                echo "[!] $domain is already in sources."
            else
                line="$domain"
                [ -n "$name" ] && line="$domain # $name"
                add_entry "$line" "$persist_dir/custom_source.txt"
                log_message SUCCESS "Added $line to sources."
                echo "[✓] Added $line to sources."
            fi
            ;;
        edit)
            old_domain="$1"
            new_domain="$2"
            shift 2
            new_name="$*"
            if ! echo "$new_domain" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})'; then
                echo "[!] Invalid new domain: $new_domain"
                exit 1
            fi
            if [ "$new_domain" != "$old_domain" ] && source_url_exists_in_file "$new_domain" "$persist_dir/custom_source.txt"; then
                echo "[!] $new_domain is already in sources."
                exit 1
            fi
            if source_url_exists_in_file "$old_domain" "$persist_dir/custom_source.txt"; then
                remove_entry "$old_domain" "$persist_dir/custom_source.txt" 1
                line="$new_domain"
                [ -n "$new_name" ] && line="$new_domain # $new_name"
                add_entry "$line" "$persist_dir/custom_source.txt"
                log_message SUCCESS "Edited $old_domain to $line."
                echo "[✓] Edited $old_domain to $line."
            else
                echo "[!] $old_domain was not found in sources."
                exit 1
            fi
            ;;
        enable|disable)
            total_processed=0
            failed_process=""
            for domain in "$@"; do
                if ! echo "$domain" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})'; then
                    echo "[!] Invalid domain: $domain"
                    failed_process="$failed_process $domain"
                    continue
                fi
                if source_url_exists_in_file "$domain" "$persist_dir/custom_source.txt"; then
                    if [ "$option" = "enable" ]; then
                        sed -i "s|^# OFF # $domain|$domain|g" "$persist_dir/custom_source.txt"
                        log_message SUCCESS "Enabled $domain in sources."
                        echo "[✓] Enabled $domain in sources."
                    else
                        sed -i "s|^$domain|# OFF # $domain|g" "$persist_dir/custom_source.txt"
                        log_message SUCCESS "Disabled $domain in sources."
                        echo "[✓] Disabled $domain in sources."
                    fi
                    total_processed=$((total_processed + 1))
                else
                    echo "[!] $domain was not found in sources."
                    failed_process="$failed_process $domain"
                fi
            done
            [ "$total_processed" -gt 0 ] || { echo "[!] No sources were processed"; exit 1; }
            [ -n "$failed_process" ] && echo "[i] Failed to process:$failed_process"
            ;;
        remove)
            total_removed=0
            failed_removals=""
            for domain_to_remove in "$@"; do
                if ! echo "$domain_to_remove" | grep -qiE '^(https?://[a-z0-9.-]+\.[a-z]{2,}(/.*)?|[a-z0-9.-]+\.[a-z]{2,})'; then
                    echo "[!] Invalid domain format: $domain_to_remove"
                    failed_removals="$failed_removals $domain_to_remove"
                    continue
                fi
                if source_url_exists_in_file "$domain_to_remove" "$persist_dir/custom_source.txt"; then
                    awk -v dom="$domain_to_remove" '{ actual=$1; if (actual=="#") actual=$4; if (actual != dom) print $0 }' "$persist_dir/custom_source.txt" > "$persist_dir/sources.tmp"
                    mv "$persist_dir/sources.tmp" "$persist_dir/custom_source.txt"
                    log_message SUCCESS "Removed $domain_to_remove from sources."
                    echo "[✓] Removed $domain_to_remove from sources."
                    total_removed=$((total_removed + 1))
                else
                    echo "[!] $domain_to_remove was not found in sources."
                    failed_removals="$failed_removals $domain_to_remove"
                fi
            done
            [ "$total_removed" -gt 0 ] || { echo "[!] No sources were removed"; exit 1; }
            [ -n "$failed_removals" ] && echo "[i] Failed to remove:$failed_removals"
            ;;
    esac
}

cmd_custom_rule() {
    start_time=$(get_current_time)
    is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
    option="$2"
    shift 2

    if [ -z "$option" ] || [ $# -eq 0 ]; then
        echo "[!] Missing arguments."
        echo "Usage: rmlwk --custom-rule <add|remove> <IP> <domain>"
        display_rules=$(cat "$persist_dir/custom_rules.txt" 2>/dev/null)
        if [ -n "$display_rules" ]; then
            echo "Current custom rules:"
            echo "$display_rules"
        else
            echo "Current custom rules: no saved custom rules"
        fi
        exit 1
    fi
    if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
        echo "[!] Invalid option: Use 'add' or 'remove'."
        exit 1
    fi

    touch "$persist_dir/custom_rules.txt"
    if [ "$option" = "add" ]; then
        [ $# -ge 2 ] || { echo "[!] Incomplete input."; exit 1; }
        ip="$1"
        domain="$2"
        if echo "$domain" | grep -qE '^https?://'; then
            domain=$(echo "$domain" | awk -F[/:] '{print $4}')
        fi
        if ! echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$'; then
            echo "[!] Invalid IP format: $ip"
            exit 1
        fi
        if ! echo "$domain" | grep -qiE '^[a-z0-9.-]+\.[a-z]{2,}$|^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$'; then
            echo "[!] Invalid domain or IP format: $domain"
            exit 1
        fi
        if awk '{print $2}' "$persist_dir/custom_rules.txt" 2>/dev/null | grep -Fxq "$domain"; then
            echo "[!] Domain $domain already has a custom rule."
            exit 1
        fi
        add_entry "$ip $domain" "$persist_dir/custom_rules.txt"
        log_message SUCCESS "Added custom rule: $ip $domain"
        echo "[✓] Added custom rule: $ip $domain"
        append_hosts_entry "$hosts_file" "$ip" "$domain"
    else
        total_removed=0
        failed_removals=""
        for domain_to_remove in "$@"; do
            if echo "$domain_to_remove" | grep -qE '^https?://'; then
                domain_to_remove=$(echo "$domain_to_remove" | awk -F[/:] '{print $4}')
            fi
            if grep -qw "$domain_to_remove" "$persist_dir/custom_rules.txt"; then
                remove_entry "$domain_to_remove" "$persist_dir/custom_rules.txt" 2
                tmp_hosts_file="$persist_dir/tmp.hosts.$$"
                grep -vE "^[0-9a-fA-F:.]+ $domain_to_remove$" "$hosts_file" > "$tmp_hosts_file" 2>/dev/null || :
                mv "$tmp_hosts_file" "$hosts_file"
                log_message SUCCESS "Removed custom rule for $domain_to_remove."
                echo "[✓] Removed custom rule for $domain_to_remove."
                total_removed=$((total_removed + 1))
            else
                echo "[!] $domain_to_remove was not found in custom rules."
                failed_removals="$failed_removals $domain_to_remove"
            fi
        done
        [ "$total_removed" -gt 0 ] || { echo "[!] No custom rules were removed"; exit 1; }
        [ -n "$failed_removals" ] && echo "[i] Failed to remove rules for:$failed_removals"
    fi

    refresh_blocked_counts
    update_status
    end_time=$(get_current_time)
    log_duration "Custom rule action: $option" "$start_time" "$end_time"
}

cmd_toggle_blocklist() {
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
        block_trackers "$status"
    else
        eval "block_toggle=\$block_${block_type}"
        if [ "$status" = "disable" ] || [ "$status" = 0 ]; then
            if [ "$block_toggle" = 0 ]; then
                echo "[i] $block_type block is already disabled"
                exit 0
            fi
            log_message "Disabling ${block_type} blocklist has been initiated."
            echo "[*] Disabling ${block_type} blocklist has been initiated."
            block_content "$block_type" 0
            log_message SUCCESS "Disabled ${block_type} blocklist successfully."
            echo "[✓] Disabled ${block_type} blocklist successfully."
        else
            if [ "$block_toggle" = 1 ]; then
                echo "[!] ${block_type} block is already enabled"
                exit 0
            fi
            log_message "Enabling block entries for $block_type has been initiated."
            echo "[*] Enabling block entries for ${block_type} has been initiated."
            block_content "$block_type" 1
            log_message SUCCESS "Enabled ${block_type} blocklist successfully."
            echo "[✓] Enabled ${block_type} blocklist successfully."
        fi
    fi

    refresh_blocked_counts
    update_status
    end_time=$(get_current_time)
    log_duration "Toggling ${block_type} blocklist" "$start_time" "$end_time"
}

cmd_update_hosts() {
    start_time=$(get_current_time)
    current_profile=$(get_prop profile "$persist_dir/config.sh" || echo "default")
    profile_file=$(resolve_profile_file "$current_profile")
    
    hosts_list=$( {
        list_source_urls_from_file "$profile_file"
        list_source_urls_from_file "$persist_dir/custom_source.txt"
    } | sort -u)

    [ -n "$hosts_list" ] || abort "No hosts sources were found, Aborting."
    echo "$hosts_list" | grep http >/dev/null || abort "No hosts sources were found, Aborting."
    is_protection_paused && abort "Ad-block is paused. Please resume before running this command."

    if [ -d /data/adb/modules/Re-Malwack ]; then
        echo "[*] Upgrading Anti-Ads fortress 🏰"
        log_message "Updating protections..."
    else
        echo "[*] Building Anti-Ads fortress 🏰"
        log_message "Installing protection for the first time"
    fi

    check_internet
    combined_file="${tmp_hosts}_all"
    echo "" > "$combined_file"
    echo "[*] Fetching base hosts..."
    log_message "Starting download of base hosts"

    counter=0
    download_limit=3
    download_count=0
    for host in $hosts_list; do
        counter=$((counter + 1))
        echo "$host" > "${tmp_hosts}${counter}.url"
        fetch "${tmp_hosts}${counter}" "$host" &
        download_count=$((download_count + 1))
        if [ "$download_count" -ge "$download_limit" ]; then
            wait
            download_count=0
        fi
    done
    wait
    log_message SUCCESS "Completed download hosts from $counter source(s)"

    job_limit=3
    job_count=0
    mkdir -p "$persist_dir/counts"
    echo "" > "$persist_dir/counts/sources.counts"
    for i in $(seq 1 "$counter"); do
        (
            if [ -f "${tmp_hosts}${i}" ]; then
                host_process "${tmp_hosts}${i}"
                if [ -f "${tmp_hosts}${i}.url" ]; then
                    host_url=$(cat "${tmp_hosts}${i}.url")
                    entries_count=$(wc -l < "${tmp_hosts}${i}")
                    echo "${host_url}|${entries_count}" >> "$persist_dir/counts/sources.counts"
                    log_message SUCCESS "Downloaded $entries_count entries from $host_url"
                fi
                ensure_trailing_newline "$combined_file"
                cat "${tmp_hosts}${i}" >> "$combined_file"
            fi
        ) &
        job_count=$((job_count + 1))
        if [ "$job_count" -ge "$job_limit" ]; then
            wait
            job_count=0
        fi
    done
    wait
    log_message "Completed processing of all source files"

    for bl in $RMLWK_BLOCKLIST_TYPES; do
        block_var="block_${bl}"
        eval "enabled=\${$block_var}"
        [ -n "$enabled" ] || enabled=0
        [ "$enabled" = "0" ] && continue

        echo "[*] Fetching blocklist: $bl"
        log_message "Fetching blocklist: $bl"
        mkdir -p "$persist_dir/cache/$bl"
        fetch_blocklist "$bl"
        bl_count=0
        for file in "$persist_dir/cache/$bl/hosts"*; do
            if [ -f "$file" ]; then
                host_process "$file"
                file_count=$(wc -l < "$file")
                bl_count=$((bl_count + file_count))
            fi
        done
        echo "${bl}|${bl_count}" >> "$persist_dir/counts/blocklists.counts"
        ensure_trailing_newline "$combined_file"
        cat "$persist_dir/cache/$bl/hosts"* >> "$combined_file"
        echo "[✓] Fetched $bl blocklist"
        log_message "Added $bl ($bl_count) hosts entries to combined hosts"
    done

    echo "[*] Installing hosts"
    log_message "Writing new hosts file"
    reset_hosts
    install_hosts "all"

    refresh_blocked_counts
    update_status
    log_message SUCCESS "Successfully updated all hosts."
    [ "$MODDIR" != "/data/adb/modules_update/Re-Malwack" ] && echo "[✓] Everything is now Good!"
    end_time=$(get_current_time)
    log_duration "Updating hosts" "$start_time" "$end_time"
}

cmd_dns_logging() {
    status="$1"
    [ -z "$status" ] && { echo "[!] Missing argument for --dns-logging"; exit 1; }

    if [ "$status" = "enable" ]; then
        if [ "$dns_logging" = "1" ]; then
            echo "[i] DNS logging is already enabled."
            exit 0
        fi
        echo "[*] Enabling DNS logging..."
        set_prop dns_logging 1 "$persist_dir/config.sh"
        touch "$persist_dir/reboot_required"
        log_message SUCCESS "DNS logging enabled. Reboot required."
        echo "[✓] DNS logging enabled. Please reboot your device to apply changes."
    elif [ "$status" = "disable" ]; then
        if [ "$dns_logging" = "0" ]; then
            echo "[i] DNS logging is already disabled."
            exit 0
        fi
        echo "[*] Disabling DNS logging..."
        set_prop dns_logging 0 "$persist_dir/config.sh"
        rm -f "$persist_dir/dns.log"
        touch "$persist_dir/reboot_required"
        log_message SUCCESS "DNS logging disabled. Reboot required."
        echo "[✓] DNS logging disabled. Please reboot your device to apply changes."
    else
        echo "[!] Invalid argument for --dns-logging. Use 'enable' or 'disable'."
        exit 1
    fi
}

show_help() {
    cat << EOC
[i] Usage: rmlwk [--argument] OPTIONAL: [--quiet]
  --update-hosts, -u
    Update the hosts file.

  --profile, -p <name|create|delete|list> ...
    Manage adblock level profiles.
    - list: List available profiles
    - create <name> [desc]: Create a new user profile
    - delete <name>: Delete a user profile
    - <name>: Switch to profile

  --auto-update, -a <enable|disable>
    Toggle auto hosts update.

  --custom-source, -c <add|remove|edit> ...
    Add/remove/edit custom hosts sources.

  --custom-rule, -cr <add|remove> <IP> <domain>
    Add or remove custom hosts rules.

  --reset, -r
    Reset hosts file to default.

  --query-domain, -q <domain>
    Query if a domain is blocked, redirected, or not blocked.

  --adblock-switch, -as
    Toggle protections on/off.

  --dns-logging <enable|disable>
    Toggle DNS logging.

  --block-trackers, -bt <disable>
    Block trackers, use disable to unblock.

  --block-porn, -bp <disable>
    Block pornographic sites, use disable to unblock.

  --block-gambling, -bg <disable>
    Block gambling sites, use disable to unblock.

  --block-fakenews, -bf <disable>
    Block fake news sites, use disable to unblock.

  --block-social, -bs <disable>
    Block social media sites, use disable to unblock.

  --whitelist, -w <add|remove> <domain|pattern> <domain2> ...
    Whitelist domain(s).

  --blacklist, -b <add|remove> <domain1> <domain2> ...
    Blacklist domain(s).

  --export-logs, -e
    Export logs to a tarball in Download directory.

  --help, -h
    Display help.
EOC
    printf '\033[0;31m Example command: su -c rmlwk --update-hosts\033[0m\n'
}
