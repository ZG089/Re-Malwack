[ "${RMLWK_LIB_FETCH:-0}" -eq 1 ] && return 0
RMLWK_LIB_FETCH=1

check_internet() {
    retry_count=0
    max_retries=6
    while ! ping -c 1 8.8.8.8 >/dev/null 2>&1; do
        retry_count=$((retry_count + 1))
        if [ "$retry_count" -ge "$max_retries" ]; then
            abort "No internet connection detected after $max_retries attempts, aborting..."
        fi
        log_message WARN "No internet connection detected, retrying... (Attempt $retry_count/$max_retries)"
        echo "[i] No internet connection detected, attempting to reconnect... (Attempt $retry_count/$max_retries)"
        sleep 1.5
    done
}

fetch() {
    local start_time
    start_time=$(get_current_time)
    local output_file="$1"
    local url="$2"

    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    ensure_file "$output_file"

    if command -v curl >/dev/null 2>&1; then
        dl_tool=curl
        if ! curl -Ls "$url" > "$output_file"; then
            log_message ERROR "Failed to download from $url with curl"
            echo "[!] Failed to download from $url"
            : > "$output_file"
            return 1
        fi
    else
        dl_tool=wget
        if ! busybox wget --no-check-certificate -qO - "$url" > "$output_file"; then
            log_message ERROR "Failed to download from $url with wget"
            echo "[!] Failed to download from $url"
            : > "$output_file"
            return 1
        fi
    fi

    log_message SUCCESS "Downloaded from $url using $dl_tool, stored in $output_file"
    local end_time
    end_time=$(get_current_time)
    log_duration "Fetching process" "$start_time" "$end_time"
}

fetch_blocklist() {
    bl="$1"
    cache_hosts="$persist_dir/cache/$bl/hosts"

    case "$bl" in
        porn)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts" &
            fetch "${cache_hosts}2" "https://blocklistproject.github.io/Lists/porn.txt" &
            fetch "${cache_hosts}3" "https://raw.githubusercontent.com/4skinSkywalker/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt" &
            ;;
        gambling)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-only/hosts" &
            fetch "${cache_hosts}2" "https://blocklistproject.github.io/Lists/gambling.txt" &
            ;;
        fakenews|social)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${bl}-only/hosts"
            ;;
        trackers)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardTracking.txt" &
            fetch "${cache_hosts}2" "https://blocklistproject.github.io/Lists/tracking.txt" &
            brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
            case "$brand" in
                xiaomi|redmi|poco) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt" ;;
                samsung)           url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt" ;;
                oppo|realme)       url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt" ;;
                vivo)              url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt" ;;
                huawei)            url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt" ;;
                *) url="" ;;
            esac
            [ -n "$url" ] && fetch "${cache_hosts}3" "$url" &
            ;;
        safebrowsing)
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing"
            ;;
    esac
    wait
}
