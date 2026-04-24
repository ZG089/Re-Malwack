[ "${RMLWK_LIB_HOSTS:-0}" -eq 1 ] && return 0
RMLWK_LIB_HOSTS=1

host_process() {
    CURRENT_SCRIPT="hosts.sh"; CURRENT_FUNC="host_process"
    local file="$1"
    echo "$file" | tr '[:upper:]' '[:lower:]' | grep -q "whitelist" && return 0
    log_message "Filtering $file..."
    sed -i '/^[[:space:]]*#/d; s/[[:space:]]*#.*$//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//; s/[[:space:]]\+/ /g; s/127.0.0.1/0.0.0.0/g' "$file"
}

apply_custom_rules() {
    CURRENT_SCRIPT="hosts.sh"; CURRENT_FUNC="apply_custom_rules"
    if [ -s "$persist_dir/custom_rules.txt" ]; then
        log_message "Re-Applying custom rules..."
        echo "[*] Re-Applying custom rules..."
        ensure_trailing_newline "$hosts_file"
        cat "$persist_dir/custom_rules.txt" >> "$hosts_file"
    fi
}

stage_blocklist_files() {
    local block_type="$1"
    local i=1
    for file in "$persist_dir/cache/$block_type/hosts"*; do
        [ -f "$file" ] || continue
        cp -f "$file" "${tmp_hosts}${i}"
        i=$((i + 1))
    done
}

install_hosts() {
    CURRENT_SCRIPT="hosts.sh"; CURRENT_FUNC="install_hosts"
    type="$1"
    local start_time
    start_time=$(get_current_time)

    log_message "Fetching module's repo whitelist files"
    mkdir -p "$persist_dir/cache/whitelist"
    fetch "$persist_dir/cache/whitelist/whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt
    fetch "$persist_dir/cache/whitelist/social_whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt
    log_message "Starting to install $type hosts."

    cp -f "$hosts_file" "${tmp_hosts}0"
    log_message "Preparing Blacklist..."
    if [ -s "$persist_dir/blacklist.txt" ]; then
        awk 'NF && $1 !~ /^#/ { print "0.0.0.0", $1 }' "$persist_dir/blacklist.txt" >> "${tmp_hosts}0"
    fi

    log_message "Processing Whitelist..."
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"
    if [ "${block_social:-0}" -eq 0 ] && [ "$type" != "social" ]; then
        whitelist_file="$whitelist_file $persist_dir/cache/whitelist/social_whitelist.txt"
    else
        log_message WARN "Social Block triggered, Social whitelist won't be applied"
    fi
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    for file in $whitelist_file; do
        if [ ! -f "$file" ]; then
            log_message WARN "Whitelist file $file does not exist!"
        elif [ ! -s "$file" ]; then
            log_message WARN "Whitelist file $file is empty!"
        else
            log_message "Whitelist file $file found with content."
        fi
    done

    cat $whitelist_file | sed '/#/d; /^$/d' | awk '{print "0.0.0.0", $0}' > "${tmp_hosts}w"
    if [ ! -s "${tmp_hosts}w" ]; then
        log_message WARN "Whitelist is empty. Skipping whitelist filtering."
    fi

    if [ -f "$combined_file" ]; then
        log_message "Detected unified hosts, sorting..."
        ensure_trailing_newline "$combined_file"
        cat "${tmp_hosts}0" >> "$combined_file"
        awk '!seen[$0]++' "$combined_file" > "${tmp_hosts}merged.sorted"
    else
        log_message "Detected multiple hosts files, merging and sorting... (Blocklist toggles only)"
        LC_ALL=C sort -u "${tmp_hosts}"[!0] "${tmp_hosts}0" > "${tmp_hosts}merged.sorted"
    fi

    log_message "Filtering hosts"
    grep -Fvxf "${tmp_hosts}w" "${tmp_hosts}merged.sorted" > "$hosts_file" || {
        log_message WARN "Failed to filter with grep, trying awk fallback"
        awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmp_hosts}w" "${tmp_hosts}merged.sorted" > "$hosts_file"
    }
    apply_custom_rules

    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully installed $type hosts."
    local end_time
    end_time=$(get_current_time)
    log_duration "Installing hosts (Type: $type)" "$start_time" "$end_time"
}

remove_hosts() {
    CURRENT_SCRIPT="hosts.sh"; CURRENT_FUNC="remove_hosts"
    local start_time
    start_time=$(get_current_time)
    log_message "Starting to remove hosts."

    cp -f "$hosts_file" "${tmp_hosts}0"
    cat "$cache_hosts"* | sort -u > "${tmp_hosts}1"
    awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmp_hosts}1" "${tmp_hosts}0" > "$hosts_file"

    if [ ! -s "$hosts_file" ]; then
        echo "[!] Hosts file is empty. Restoring default entries."
        log_message WARN "Detected empty hosts file"
        log_message "Restoring default entries..."
        reset_hosts
    fi

    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully removed hosts."
    local end_time
    end_time=$(get_current_time)
    log_duration "Removing hosts" "$start_time" "$end_time"
}

query_domain() {
    CURRENT_SCRIPT="hosts.sh"; CURRENT_FUNC="query_domain"
    local domain="$1"

    if [ -z "$domain" ]; then
        echo "[!] No domain provided."
        echo "[i] Usage: rmlwk --query-domain <domain> or rmlwk -q <domain>"
        echo "[i] Example: rmlwk --query-domain example.com"
        exit 1
    fi

    if echo "$domain" | grep -qE '^https?://'; then
        domain=$(echo "$domain" | awk -F[/:] '{print $4}')
    fi

    if ! echo "$domain" | grep -qiE '^[a-z0-9]([a-z0-9-]*\.)*[a-z0-9-]*[a-z0-9]$|^[a-z0-9]$'; then
        abort "Invalid domain format: $domain"
    fi

    log_message "Querying domain: $domain"
    entry=$(grep -E "^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[0-9a-fA-F:]+)[[:space:]]+${domain}([[:space:]]|$)" "$hosts_file" 2>/dev/null | head -1)

    if [ -z "$entry" ]; then
        echo "[i] Domain '$domain' is NOT blocked"
        log_message "Domain query result: $domain is NOT blocked"
        return 0
    fi

    ip=$(echo "$entry" | awk '{print $1}')
    case "$ip" in
        0.0.0.0)
            echo "[!] Domain '$domain' IS BLOCKED"
            echo "[i] IP: $ip"
            log_message "Domain query result: $domain IS BLOCKED with IP $ip"
            ;;
        *)
            echo "[→] Domain '$domain' IS REDIRECTED"
            echo "[i] Redirected to IP: $ip"
            log_message "Domain query result: $domain IS REDIRECTED to IP $ip"
            ;;
    esac
}
