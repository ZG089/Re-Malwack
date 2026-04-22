[ "${RMLWK_LIB_PROTECTION:-0}" -eq 1 ] && return 0
RMLWK_LIB_PROTECTION=1

pause_protections() {
    if is_protection_paused; then
        resume_protections
        exit 0
    fi

    if is_default_hosts; then
        abort "You cannot pause protections while hosts is reset."
    fi

    local start_time
    start_time=$(get_current_time)
    log_message "Pausing Protections"
    echo "[*] Pausing Protections"
    cp "$hosts_file" "$persist_dir/hosts.bak"
    reset_hosts
    set_prop adblock_switch 1 "$persist_dir/config.sh"
    refresh_blocked_counts
    update_status
    log_message SUCCESS "Protection has been paused."
    local end_time
    end_time=$(get_current_time)
    log_duration "Pausing protections" "$start_time" "$end_time"
    echo "[✓] Protection has been paused."
}

resume_protections() {
    local start_time
    start_time=$(get_current_time)
    log_message "Resuming protection."
    echo "[*] Resuming protection"

    if [ -f "$persist_dir/hosts.bak" ]; then
        cat "$persist_dir/hosts.bak" > "$hosts_file"
        rm -f "$persist_dir/hosts.bak"
        set_prop adblock_switch 0 "$persist_dir/config.sh"
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Protection has been resumed."
        local end_time
        end_time=$(get_current_time)
        log_duration "Resuming protections" "$start_time" "$end_time"
        echo "[✓] Protection has been resumed."
    else
        log_message WARN "No backup hosts file found to resume"
        log_message "Force resuming protection and running hosts update as a fallback action"
        echo "[!] No backup hosts file found to resume."
        sleep 0.5
        echo "[i] Force resuming protection and running hosts update as a fallback action"
        check_internet
        sleep 2
        set_prop adblock_switch 0 "$persist_dir/config.sh"
        exec "$0" --quiet --update-hosts
    fi
}
