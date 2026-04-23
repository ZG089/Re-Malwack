[ "${RMLWK_LIB_STATUS:-0}" -eq 1 ] && return 0
RMLWK_LIB_STATUS=1

is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ] \
    || { [ "$blocked_mod" -eq "$blacklist_count" ] && [ "$blocked_sys" -eq "$blacklist_count" ]; }
}

is_protection_paused() {
    [ -f "$persist_dir/hosts.bak" ] || return 1
}

identify_enabled_blocklists() {
    enabled_blocklists=""
    for bl in $RMLWK_BLOCKLIST_TYPES; do
        eval enabled="\$block_${bl}"
        if [ "$enabled" = "1" ]; then
            if [ -z "$enabled_blocklists" ]; then
                enabled_blocklists=" $bl"
            else
                enabled_blocklists="$enabled_blocklists - $bl"
            fi
        fi
    done
}

refresh_blocked_counts() {
    mkdir -p "$persist_dir/counts"
    log_message INFO "Refreshing blocked entries counts"
    blocked_mod=$(count_entries $hosts_file)
    blocked_sys=$(count_entries $system_hosts)
    custom_entries=$(count_entries $persist_dir/custom_rules.txt)
    echo $blocked_sys > "$persist_dir/counts/blocked_sys.count"
    echo $blocked_mod > "$persist_dir/counts/blocked_mod.count"
    echo $custom_entries > "$persist_dir/counts/custom_entries.count"
    log_message "Module hosts: $blocked_mod entries, System hosts: $blocked_sys entries, Custom rules: $custom_entries"
}

remount_hosts() {
    if [ "$is_znhr_detected" -eq 1 ]; then
        log_message "zn-hostsredirect detected, skipping mount operation"
        return 0
    fi

    log_message "Attempting to remount hosts..."
    if [ -n "$system_hosts_lines" ] || [ -n "$module_hosts_lines" ]; then
        log_message "system hosts file lines count: $system_hosts_lines, module hosts file lines count: $module_hosts_lines"
    fi
    echo "[*] Attempting to remount hosts..."
    umount -l "$system_hosts" 2>/dev/null || log_message WARN "Failed to unmount $system_hosts"
    mount --bind "$hosts_file" "$system_hosts" || {
        log_message ERROR "Failed to bind mount $hosts_file to $system_hosts"
        echo "[!] Failed to remount hosts, please report to developer!"
        return 1
    }
    log_message SUCCESS "Hosts remounted successfully."
    echo "[✓] Hosts remounted successfully."
}

update_status() {
    local start_time
    start_time=$(get_current_time)
    status_msg=""

    rmlwk_source_config
    log_message SUCCESS "Loaded config file!"
    log_message "Selected profile: ${profile:-default}"
    log_message INFO "Updating module status"

    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1)
    blocked_sys=$(cat "$persist_dir/counts/blocked_sys.count" 2>/dev/null || true)
    blocked_mod=$(cat "$persist_dir/counts/blocked_mod.count" 2>/dev/null || true)
    blacklist_count=$(count_entries $persist_dir/blacklist.txt)
    whitelist_count=$(count_entries $persist_dir/whitelist.txt)
    custom_entries=$(count_entries $persist_dir/custom_rules.txt)

    log_message "Last hosts file update was in: $last_mod"
    log_message "Blacklist entries count: $blacklist_count"
    log_message "Whitelist entries count: $whitelist_count"
    log_message "Custom rules count: $custom_entries"

    identify_enabled_blocklists
    if [ -n "$enabled_blocklists" ]; then
        log_message INFO "Enabled blocklists:$enabled_blocklists"
    else
        log_message INFO "No blocklists enabled"
    fi

    # Build mode/dns suffix strings
    if [ "$is_znhr_detected" -eq 1 ]; then
        mode="hosts mount mode: zn-hostsredirect"
    else
        mode="hosts mount mode: Standard mount"
    fi
    [ "$dns_logging" = "1" ] && dns_status=" | 🔍 DNS Logging: ON" || dns_status=""

    # Profile display
    [ -z "$profile" ] && profile="default"
    capitalized_profile="$(echo "$profile" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    # Clear mode_ready if hosts have blocked entries
    if [ -f "$persist_dir/mode_ready" ] && [ "$blocked_mod" -gt 0 ]; then
        rm -f "$persist_dir/mode_ready"
        log_message "Cleared mode_ready flag, hosts file has $blocked_mod blocked entries"
    fi

    if [ -f "$persist_dir/reboot_required" ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (DNS Logging) | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif [ -f "$persist_dir/mode_ready" ]; then
        status_msg="Status: Protection is idle 💤 | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif is_protection_paused; then
        status_msg="Status: Protection is paused ⏸️ | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif [ -d /data/adb/modules_update/Re-Malwack ] && [ -d /data/adb/modules/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (pending module update) | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif [ -d /data/adb/modules_update/Re-Malwack ] && [ ! -d /data/adb/modules/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (First time install) | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif is_default_hosts; then
        if [ "$blacklist_count" -gt 0 ]; then
            plural="entries are active"
            [ "$blacklist_count" -eq 1 ] && plural="entry is active"
            status_msg="Status: Protection is disabled due to reset ❌ | ⚙️ Profile: $capitalized_profile${dns_status} | $blacklist_count blacklist $plural"
        else
            status_msg="Status: Protection is disabled due to reset ❌ | ⚙️ Profile: $capitalized_profile${dns_status}"
        fi
    elif [ "$blocked_mod" -ge 0 ]; then
        if [ "$blocked_mod" -ne "$blocked_sys" ] && [ "$is_znhr_detected" -ne 1 ]; then
            remount_hosts
            refresh_blocked_counts
            if [ "$blocked_mod" -ne "$blocked_sys" ]; then
                status_msg="Status: ❌ Critical Error Detected (Hosts Mount Failure). Please check your root manager settings and disable any conflicted module(s)."
                echo "[!!!] Critical Error Detected (Hosts Mount Failure). Please check your root manager settings and disable any conflicted module(s)."
                echo "[!!!] Module hosts blocks $blocked_mod domains, System hosts blocks $blocked_sys domains."
            fi
        fi

        if [ -z "$status_msg" ]; then
            if [ "$(date +%m%d)" = "0401" ]; then
                blocking_info="Allowing $blocked_mod ads"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Allowing $((blocked_mod - blacklist_count)) ads + $blacklist_count (blacklist)"
                status_msg="Status: Protection is Vulnerable ✅ | ⚙️ Profile: $capitalized_profile${dns_status} | $blocking_info"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Allowlists:$enabled_blocklists"
                set_prop name "Re-Malware | Not just a normal malware module ✨" "$MODDIR/module.prop"
                set_prop banner "banner_alt.png" "$MODDIR/module.prop"
            else
                blocking_info="Blocking $blocked_mod domains"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Blocking $((blocked_mod - blacklist_count)) domains + $blacklist_count (blacklist)"
                status_msg="Status: Protection is enabled ✅ | ⚙️ Profile: $capitalized_profile${dns_status} | $blocking_info"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Blocklists:$enabled_blocklists"
                set_prop name "Re-Malwack | Not just a normal ad-blocker module ✨" "$MODDIR/module.prop"
                set_prop banner "banner.png" "$MODDIR/module.prop"
            fi
        fi
    fi

    set_prop description "$status_msg" "$MODDIR/module.prop"
    log_message "$status_msg"
    local end_time
    end_time=$(get_current_time)
    log_duration "Updating module status" "$start_time" "$end_time"
}
