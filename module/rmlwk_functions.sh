#!/system/bin/sh

# check if we are executed from the main srcipt DUMB IDEA btw
[ -z "${rmlwkExec}" ] && exit 1
# yeah, that shellcheck (3043) is something that we shouldn't disable# since we are in android, we can safely do that - ikuyo-kita07
# shellcheck disable=SC3043

rmlwk_banner() {
    [ "$quiet_mode" -eq 1 ] && return
    clear
    if [ "$(date +%m%d)" = "0401" ]; then
        printf '\033[0;31m'
        printf "██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗ ██████╗ ███████╗\n"
        printf "██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔══██╗██╔════╝\n"
        printf "██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██████╔╝█████╗  \n"
        printf "██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██╔══██╗██╔══╝  \n"
        printf "██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║███████╗\n"
        printf "╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝\n"
        printf '\033[0m'
    else
        printf '\033[0;31m'
        printf "██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗\n"
        printf "██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝\n"
        printf "██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ \n"
        printf "██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ \n"
        printf "██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗\n"
        printf "╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝\n"
    fi
    printf '\033[0m'
    echo ""
    echo "$version - $status_msg"
    printf '\033[0;31m'
    echo "================================================================="
    printf '\033[0m'
}

# Sanitize domain input: strip protocol (http/https) and www. prefix
sanitize_domain() {
    local input="$1"
    if printf '%s' "$input" | grep -qE '^https?://'; then
        input=$(printf '%s' "$input" | awk -F[/:] '{print $4}')
    fi
    printf '%s' "$input" | sed 's/^www\.//'
}

# function to check hosts file reset state
# Becomes true in case of both hosts counts = 0
# And becomes also true in case of blocked entries in both module and system hosts equals the blacklist file
# AKA only blacklisted entries are active
# -- shellcheck issue: SC2015 - can be skippable ig
is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ] \
    || { [ "$blocked_mod" -eq "$blacklist_count" ] && [ "$blocked_sys" -eq "$blacklist_count" ]; }
}

# function to process hosts, maybe?
host_process() {
    file="$1"
    log_message "Filtering $file..."
    awk '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        {
            ip   = $1
            host = $2
            if (host ~ /localhost/) {
                print "127.0.0.1 localhost"
                print "::1 localhost"
                next
            }
            if (ip == "127.0.0.1") ip = "0.0.0.0"
            if (ip != "" && host != "") printf "%s %s\n", ip, host
        }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# function to apply custom rules
apply_custom_rules() {
    if [ -s "$persist_dir/custom_rules.txt" ]; then
        log_message "Re-Applying custom rules..."
        echo "[*] Re-Applying custom rules..."
        # Ensure hosts file ends with a newline before appending
        if [ -s "$hosts_file" ]; then
            last_line=$(tail -n 1 "$hosts_file")
            [ -n "$last_line" ] && echo "" >> "$hosts_file"
        fi
        cat "$persist_dir/custom_rules.txt" >> "$hosts_file"
    fi
}

# function to count blocked entries and store them
refresh_blocked_counts() {
    mkdir -p "$persist_dir/counts"
    log_message INFO "Refreshing blocked entries counts"
    blocked_mod=$(grep -c "0.0.0.0" $hosts_file || true)
    blocked_sys=$(grep -c "0.0.0.0" $system_hosts || true)
    echo "$blocked_sys" > "$persist_dir/counts/blocked_sys.count"
    echo "$blocked_mod" > "$persist_dir/counts/blocked_mod.count"
    log_message "Module hosts: $blocked_mod entries, System hosts: $blocked_sys entries"
}

# helper functions: - ikuyo
setConfigProperty()
{
    file="$3"
    [ -z "$file" ] && file="/data/adb/Re-Malwack/config.sh"
    sed -i "s/^$1=.*/$1=$2/" $file;
    # pray to god that we don't fail.
}

getConfigProperty() 
{
    file="$2"
    [ -z "$file" ] && file="/data/adb/Re-Malwack/config.sh"
    grep -m 1 "^$1=" "$file" 2>/dev/null | cut -d= -f2- | tr -d '\r'
}
# helper functions: - ikuyo

# function to check adblock pause
is_protection_paused() {
    [ -f "$persist_dir/hosts.bak" ]
}

# Returns 0 if the given profile (defaults to $profile) is a built-in one
# i.e. it ships with the module inside MODDIR/profiles/
is_builtin_profile() {
    local p="${1:-$profile}"
    [ -f "$MODDIR/profiles/${p}.txt" ]
}

