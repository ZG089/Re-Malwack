[ "${RMLWK_LIB_BLOCKLISTS:-0}" -eq 1 ] && return 0
RMLWK_LIB_BLOCKLISTS=1

block_content() {
    block_type=$1
    status=$2
    cache_hosts="$persist_dir/cache/$block_type/hosts"
    mkdir -p "$persist_dir/cache/$block_type"

    if [ "$status" = 0 ]; then
        if [ ! -f "${cache_hosts}1" ]; then
            log_message WARN "No cached $block_type blocklist found, redownloading to disable properly."
            echo "[!] No cached $block_type blocklist found, redownloading to disable properly"
            check_internet
            fetch_blocklist "$block_type"
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
            stage_blocklist_files "$block_type"
            install_hosts "$block_type"
        fi
        remove_hosts
        set_prop "block_${block_type}" 0 "$persist_dir/config.sh"
        log_message SUCCESS "Disabled $block_type blocklist."
    else
        if [ ! -f "${cache_hosts}1" ] || [ "$status" = "update" ]; then
            check_internet
            echo "[*] Downloading hosts for $block_type block."
            fetch_blocklist "$block_type"
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
        fi

        if [ "$status" != "update" ]; then
            stage_blocklist_files "$block_type"
            install_hosts "$block_type"
            set_prop "block_${block_type}" 1 "$persist_dir/config.sh"

            bl_count=0
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                if [ -f "$file" ]; then
                    file_count=$(wc -l < "$file")
                    bl_count=$((bl_count + file_count))
                fi
            done
            log_message SUCCESS "Enabled $block_type blocklist ($bl_count entries)."
        fi
    fi
}

block_trackers() {
    local start_time
    start_time=$(get_current_time)
    status=$1
    cache_dir="$persist_dir/cache/trackers"
    cache_hosts="$cache_dir/hosts"
    mkdir -p "$cache_dir"
    brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')

    if [ "$status" = "disable" ] || [ "$status" = 0 ]; then
        if [ "$block_trackers" = 0 ]; then
            echo "[!] Trackers block is already disabled"
            return 0
        fi

        if ! ls "${cache_hosts}"* >/dev/null 2>&1; then
            check_internet
            log_message WARN "No cached trackers blocklist file found for $brand device, redownloading before removal."
            echo "[!] No cached trackers blocklist file(s) found for $brand device, redownloading before removal."
            fetch_blocklist "trackers"
            for file in "$persist_dir/cache/trackers/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
            stage_blocklist_files "trackers"
            install_hosts "trackers"
        fi
        echo "[*] Disabling trackers block for $brand device"
        remove_hosts
        set_prop block_trackers 0 "$persist_dir/config.sh"
        log_message SUCCESS "Trackers blocklist disabled."
        local end_time
        end_time=$(get_current_time)
        log_duration "Disabling trackers block" "$start_time" "$end_time"
        echo "[✓] Trackers block has been disabled"
    else
        if [ "$block_trackers" = 1 ]; then
            echo "[!] Trackers block is already enabled"
            return 0
        fi

        if ! ls "${cache_hosts}"* >/dev/null 2>&1; then
            check_internet
            log_message "Fetching trackers block hosts for $brand"
            echo "[*] Fetching trackers block files for $brand"
            fetch_blocklist "trackers"
            for file in "$persist_dir/cache/trackers/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
        fi
        log_message "Enabling trackers block"
        echo "[*] Enabling trackers block for $brand"
        stage_blocklist_files "trackers"
        install_hosts "trackers"
        set_prop block_trackers 1 "$persist_dir/config.sh"

        tr_count=0
        for file in "$persist_dir/cache/trackers/hosts"*; do
            if [ -f "$file" ]; then
                file_count=$(wc -l < "$file")
                tr_count=$((tr_count + file_count))
            fi
        done
        log_message SUCCESS "Trackers blocklist enabled ($tr_count entries)."
        local end_time
        end_time=$(get_current_time)
        log_duration "Enabling trackers block" "$start_time" "$end_time"
        echo "[✓] Trackers block has been enabled"
    fi
}