# Returns 0 if the given profile (defaults to $profile) was created by the user
# i.e. it exists in persist_dir/profiles/ but is NOT a built-in profile
is_user_profile() {
    local p="${1:-$profile}"
    [ -f "$persist_dir/profiles/${p}.txt" ] && ! is_builtin_profile "$p"
}

# 1 - Pause adblock
pause_protections() {
    # Check if protection is paused, enable if it is paused.
    if is_protection_paused; then
        resume_protections
        exit 0
    fi
    # Prevent pausing if hosts is reset
    if is_default_hosts && ! is_protection_paused; then
        abort "You cannot pause protections while hosts is reset."
    fi
    local start_time
    start_time=$(get_current_time)
    log_message "Pausing Protections"
    echo "[*] Pausing Protections"
    cp "$hosts_file" "$persist_dir/hosts.bak"
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
    setConfigProperty "adblock_switch" "1"
    refresh_blocked_counts
    update_status
    log_message SUCCESS "Protection has been paused."
    local end_time
    end_time=$(get_current_time)
    log_duration "Pausing protections" "$start_time" "$end_time"
    echo "[✓] Protection has been paused."
}

# 2 - Resume adblock
resume_protections() {
    local start_time
    start_time=$(get_current_time)
    log_message "Resuming protection."
    echo "[*] Resuming protection"
    if [ -f "$persist_dir/hosts.bak" ]; then
        cat "$persist_dir/hosts.bak" > "$hosts_file"
        rm -f $persist_dir/hosts.bak
        setConfigProperty "adblock_switch" "0"
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
        setConfigProperty "adblock_switch" "1"
        exec "$0" --quiet --update-hosts
    fi
}

# Logging func - Literally helpful for any dev :D
log_message() {
    # Handle optional log level (default: INFO)
    case "$1" in
        INFO|WARN|ERROR|SUCCESS)
            level="$1"
            shift
            ;;
        *)
            level="INFO"
            ;;
    esac
    msg="$*"
    echo "[$(date +"%Y-%m-%d %I:%M:%S %p")] - [$level] - $msg" >> "$LOGFILE"
}

# function to get current time in milliseconds
get_current_time() {
    # Using date +%s%N for nanoseconds
    # Fallback to %s if %N is not supported
    time_ns=$(date +%s%N 2>/dev/null)
    if [ $? -ne 0 ] || [ "$time_ns" = "%s%N" ]; then
        # Fallback: use seconds only, return as milliseconds
        time_ms=$(($(date +%s) * 1000))
    else
        # Convert nanoseconds to milliseconds by dividing by 1,000,000
        time_ms=$((time_ns / 1000000))
    fi
    echo "$time_ms"
}

# function to format duration from milliseconds to human-readable format
# Smart format: only shows non-zero units (e.g., "1m, 42s and 433ms" or "5s and 234ms")
format_duration() {
    local duration_ms=$1
    local minutes=$(( duration_ms / 60000 ))
    local remainder=$(( duration_ms % 60000 ))
    local seconds=$(( remainder / 1000 ))
    local milliseconds=$(( remainder % 1000 ))
    local parts=""

    # Add minutes if non-zero
    if [ "$minutes" -gt 0 ]; then
        if [ "$minutes" -eq 1 ]; then
            parts="1m"
        else
            parts="${minutes}m"
        fi
    fi

    # Add seconds if non-zero
    if [ "$seconds" -gt 0 ]; then
        if [ -z "$parts" ]; then
            if [ "$seconds" -eq 1 ]; then
                parts="1s"
            else
                parts="${seconds}s"
            fi
        else
            if [ "$seconds" -eq 1 ]; then
                parts="$parts, 1s"
            else
                parts="$parts, ${seconds}s"
            fi
        fi
    fi

    # Add milliseconds if non-zero or if both minutes and seconds are zero
    if [ "$milliseconds" -gt 0 ] || [ -z "$parts" ]; then
        if [ -z "$parts" ]; then
            if [ "$milliseconds" -eq 1 ]; then
                parts="1ms"
            else
                parts="${milliseconds}ms"
            fi
        else
            if [ "$milliseconds" -eq 1 ]; then
                parts="$parts and 1ms"
            else
                parts="$parts and ${milliseconds}ms"
            fi
        fi
    fi

    # Ensure at least milliseconds are shown
    if [ -z "$parts" ]; then
        parts="0ms"
    fi

    echo "$parts"
}

# function to log job duration
log_duration() {
    local job_name="$1"
    local start_time="$2"
    local end_time="$3"

    # Calculate duration in milliseconds
    local duration_ms=$(( end_time - start_time ))

    # Handle negative duration (clock adjustment)
    if [ "$duration_ms" -lt 0 ]; then
        duration_ms=$(( -duration_ms ))
    fi

    # Format duration
    local formatted_time
    formatted_time=$(format_duration "$duration_ms")

    # Log the result
    log_message SUCCESS "Task [$job_name] took $formatted_time"
}

# function to query domain status in hosts file
query_domain() {
    local domain="$1"

    if [ -z "$domain" ]; then
        echo "[!] No domain provided."
        echo "[i] Usage: rmlwk --query-domain <domain> or rmlwk -q <domain>"
        echo "[i] Example: rmlwk --query-domain example.com"
        exit 1
    fi

    # Validate domain format
    printf '%s' "$domain" | grep -qiE '^[a-z0-9]([a-z0-9-]*\.)*[a-z0-9-]*[a-z0-9]$|^[a-z0-9]$' || abort "Invalid domain format: $domain"

    log_message "Querying domain: $domain"
    # Search in hosts file for the domain
    # This will find lines like "0.0.0.0 example.com" or "127.0.0.1 example.com"
    entry=$(grep -E "^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[0-9a-fA-F:]+)[[:space:]]+${domain}([[:space:]]|$)" "$hosts_file" 2>/dev/null | head -1)

    if [ -z "$entry" ]; then
        echo "[i] Domain '$domain' is NOT blocked"
        log_message "Domain query result: $domain is NOT blocked"
        return 0
    fi

    # Extract the IP address from the entry
    ip=$(echo "$entry" | awk '{print $1}')

    # Check if it's a blocking IP
    case "$ip" in
        0.0.0.0)
            echo "[!] Domain '$domain' IS BLOCKED"
            echo "[i] IP: $ip"
            log_message "Domain query result: $domain IS BLOCKED with IP $ip"
            return 0
        ;;
        *)
            # If it's a different IP, it's redirected
            echo "[⟳] Domain '$domain' IS REDIRECTED"
            echo "[i] Redirected to IP: $ip"
            log_message "Domain query result: $domain IS REDIRECTED to IP $ip"
            return 0
        ;;
    esac
}

# function to export logs
export_logs() {
    log_message "Exporting logs..."
    VERSION=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2)
    LOG_DATE="$(date +%Y-%m-%d__%H%M%S)"
    if echo "$VERSION" | grep -q "\-test.*(.*@.*)"; then
        base_version=$(echo "$VERSION" | sed 's/-test.*//')
        build_id=$(echo "$VERSION" | sed 's/.*(\(.*\)).*/\1/' | sed 's/\//_/g')
        tarFileName="Re-Malwack_${base_version}-${build_id}_logs_${LOG_DATE}.tgz"
    else
        clean_version=$(echo "$VERSION" | sed 's/\//_/g')
        tarFileName="Re-Malwack_${clean_version}_logs_${LOG_DATE}.tgz"
    fi
    log_message SUCCESS "Logs are going to be saved in: /sdcard/Download/$tarFileName"
    tar -czf "/sdcard/Download/$tarFileName" -C "$persist_dir" logs
    echo "Log saved to: /sdcard/Download/$tarFileName"
}

# Functions to process hosts

# 1. Helper to stage cached blocklist files into tmp
stage_blocklist_files() {
    local block_type="$1"
    local i=1
    for file in "$persist_dir/cache/$block_type/hosts"*; do
        [ -f "$file" ] || continue
        cp -f "$file" "${tmp_hosts}${i}"
        i=$((i+1))
    done
}

# 2. Install hosts
install_hosts() {
    type="$1"
    local start_time
    start_time=$(get_current_time)
    log_message "Fetching module's repo whitelist files"
    # Update hosts for global whitelist
    mkdir -p "$persist_dir/cache/whitelist"
    fetch "$persist_dir/cache/whitelist/whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt
    fetch "$persist_dir/cache/whitelist/social_whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt
    log_message "Starting to install $type hosts."
    # Prepare original hosts
    cp -f $system_hosts "${tmp_hosts}0"
    # Process blacklist and merge into previous hosts
    log_message "Preparing Blacklist..."
    [ -s "$persist_dir/blacklist.txt" ] && awk 'NF && $1 !~ /^#/ { print "0.0.0.0", $1 }' "$persist_dir/blacklist.txt" >> "${tmp_hosts}0"

    # Process whitelist
    log_message "Processing Whitelist..."
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"

    if [ "$block_social" -eq 0 ] && [ "$type" != "social" ]; then
        whitelist_file="$whitelist_file $persist_dir/cache/whitelist/social_whitelist.txt"
    else
        log_message WARN "Social Block triggered, Social whitelist won't be applied"
    fi

    # Append user-defined whitelist if it exists
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    # Merge whitelist files into one
    cat $whitelist_file | sed '/#/d; /^$/d' | awk '{print "0.0.0.0", $0}' > "${tmp_hosts}w"

    # If whitelist is empty, log and skip filtering
    if [ ! -s "${tmp_hosts}w" ]; then
        log_message WARN "Whitelist is empty. Skipping whitelist filtering."
        echo "" > "${tmp_hosts}w"
    fi

    # In case of hosts update (since only combined file exists only on --update-hosts)
    if [ -f "$combined_file" ]; then
        log_message "Detected unified hosts, sorting..."
        cat "${tmp_hosts}0" >> "$combined_file"
        awk '!seen[$0]++' "$combined_file" > "${tmp_hosts}merged.sorted"
    else # In case of install_hosts() being called in block_content() or block_trackers()
        log_message "detected multiple hosts file, merging and sorting... (Blocklist toggles only)"
        LC_ALL=C sort -u "${tmp_hosts}"[1-9] "${tmp_hosts}0" > "${tmp_hosts}merged.sorted"
    fi

    log_message "Filtering hosts"
    grep -Fvxf "${tmp_hosts}w" "${tmp_hosts}merged.sorted" > "$hosts_file" || {
        log_message WARN "Failed to filter with grep, trying awk fallback"
        # Fallback to awk if grep fails
        awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmp_hosts}w" "${tmp_hosts}merged.sorted" > "$hosts_file"
    }
    apply_custom_rules

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully installed $type hosts."
    local end_time
    end_time=$(get_current_time)
    log_duration "Installing hosts (Type: $type)" "$start_time" "$end_time"
}

# 3. Remove hosts
remove_hosts() {
    local start_time
    start_time=$(get_current_time)
    log_message "Starting to remove hosts."
    # Prepare original hosts
    cp -f "$hosts_file" "${tmp_hosts}0"

    # Processing & sorting files
    cat "$cache_hosts"* | sort -u > "${tmp_hosts}1"

    # Remove from hosts file
    awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmp_hosts}1" "${tmp_hosts}0" > "$hosts_file"

    # Restore to default entries if hosts file is empty
    if [ ! -s "$hosts_file" ]; then
        echo "[!] Hosts file is empty. Restoring default entries."
        log_message WARN "Detected empty hosts file, restoring default entries..."
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
    fi

    # Clean up
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully removed hosts."
    local end_time
    end_time=$(get_current_time)
    log_duration "Removing hosts" "$start_time" "$end_time"
}

# function to block conte- bruhhh doesn't that seem to be clear to you already? -_-
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

            # Process downloaded hosts
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done

            # Stage cache to tmp then install
            stage_blocklist_files "$block_type"
            install_hosts "$block_type"
        fi
        remove_hosts
        setConfigProperty "block_${block_type}" "0"
        log_message SUCCESS "Disabled $block_type blocklist."
    else
        # Download and process if no cache exists
        if [ ! -f "${cache_hosts}1" ]; then
            check_internet
            echo "[*] Downloading hosts for $block_type block."
            fetch_blocklist "$block_type"

            for file in "$persist_dir/cache/$block_type/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
        fi

        stage_blocklist_files "$block_type"
        install_hosts "$block_type"
        setConfigProperty "block_${block_type}" "1"

        # Count entries from cache and persist
        bl_count=0
        for file in "$persist_dir/cache/$block_type/hosts"*; do
            if [ -f "$file" ]; then
                file_count=$(wc -l < "$file")
                bl_count=$((bl_count + file_count))
            fi
        done
        log_message SUCCESS "Enabled $block_type blocklist ($bl_count entries)."
        sed -i "/^${block_type}|/d" "$persist_dir/counts/blocklists.counts" 2>/dev/null || true
        echo "${block_type}|${bl_count}" >> "$persist_dir/counts/blocklists.counts"
    fi
}

# function to remount hosts
remount_hosts() {
    if [ "$is_zn_detected" -eq 1 ]; then
        log_message "zn-hostsredirect detected, skipping mount operation"
        return 0
    fi
    log_message "Attempting to remount hosts..."
    log_message "system hosts file lines count: $system_hosts_lines, module hosts file lines count: $module_hosts_lines"
    echo "[*] Attempting to remount hosts..."
    umount -l "$system_hosts" 2>/dev/null || log_message WARN "Failed to unmount $system_hosts"
    if ! mount --bind "$hosts_file" "$system_hosts"; then
        log_message ERROR "Failed to bind mount $hosts_file to $system_hosts"
        return 1
    fi
    log_message SUCCESS "Hosts remounted successfully."
    echo "[✓] Hosts remounted successfully."
}

# function to block trackers
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
        setConfigProperty "block_trackers" "0"
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
            host_process "${cache_hosts}1"
            host_process "${cache_hosts}2"
            # note to self
            # If we add a third general source for trackers
            # move cache_hosts3 to the general trackers blocklist fetching section
            # and change 3 to 4 below
            [ -f "${cache_hosts}3" ] && host_process "${cache_hosts}3"
        fi
        log_message "Enabling trackers block"
        echo "[*] Enabling trackers block for $brand"
        stage_blocklist_files "trackers"
        install_hosts "trackers"
        setConfigProperty "block_trackers" "1"
        
        # Count trackers entries
        tr_count=0
        for file in "$persist_dir/cache/trackers/hosts"*; do
            if [ -f "$file" ]; then
                file_count=$(wc -l < "$file")
                tr_count=$((tr_count + file_count))
            fi
        done
        log_message SUCCESS "Trackers blocklist enabled ($tr_count entries)."
        sed -i "/^trackers|/d" "$persist_dir/counts/blocklists.counts" 2>/dev/null || true
        echo "trackers|${tr_count}" >> "$persist_dir/counts/blocklists.counts"
        local end_time
        end_time=$(get_current_time)
        log_duration "Enabling trackers block" "$start_time" "$end_time"
        echo "[✓] Trackers block has been enabled"
    fi
}

fetch_blocklist() {
    bl="$1"
    cache_hosts="$persist_dir/cache/$bl/hosts"

    case "$bl" in
        porn)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"
            fetch "${cache_hosts}2" "https://raw.githubusercontent.com/4skinSkywalker/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt"
            ;;
        gambling)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-only/hosts"
            fetch "${cache_hosts}2" "https://blocklistproject.github.io/Lists/gambling.txt"
            ;;
        fakenews|social)
            fetch "${cache_hosts}1" \
                "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${bl}-only/hosts"
            ;;
        trackers)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardTracking.txt"
            fetch "${cache_hosts}2" "https://blocklistproject.github.io/Lists/tracking.txt"

            # Device-specific tracker hosts
            brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
            case "$brand" in
                xiaomi|redmi|poco) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt" ;;
                samsung)           url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt" ;;
                oppo|realme)       url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt" ;;
                vivo)              url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt" ;;
                huawei)            url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt" ;;
                *) url="" ;;
            esac
            [ -n "$url" ] && fetch "${cache_hosts}3" "$url"
            ;;
        safebrowsing)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/Re-Malwack/hosts/refs/heads/main/safebrowsing.txt"
            ;;
    esac
    wait
}

# shortcase
tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# uhhhhh
abort() {
    log_message "Aborting: $1"
    echo "[✗] $1"
    sleep 0.5
    exit 1
}

# Bruh It's clear already what this function does ._.
check_internet() {
    retry_count=0
    max_retries=6
    while ! ping -c 1 8.8.8.8 &>/dev/null; do
        retry_count=$((retry_count + 1))
        [ "$retry_count" -ge "$max_retries" ] && abort "No internet connection detected after $max_retries attempts, aborting..."
        log_message WARN "No internet connection detected, retrying... (Attempt $retry_count/$max_retries)"
        echo "[i] No internet connection detected, attempting to reconnect... (Attempt $retry_count/$max_retries)"
        sleep 1.5
    done
}

# Fetches hosts from sources.txt
# tmp_hosts 0 = This is the original hosts file, to prevent overwriting before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = This is the downloaded hosts, to simplify process of install and remove function.
fetch() {
    local start_time
    start_time=$(get_current_time)
    local output_file="$1"
    local url="$2"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    # Curly hairyyy- *ahem*
    # So uhh, we check for curl existence, if it exists then we gotta use it to fetch hosts
    if command -v curl >/dev/null 2>&1; then
        dl_tool=curl
        if ! curl -LfsS "$url" > "$output_file"; then
            log_message ERROR "Failed to download from $url with curl"
            echo "[!] Failed to download from $url"
            echo "" > "$output_file"
            return 1
        fi
    else # Else we gotta just fallback to windows ge- my bad I mean winget- BRUH it's wget :sob:
        dl_tool=wget
        if ! busybox wget --no-check-certificate -qO - "$url" > "$output_file"; then
            log_message ERROR "Failed to download from $url with wget"
            echo "[!] Failed to download from $url"
            echo "" > "$output_file"
            return 1
        fi
    fi
    log_message SUCCESS "Downloaded from $url using $dl_tool, stored in $output_file"
    local end_time
    end_time=$(get_current_time)
    log_duration "Fetching process" "$start_time" "$end_time"
}

# Updates module status, modifying module description in module.prop
update_status() {
    local start_time
    start_time=$(get_current_time)
    status_msg=""  # Reset status message
    . "$persist_dir/config.sh" # Sourcing config file
    log_message SUCCESS "loaded config file!"
    log_message "Selected profile: $profile"
    log_message INFO "Updating module status"
    log_message "Fetching last hosts file update"
    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file
    log_message "Last hosts file update was in: $last_mod"

    # System hosts count
    [ ! -d "/data/adb/modules/Re-Malwack" ] && log_message "First install detected (module directory missing)."

    # Module hosts count
    blocked_sys=$(cat "$persist_dir/counts/blocked_sys.count" 2>/dev/null)
    blocked_mod=$(cat "$persist_dir/counts/blocked_mod.count" 2>/dev/null)
    
    # Custom rules count
    [ -s "$persist_dir/custom_rules.txt" ] && custom_entries=$(grep -c '^[^#[:space:]]' "$persist_dir/custom_rules.txt" ) || custom_entries=0

    # Count blacklisted entries (excluding comments and empty lines)
    [ -s "$persist_dir/blacklist.txt" ] && blacklist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/blacklist.txt") || blacklist_count=0

    # Count whitelisted entries (excluding comments and empty lines)
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/whitelist.txt") || whitelist_count=0
    log_message "Blacklist entries count: $blacklist_count"
    log_message "Whitelist entries count: $whitelist_count"
    log_message "Custom rules count: $custom_entries"

    # Determine mode based on zn-hostsredirect detection
    mode="hosts mount mode: zn-hostsredirect"
    [ "$is_zn_detected" -ne 1 ] && mode="hosts mount mode: Standard mount"

    # Log enabled blocklists
    enabled_blocklists=""
    for bl in porn gambling fakenews social trackers safebrowsing; do
        eval enabled=\$block_${bl}
        if [ "$enabled" = "1" ]; then
            if [ -z "$enabled_blocklists" ]; then
                enabled_blocklists="$bl"
            else
                enabled_blocklists="$enabled_blocklists, $bl"
            fi
        fi
    done
    [ -n "$enabled_blocklists" ] && log_message INFO "Enabled blocklists:$enabled_blocklists" || \
        log_message INFO "No blocklists enabled"

    # Here goes the part where we actually determine module status
    if [ -f "$persist_dir/mode_ready" ] && [ "$blocked_mod" -gt 0 ]; then
        # Clear mode_ready flag if hosts file has blocked entries
        rm -f "$persist_dir/mode_ready"
        log_message "Cleared mode_ready flag, hosts file has $blocked_mod blocked entries"
    fi

    [ -z "$profile" ] && profile="default"
    capitalized_profile="$(echo "$profile" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
    [ "$dns_logging" = "1" ] && dns_status=" | 🔍 DNS Logging: ON" || dns_status=""

    if [ -f "$persist_dir/reboot_required" ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (DNS Logging) | ⚙️ Profile: $capitalized_profile${dns_status}"
	elif [ -f "$persist_dir/mode_ready" ]; then
        status_msg="Status: Protection is idle 💤 | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif is_protection_paused; then
        status_msg="Status: Protection is paused ⏸️ | ⚙️ Profile: $capitalized_profile${dns_status}"
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
        system_hosts_lines=$(cat "$system_hosts" 2>/dev/null | wc -l)
        module_hosts_lines=$(cat "$hosts_file" 2>/dev/null | wc -l)
        if [ "$module_hosts_lines" -ne "$system_hosts_lines" ] && [ "$is_zn_detected" -ne 1 ]; then
            # Attempt to remount hosts and refresh status
            # Only in case of broken mount detection
            remount_hosts
            refresh_blocked_counts
            system_hosts_lines=$(cat "$system_hosts" 2>/dev/null | wc -l)
            module_hosts_lines=$(cat "$hosts_file" 2>/dev/null | wc -l)
            if [ "$module_hosts_lines" -ne "$system_hosts_lines" ]; then
                status_msg="Status: ❌ Critical Error Detected (Hosts Mount Failure). Please check your root manager settings and disable any conflicted module(s)."
                echo "[!!!] Critical Error Detected (Hosts Mount Failure). Please check your root manager settings and disable any conflicted module(s)."
                echo "[!!!] Module hosts blocks $blocked_mod domains, System hosts blocks $blocked_sys domains."
            fi
        fi
        # Set success message if not set to error
        if [ -z "$status_msg" ]; then
            if [ "$(date +%m%d)" = "0401" ]; then
                blocking_info="Allowing $blocked_mod ads"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Allowing $((blocked_mod - blacklist_count)) ads + $blacklist_count (blacklist)"
                status_msg="Status: Protection is Vulnerable ✅ | ⚙️ Profile: $capitalized_profile${dns_status} | $blocking_info"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Allowlists:$enabled_blocklists"
                setConfigProperty "name" "Re-Malware | Not just a normal malware module ✨" "$MODDIR/module.prop"
                setConfigProperty "banner" "banner=banner_alt.png" "$MODDIR/module.prop"
            else
                blocking_info="Blocking $blocked_mod domains"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Blocking $((blocked_mod - blacklist_count)) domains + $blacklist_count (blacklist)"
                status_msg="Status: Protection is enabled ✅ | ⚙️ Profile: $capitalized_profile${dns_status} | $blocking_info"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Blocklists:$enabled_blocklists"
                setConfigProperty "name" "Re-Malwack | Not just a normal ad-blocker module ✨" "$MODDIR/module.prop"
                setConfigProperty "banner" "banner=banner.png" "$MODDIR/module.prop"
            fi
        fi
    fi

    # Update module description
    setConfigProperty "description" "$status_msg" "$MODDIR/module.prop"
    log_message "$status_msg"
    local end_time
    end_time=$(get_current_time)
    log_duration "Updating module status" "$start_time" "$end_time"
}

# Functions for auto-update (cron jobs)

# 1 - Detect cron provider
detect_cron_provider() {
    if command -v busybox >/dev/null 2>&1 && busybox crond --help >/dev/null 2>&1; then
        echo busybox
    elif command -v toybox >/dev/null 2>&1 && toybox crond --help >/dev/null 2>&1; then
        echo toybox
    else
        return 1
    fi
}

# 1.2 - Helper function for applets usage
cron_cmd() {
    case "$CRON_PROVIDER" in
        busybox) echo "busybox $1" ;;
        toybox)  echo "toybox $1" ;;
    esac
}

# 2 - Fallback auto update script
auto_update_fallback() {
    FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
    cat > "$FALLBACK_SCRIPT" << 'EOF'
#!/system/bin/sh
LOGFILE="/data/adb/Re-Malwack/logs/auto_update-fallback.log"
PID=$$
echo $PID > /data/adb/Re-Malwack/logs/auto_update.pid
echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Fallback auto update script started with PID $PID" >> "$LOGFILE" 2>&1
while true; do
    sleep 86400 # Sleep for 24 hours
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto-update check started"
        if sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts --quiet 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto update completed successfully"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Auto update failed"
        fi
    } >> "$LOGFILE" 2>&1
done
EOF
    # Make the fallback script executable and run it in the background
    chmod +x "$FALLBACK_SCRIPT"
    nohup "$FALLBACK_SCRIPT" >/dev/null 2>&1 &
    sleep 1

    # Verify if the fallback script is running
    if ! kill -0 "$(cat $persist_dir/logs/auto_update.pid 2>/dev/null)" 2>/dev/null; then
        echo "[!] Failed to start fallback auto update script, We're officially cooked twin 🥀"
        log_message ERROR "Fallback auto update script failed to stay alive"
        rm -f "$FALLBACK_SCRIPT"
        exit 1
    fi

}

# 3 - Enable auto update
enable_auto_update() {
    JOB_DIR="$persist_dir/auto_update"
    JOB_FILE="$JOB_DIR/root"
    CRON_JOB="0 */12 * * * ( sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts --quiet 2>&1 || echo \"Auto-update failed at \$(date)\" ) >> /data/adb/Re-Malwack/logs/auto_update-cron.log"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local start_time
    start_time=$(get_current_time)

    log_message "Enabling auto update has been initiated."
    [ "$daily_update" = "1" ] && abort "Auto update is already enabled"
    if CRON_PROVIDER=$(detect_cron_provider); then
        CROND=$(cron_cmd crond)
        CRONTAB=$(cron_cmd crontab)

        echo "[*] Enabling auto update via cron."
        log_message "Enabling auto update via cron, Using $CRON_PROVIDER as cron provider."

        mkdir -p "$JOB_DIR" "$persist_dir/logs"
        echo "$CRON_JOB" > "$JOB_FILE"
        $CRONTAB "$JOB_FILE" -c "$JOB_DIR"
        log_message SUCCESS "Cron job added, running crond..."
        $CROND -b -c "$JOB_DIR" -L "$persist_dir/logs/auto_update-cron.log"
        log_message SUCCESS "Started crond successfully."
        sleep 1.5 # Give crond some time to start and register the job
        CROND_PID="$(busybox pgrep -f "crond.*$JOB_DIR" | head -n 1 || true)"

        if [ -n "$CROND_PID" ]; then
            log_message SUCCESS "crond started! (PID:$CROND_PID)"
        else
            log_message WARN "crond process was not found, falling back to script loop method."
            echo "[!] Crond failed to run in the background, falling back to script loop method."
            rm -rf "$JOB_DIR"
            auto_update_fallback
            log_message SUCCESS "Fallback auto update script started."
        fi
    else
        echo "[i] No cron provider detected, falling back to script loop method."
        log_message WARN "No cron provider detected, falling back to script loop method."
        auto_update_fallback
        log_message SUCCESS "Fallback auto update script started."
    fi
    setConfigProperty "daily_update" "1" "/data/adb/Re-Malwack/config.sh"
    log_message SUCCESS "Auto update has been enabled."
    local end_time
    end_time=$(get_current_time)
    log_duration "Enabling auto update" "$start_time" "$end_time"
    echo "[✓] Auto update has been enabled."
}

# 4 - Disable auto update
disable_auto_update() {
    JOB_DIR="$persist_dir/auto_update"
    FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local start_time
    start_time=$(get_current_time)

    [ "$daily_update" = "0" ] && abort "Auto update is already disabled"
    log_message "Disabling auto update has been initiated."
    echo "[*] Disabling auto hosts update"
    if CRON_PROVIDER=$(detect_cron_provider); then
        KILL=$(cron_cmd kill)
        PIDOF=$(cron_cmd pidof)

        log_message "Killing cron processes, Using $CRON_PROVIDER applets."

        for pid in $($PIDOF crond 2>/dev/null); do
            $KILL -9 "$pid" >/dev/null 2>&1
        done

        rm -rf "$JOB_DIR"
        log_message "Cron job removed."
    else
        # Stop fallback loop if cron was never used
        log_message "Killing fallback auto update script."
        PID="$(cat "$persist_dir/logs/auto_update.pid" 2>/dev/null)"
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" >/dev/null 2>&1
            log_message SUCCESS "Fallback auto update script stopped (PID:$PID)"
        fi
        rm -f "$FALLBACK_SCRIPT"
        log_message "Fallback auto update script stopped and removed."
    fi

    setConfigProperty "daily_update" "0" "/data/adb/Re-Malwack/config.sh"
    local end_time
    end_time=$(get_current_time)
    log_message SUCCESS "Auto update has been disabled."
    log_duration "Disabling auto update" "$start_time" "$end_time"
    echo "[✓] Auto update has been disabled."
}

help_menu() {
    echo ""
    echo "[i] Usage: rmlwk [--argument] OPTIONAL: [--quiet]"
    echo "============= Hosts Management ============="
    echo "--adblock-switch, -as: Toggle protections on/off."
    echo "--profile, -p <default|lite|balanced|aggressive|custom>: Switch adblock level profile."
    echo "--update-hosts, -u: Update the hosts file."
    echo "--reset, -r: Reset hosts file to default."
    echo "--auto-update, -a <enable|disable>: Toggle auto hosts update."
    echo ""
    echo "============= Customization ============="
    echo "--query-domain, -q <domain>: Query if a domain is blocked, redirected, or not blocked."
    echo "--dns-logging, -dl <enable|disable>: Enable or disable DNS logging."
    echo "--custom-rule, -cr <add|remove> <IP> <domain>: Add or remove custom hosts rules."
    echo ""
    echo "============= Sources Management ============="
    echo "--whitelist, -w <add|remove> <domain|pattern> <domain2> ...: Whitelist domain(s), only whitelist one domain at a time, otherwise use wildcard or use multiple domains in case of unwhitelisting."
    echo "--blacklist, -b <add|remove> <domain1> <domain2> ...: Blacklist domain(s)."
    echo "--custom-source, -c <add|remove|enable|disable|edit> ...: Add/remove/enable/disable custom hosts sources."
    echo ""
    echo "============= Block Lists Categories ============="
    echo "--block-porn, -bp <disable>: Enable or disable porn domains blocking."
    echo "--block-gambling, -bg <disable>: Enable or disable gambling domains blocking."
    echo "--block-fakenews, -bf <disable>: Enable or disable fake news domains blocking."
    echo "--block-social, -bs <disable>: Enable or disable social media domains blocking."
    echo "--block-trackers, -bt <disable>: Enable or disable tracker domains blocking."
    echo "--block-safebrowsing, -bsb <disable>: Enable or disable Google Safe Browsing domains blocking."
    echo ""
    echo "============= Information ============="
    echo "--export-logs, -e: Export logs to a tarball in Download directory."
    echo "--help, -h: Display help."
    echo ""
    echo -e "\033[0;31m Example command: su -c rmlwk --update-hosts\033[0m"
    exit 1
}
