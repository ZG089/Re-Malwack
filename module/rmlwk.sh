#!/system/bin/sh

# Welcome to the main script of the module :)
# Side notes: Literally everything in this module relies on this script you're checking right now.
# customize.sh (installer script), action script and even WebUI!
# Now enjoy reading the code
# - ZG089, Founder of Re-Malwack.


# ====== Variables ======
quiet_mode=0
persist_dir="/data/adb/Re-Malwack"
REALPATH=$(readlink -f "$0")
MODDIR=$(dirname "$REALPATH")
hosts_file="$MODDIR/system/etc/hosts"
system_hosts="/system/etc/hosts"
tmp_hosts="/data/local/tmp/hosts"
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"

# ====== Pre-func ======
. "$persist_dir/config.sh"
mkdir -p "$persist_dir/logs"

# ====== Functions ======
function rmlwk_banner() {
    
    [ "$quiet_mode" -eq 1 ] && return

    clear

    if command -v shuf >/dev/null 2>&1; then
        random_index=$(shuf -i 1-2 -n 1)
    else
        random_index=$(( ($(date +%s) % 2) + 1 ))
    fi

    case "$random_index" in
        1)
            printf '\033[0;31m'
            printf "    ____             __  ___      __                    __            \n"
            printf "   / __ \\___        /  |/  /___ _/ /      ______ ______/ /__          \n"
            printf "  / /_/ / _ \\______/ /|_/ / __ \`/ / | /| / / __ \`/ ___/ //_/       \n"
            printf " / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<              \n"
            printf "/_/ |_|\\___/     /_/  /_/\\__,_/_/ |__/|__/\\__,_/\\___/_/|_|      \n"
            ;;
        2)
            printf '\033[0;31m'
            printf "██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗\n"
            printf "██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝\n"
            printf "██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ \n"
            printf "██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ \n"
            printf "██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗\n"
            printf "╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝\n"
            ;;
    esac

    printf '\033[0m'
    update_status
    echo ""
    echo "$version - $status_msg"
    printf '\033[0;31m'
    echo "================================================================="
    printf '\033[0m'
}

# Function to check hosts file reset state
function is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ]
}

# Function to process hosts, maybe?
function host_process() {
    local file="$1"
    # Exclude whitelist files
    echo "$file" | tr '[:upper:]' '[:lower:]' | grep -q "whitelist" && return 0
    # Unified filtration: remove comments, empty lines, trim whitespaces, handles windows-formatted hosts 
    log_message "Filtering $file..."
    sed -i '/^[[:space:]]*#/d; s/[[:space:]]*#.*$//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//' "$file"
}

# Function to count blocked entries and store them
function refresh_blocked_counts() {
    mkdir -p "$persist_dir/counts"

    blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
    echo "${blocked_mod:-0}" > "$persist_dir/counts/blocked_mod.count"

    blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
    echo "${blocked_sys:-0}" > "$persist_dir/counts/blocked_sys.count"
}

# Functions for protection switch

# function to check adblock pause
function is_protection_paused() {
    [ -f "$persist_dir/hosts.bak" ] || [ "$adblock_switch" -eq 1 ]
}

# 1 - Pause adblock
function pause_protections() {
    # Check if protection is already paused
    if is_protection_paused; then
        resume_protections
        exit 0
    fi
    # Check if hosts file is reset
    if is_default_hosts; then
        echo "[i] You cannot pause protections while hosts is reset"
        exit
    fi
    log_message "Pausing Protections"
    echo "[*] Pausing Protections"
    cp "$hosts_file" "$persist_dir/hosts.bak"
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
    sed -i 's/^adblock_switch=.*/adblock_switch=1/' "/data/adb/Re-Malwack/config.sh"
    refresh_blocked_counts
    update_status
    log_message SUCCESS "Protection has been paused."
    echo "[✓] Protection has been paused."
}

# 2 - Resume adblock
function resume_protections() {
    log_message "Resuming protection."
    echo "[*] Resuming protection"
    if [ -f "$persist_dir/hosts.bak" ]; then
        cat "$persist_dir/hosts.bak" > "$hosts_file"
        rm -f $persist_dir/hosts.bak
        sed -i 's/^adblock_switch=.*/adblock_switch=0/' "/data/adb/Re-Malwack/config.sh"
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Protection has been resumed."
        echo "[✓] Protection has been resumed."
    else
        log_message WARN "No backup hosts file found to resume"
        log_message "Force resuming protection and running hosts update as a fallback action"
        echo "[!] No backup hosts file found to resume."
        sleep 0.5
        echo "[i] Force resuming protection and running hosts update as a fallback action"
        sleep 3
        sed -i 's/^adblock_switch=.*/adblock_switch=0/' "/data/adb/Re-Malwack/config.sh"
        exec "$0" --update-hosts
    fi
}

# Logging func - Literally helpful for any dev :D
function log_message() {

    timestamp() {
        date +"%m-%d-%Y %I:%M:%S %p"
    }

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
    line="[$(timestamp)] - [$level] - $msg"
    echo "$line" >> "$LOGFILE"
}

# Helper to log duration
function duration_to_hms() {
    T=$1
    printf "%02d:%02d:%02d" $((T/3600)) $((T%3600/60)) $((T%60))
}

# I think this is for logging duration? Who knows ¯\\(ツ)/¯
function log_duration() {
    name="$1"
    start_time="$2"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    log_message "$name took $(duration_to_hms $duration) (hh:mm:ss)"
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
function install_hosts() {
    start_time=$(date +%s)
    type="$1"
    log_message "Fetching module's repo whitelist files"
    # Update hosts for global whitelist
    mkdir -p "$persist_dir/cache/whitelist"
    fetch "$persist_dir/cache/whitelist/whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt
    fetch "$persist_dir/cache/whitelist/social_whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt
    log_message "Starting to install $type hosts."
    # Prepare original hosts
    cp -f "$hosts_file" "${tmp_hosts}0"
    # Process blacklist and merge into previous hosts
    log_message "Preparing Blacklist..."
    [ -s "$persist_dir/blacklist.txt" ] && awk 'NF && $1 !~ /^#/ { print "0.0.0.0", $1 }' "$persist_dir/blacklist.txt" >> "${tmp_hosts}0"

    # Process whitelist
    log_message "Processing Whitelist..."
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"

    if [ "$block_social" -eq 0 ]; then
        whitelist_file="$whitelist_file $persist_dir/cache/whitelist/social_whitelist.txt"
    else
        log_message WARN "Social Block triggered, Social whitelist won't be applied"
    fi

    # Append user-defined whitelist if it exists
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    # Debugging - Check each whitelist file individually
    for file in $whitelist_file; do
        if [ ! -f "$file" ]; then
            log_message WARN "Whitelist file $file does not exist!"
        elif [ ! -s "$file" ]; then
            log_message WARN "Whitelist file $file is empty!"
        else
            log_message "Whitelist file $file found with content."
        fi
    done

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
        LC_ALL=C sort -u "${tmp_hosts}"[!0] "${tmp_hosts}0" > "${tmp_hosts}merged.sorted"
    fi

    log_message "Filtering hosts"
    grep -Fvxf "${tmp_hosts}w" "${tmp_hosts}merged.sorted" > "$hosts_file"

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully installed $type hosts."
    log_duration "install_hosts ($type)" "$start_time"
}

# 3. Remove hosts
function remove_hosts() {
    start_time=$(date +%s)
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
        log_message WARN "Detected empty hosts file"
        log_message "Restoring default entries..."
        echo -e "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
    fi

    # Clean up
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully removed hosts."
    log_duration "remove_hosts" "$start_time"
}

# Function to block conte- bruhhh doesn't that seem to be clear to you already? -_-
function block_content() {
    start_time=$(date +%s)
    block_type=$1
    status=$2
    cache_hosts="$persist_dir/cache/$block_type/hosts"
    mkdir -p "$persist_dir/cache/$block_type"

    if [ "$status" = 0 ]; then
        if [ ! -f "${cache_hosts}1" ]; then
            log_message WARN "No cached $block_type blocklist found, redownloading to disable properly."
            echo "[!] No cached $block_type blocklist found, redownloading to disable properly"
            nuke_if_we_dont_have_internet
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts"
            [ "$block_type" = "porn" ] && {
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts &
                fetch "${cache_hosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing &
                wait
            }
            # Stage cache to tmp then install
            stage_blocklist_files "$block_type"
            install_hosts "$block_type"
        fi
        remove_hosts
        sed -i "s/^block_${block_type}=.*/block_${block_type}=0/" "$persist_dir/config.sh"
        log_message SUCCESS "Disabled $block_type blocklist."
    else
        if [ ! -f "${cache_hosts}1" ] || [ "$status" = "update" ]; then
            nuke_if_we_dont_have_internet
            echo "[*] Downloading hosts for $block_type block."
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts"
            [ "$block_type" = "porn" ] && {
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts &
                fetch "${cache_hosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing &
                wait
            }
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                [ -f "$file" ] && host_process "$file"
            done
        fi

        if [ "$status" != "update" ]; then
            stage_blocklist_files "$block_type"
            install_hosts "$block_type"
            sed -i "s/^block_${block_type}=.*/block_${block_type}=1/" "$persist_dir/config.sh"
            log_message SUCCESS "Enabled $block_type blocklist."
        fi
    fi
    log_duration "block_content ($block_type, $status)" "$start_time"
}
# Function to block trackers
function block_trackers() {
    start_time=$(date +%s)
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
            nuke_if_we_dont_have_internet
            log_message WARN "No cached trackers file — redownloading before removal."
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardTracking.txt"
            case "$brand" in
                xiaomi|redmi|poco) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt" ;;
                samsung) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt" ;;
                oppo|realme) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt" ;;
                vivo) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt" ;;
                huawei) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt" ;;
                *) url="" ;;
            esac
            host_process "${cache_hosts}1"
            [ -n "$url" ] && fetch "${cache_hosts}2" "$url" && host_process "${cache_hosts}2"
            stage_blocklist_files "trackers"
            install_hosts "trackers"
        fi

        remove_hosts
        sed -i "s/^block_trackers=.*/block_trackers=0/" "$persist_dir/config.sh"
        log_message SUCCESS "Trackers blocklist disabled."
    else
        if [ "$block_trackers" = 1 ]; then
            echo "[!] Trackers block is already enabled"
            return 0
        fi

        if ! ls "${cache_hosts}"* >/dev/null 2>&1; then
            nuke_if_we_dont_have_internet
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardTracking.txt"
            case "$brand" in
                xiaomi|redmi|poco) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt" ;;
                samsung) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt" ;;
                oppo|realme) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt" ;;
                vivo) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt" ;;
                huawei) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt" ;;
                *) url="" ;;
            esac
            host_process "${cache_hosts}1"
            [ -n "$url" ] && fetch "${cache_hosts}2" "$url" && host_process "${cache_hosts}2"
        fi

        stage_blocklist_files "trackers"
        install_hosts "trackers"
        sed -i "s/^block_trackers=.*/block_trackers=1/" "$persist_dir/config.sh"
        log_message SUCCESS "Trackers blocklist enabled."
    fi

    log_duration "block_trackers ($status)" "$start_time"
}

# shortcase
function tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# uhhhhh
function abort() {
    log_message "Aborting: $1"
    echo "[!] $1"
    sleep 0.5
    exit 1
}

# Bruh It's clear already what this function does ._.
function nuke_if_we_dont_have_internet() {
    ping -c 1 -w 5 8.8.8.8 &>/dev/null || abort "No internet connection detected, Please connect to a network then try again."
}

# Fetches hosts from sources.txt
# Don't be concerned from these filenames when checking cached files during hosts downloading/processing
# tmp_hosts 0 = This is the original hosts file, to prevent overwriting before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = This is the downloaded hosts, to simplify process of install and remove function.
function fetch() {
    start_time=$(date +%s)
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local output_file="$1"
    local url="$2"

    # Curly hairyyy- *ahem*
    # So uhh, we check for curl existence, if it exists then we gotta use it to fetch hosts
    if command -v curl >/dev/null 2>&1; then
        dl_tool=curl
        curl -Ls "$url" > "$output_file" || {
            log_message ERROR "Failed to download from $url with curl"
            echo "[!] Failed to download from $url"
        }
        echo "" >> "$output_file"
    else # Else we gotta just fallback to windows ge- my bad I mean winget- BRUH it's wget :sob:
        dl_tool=wget
        busybox wget --no-check-certificate -qO - "$url" > "$output_file" || {
            log_message ERROR "Failed to download from $url with wget"
            echo "[!] Failed to download from $url"
        }
        echo "" >> "$output_file"
    fi
    log_message SUCCESS "Downloaded from $url using $dl_tool, stored in $output_file"
    log_duration "fetch file from url: $url" "$start_time"
}

# Updates module status, modifying module description in module.prop
function update_status() {
    start_time=$(date +%s)
    log_message "Fetching last hosts file update"
    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file
    log_message "Last hosts file update was in: $last_mod"

    # System hosts count
    [ ! -d "/data/adb/modules/Re-Malwack" ] && log_message "First install detected (module directory missing)."

    # Module hosts count
    blocked_sys=$(cat "$persist_dir/counts/blocked_sys.count" 2>/dev/null)
    blocked_mod=$(cat "$persist_dir/counts/blocked_mod.count" 2>/dev/null)
    
    # Count blacklisted entries (excluding comments and empty lines)
    blacklist_count=0
    [ -s "$persist_dir/blacklist.txt" ] && blacklist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/blacklist.txt")

    # Count whitelisted entries (excluding comments and empty lines)
    whitelist_count=0
    [ -f "$persist_dir/whitelist.txt" ] && whitelist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/whitelist.txt")

    log_message "Blacklist entries count: $blacklist_count"
    log_message "Whitelist entries count: $whitelist_count"
    log_message "System hosts entries count: $blocked_sys"
    log_message "Module hosts entries count: $blocked_mod"

    # Here goes the part where we actually determine module status
    if is_protection_paused; then
        status_msg="Status: Protection is paused ⏸️"
    elif [ -d /data/adb/modules_update/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (pending module update)"
    elif [ -d /data/adb/modules_update/Re-Malwack ] && [ ! -d /data/adb/modules/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (First time install)"
    elif [ "$blocked_mod" -gt 10 ]; then
        if [ "$blocked_mod" -ne "$blocked_sys" ]; then # Only for cases when mount breaks between module hosts and system hosts
            status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
        else
            status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains"
            status_msg="$status_msg | Blocklist: $((blocked_mod - blacklist_count))"
            [ "$blacklist_count" -gt 0 ] && status_msg="Status: Protection is enabled ✅ | Blocking $((blocked_mod - blacklist_count)) domains + $blacklist_count (blacklist)"
            [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
            status_msg="$status_msg | Last updated: $last_mod"
        fi
    elif is_default_hosts; then
        status_msg="Status: Protection is disabled due to reset ❌"
    fi

    # Update module description
    sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
    log_message "$status_msg"
    log_duration "update_status" "$start_time"
}

# Functions for auto-update (cron jobs)

# 1 - Enable cron job
function enable_cron() {
    JOB_DIR="/data/adb/Re-Malwack/auto_update"
    JOB_FILE="$JOB_DIR/root"
    CRON_JOB="0 */12 * * * sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts && echo '[AUTO UPDATE TIME!!!]' >> /data/adb/Re-Malwack/logs/auto_update.log"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

    if [ -d "$JOB_DIR" ]; then
        echo "[i] Auto update is already enabled"
    else
        # Create directory and file if they don't exist
        mkdir -p "$JOB_DIR"
        touch "$JOB_FILE"
        echo "$CRON_JOB" >> "$JOB_FILE"
        if ! busybox crontab "$JOB_FILE" -c "$JOB_DIR"; then
            echo "[✗] Failed to enable auto update: cron-side error."
            log_message ERROR "Failed to enable auto update: cron-side error."
        else
            log_message "Cron job added."
            crond -c $JOB_DIR -L $persist_dir/logs/auto_update.log
            sed -i 's/^daily_update=.*/daily_update=1/' "/data/adb/Re-Malwack/config.sh"
            log_message SUCCESS "Auto-update has been enabled."
            echo "[✓] Auto-update enabled."
        fi
    fi
}

# 2 - Disable cron
function disable_cron() {
    JOB_DIR="/data/adb/Re-Malwack/auto_update"
    JOB_FILE="$JOB_DIR/root"
    CRON_JOB="0 */12 * * * sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts && echo \"[$(date '+%Y-%m-%d %H:%M:%S')] - Running auto update.\" >> /data/adb/Re-Malwack/logs/auto_update.log"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
    log_message "Disabling auto update has been initiated."
    log_message "Killing cron processes"
    # Kill cron lore
    busybox pkill crond > /dev/null 2>&1
    busybox pkill busybox crond > /dev/null 2>&1
    busybox pkill busybox crontab > /dev/null 2>&1
    busybox pkill crontab > /dev/null 2>&1
    log_message "Cron processes stopped."

    # Check if cron job exists
    if [ ! -d "$JOB_DIR" ]; then
        echo "[i] Auto update is already disabled"
    else    
        rm -rf "$JOB_DIR"
        log_message "Cron job removed."

        # Disable auto-update
        sed -i 's/^daily_update=.*/daily_update=0/' "/data/adb/Re-Malwack/config.sh"
        log_message SUCCESS "Auto-update has been disabled."
        echo "[✓] Auto-update disabled."
    fi
}

# Now enough functions and variables, Let's start the real work 😎

# Trigger force stats refresh on WebUI
if [ "$WEBUI" = "true" ]; then
    refresh_blocked_counts
    update_status
fi
#### Error logging lore

# 1 - Log errors
exec 2>>"$LOGFILE"

# 2 - Trap runtime errors (logs failing command + exit code)
trap '
err_code=$?
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$timestamp] - [ERROR] - Command \"$BASH_COMMAND\" failed at line $LINENO (exit code: $err_code)" >> "$LOGFILE"
' ERR

# 3 - Trap final script exit
trap '
exit_code=$?
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

case $exit_code in
    0)
        echo "[$timestamp] - [SUCCESS] - Script ran successfully ✅ - No errors" >> "$LOGFILE"
        ;;
    1)   msg="General error ❌" ;;
    126) msg="Command invoked cannot execute ❌" ;;
    127) msg="Command not found ❌" ;;
    130) msg="Terminated by Ctrl+C (SIGINT) ❌" ;;
    137) msg="Killed (possibly OOM or SIGKILL) ❌" ;;
    *)   msg="Unknown error ❌ (code $exit_code)" ;;
esac

[ $exit_code -ne 0 ] && echo "[$timestamp] - [ERROR] - $msg at line $LINENO (exit code: $exit_code)" >> "$LOGFILE"
' EXIT

# Check for --quiet argument
for arg in "$@"; do
    if [ "$arg" = "--quiet" ]; then
        quiet_mode=1
        break
    fi
done

# Show banner if not running from Magisk Manager / quiet mode is disabled
[ -z "$MAGISKTMP" ] && [ "$quiet_mode" = 0 ] && rmlwk_banner

# ====== Main Logic ======
case "$(tolower "$1")" in
    --adblock-switch|-as)
        start_time=$(date +%s)
        pause_protections
        log_duration "pause_or_resume_adblock" "$start_time"
        ;;
    --reset|-r)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        start_time=$(date +%s)
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
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Successfully reverted changes."
	    echo "[✓] Successfully reverted changes."
        log_duration "reset" "$start_time"
        ;;
    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs|--block-trackers|-bt)
            start_time=$(date +%s)
            is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."
    
            case "$1" in
                --block-porn|-bp) block_type="porn" ;;
                --block-gambling|-bg) block_type="gambling" ;;
                --block-fakenews|-bf) block_type="fakenews" ;;
                --block-social|-bs) block_type="social" ;;
                --block-trackers|-bt) block_type="trackers" ;;
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
                    else
                        log_message "Disabling ${block_type} has been initiated."
                        echo "[*] Removing block entries for ${block_type} sites."
                        block_content "$block_type" 0
                        log_message SUCCESS "Unblocked ${block_type} sites successfully."
                        echo "[✓] Unblocked ${block_type} sites successfully."
                    fi
                else
                    if [ "$block_toggle" = 1 ]; then
                        echo "[!] ${block_type} block is already enabled"
                    else
                        log_message "Enabling/Adding block entries for $block_type has been initiated."
                        echo "[*] Adding block entries for ${block_type} sites."
                        block_content "$block_type" 1
                        log_message SUCCESS "Blocked ${block_type} sites successfully."
                        echo "[*] Blocked ${block_type} sites successfully."
                    fi
                fi
            fi
    
            refresh_blocked_counts
            update_status
            log_duration "block-$block_type" "$start_time"
            ;;

    --whitelist|-w)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        is_default_hosts && abort "You cannot whitelist links while hosts is reset."
        option="$2"
        raw_input="$3"

        # Normalize full URL or wildcard input
        if printf "%s" "$raw_input" | grep -qE '^https?://'; then
            domain=$(printf "%s" "$raw_input" | awk -F[/:] '{print $4}')
        else
            domain="$raw_input"
        fi

        wildcard_match=0
        if echo "$raw_input" | grep -q '^\*\.'; then
            wildcard_match=1
        fi

        domain=$(printf "%s" "$domain" | sed 's/^\*\.\?//')
        escaped_domain=$(printf '%s' "$domain" | sed 's/[.[\*^$/]/\\&/g')

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "Usage: rmlwk --whitelist, -w <add/remove> <domain>"
            display_whitelist=$(cat "$persist_dir/whitelist.txt" 2>/dev/null)
            [ ! -z "$display_whitelist" ] && echo -e "Current whitelist:\n$display_whitelist" || echo "Current whitelist: no saved whitelist"
            exit 1
        else
            touch "$persist_dir/whitelist.txt"
            if [ "$option" = "add" ]; then

                # Determine match pattern based on wildcard presence
                if [ "$wildcard_match" -eq 1 ]; then
                    pattern="^0\.0\.0\.0 (.*\.)?$escaped_domain\$"
                else
                    pattern="^0\.0\.0\.0 $escaped_domain\$"
                fi

                # Add domain to whitelist.txt and remove from hosts
                if grep -qxF "$domain" "$persist_dir/whitelist.txt"; then
                    echo "[i] $domain is already whitelisted"
                    exit 1
                elif ! grep -Eq "$pattern" "$hosts_file"; then
                    echo "[!] $domain not found in hosts file. Nothing to whitelist."
                    exit 1
                else
                    # Parse entries to whitelist
                    grep -E "$pattern" "$hosts_file" | awk '{print $2}' | sort -u | while read -r matched; do
                        echo "$matched" >> "$persist_dir/whitelist.txt"
                    done
                    # Remove entries from hosts
                    echo "[i] The following domain(s) matched and were whitelisted:"
                    printf "%s\n" "$matched_domains"
                    log_message SUCCESS "Whitelisted domains: $(printf "%s " $matched_domains)"
                    sed -E "/$pattern/d" "$hosts_file" > "$tmp_hosts"
                    cat "$tmp_hosts" > "$hosts_file"

                    # Cleanup whitelist file - deduplicate
                    sort -u "$persist_dir/whitelist.txt" -o "$persist_dir/whitelist.txt"
                    rm -f "$tmp_hosts"
                fi
            else
                # Remove domain(s) from whitelist.txt based on wildcard or exact
                if [ "$wildcard_match" -eq 1 ]; then
                    removal_pattern="(.*\.)?$escaped_domain"
                else
                    removal_pattern="^$escaped_domain\$"
                fi

                if grep -Eq "$removal_pattern" "$persist_dir/whitelist.txt"; then
                    sed -i -E "/$removal_pattern/d" "$persist_dir/whitelist.txt"
                    log_message SUCCESS "Removed $domain and matching entries from whitelist. They will be re-blocked on the next update." && echo "[✓] $domain removed from whitelist."
                else
                    echo "[!] $domain isn't in whitelist."
                    exit 1
                fi
            fi
        fi
        refresh_blocked_counts
        update_status
        ;;

    --blacklist|-b)
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."
        option="$2"
        raw_input="$3"

        # Sanitize input
        if printf "%s" "$raw_input" | grep -qE '^https?://'; then
            domain=$(printf "%s" "$raw_input" | awk -F[/:] '{print $4}')
        else
            domain="$raw_input"
        fi

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "Usage: rmlwk --blacklist, -b <add/remove> <domain>"
            display_blacklist=$(cat "$persist_dir/blacklist.txt" 2>/dev/null)
            [ ! -z "$display_blacklist" ] && echo -e "Current blacklist:\n$display_blacklist" || echo "Current blacklist: no saved blacklist"
            exit 1
        else
            touch "$persist_dir/blacklist.txt"
            if [ "$option" = "add" ]; then
                # Add to blacklist.txt if not already there
                grep -qxF "$domain" "$persist_dir/blacklist.txt" || echo "$domain" >> "$persist_dir/blacklist.txt"

                # Add to hosts file if not already present
                if grep -qE "^0\.0\.0\.0[[:space:]]+$domain\$" "$hosts_file"; then
                    echo "[!] $domain is already blacklisted."
                    exit 1
                else
                    # Ensure newline at end before appending
                    [ -s "$hosts_file" ] && tail -c1 "$hosts_file" | grep -qv $'\n' && echo "" >> "$hosts_file"
                    echo "0.0.0.0 $domain" >> "$hosts_file" && echo "[✓] Blacklisted $domain."
                    log_message SUCCESS "Done added $domain to hosts file and blacklist."
                fi
            else
                # Remove from blacklist.txt if present
                if grep -qxF "$domain" "$persist_dir/blacklist.txt"; then
                    sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/blacklist.txt"
                    log_message "Removed $domain from blacklist."
                    echo "[✓] $domain removed from blacklist, domain will be unblocked after hosts update."
                else
                    echo "[!] $domain isn't found in blacklist."
                    exit 1
                fi
            fi
        fi
        refresh_blocked_counts
        update_status
        ;;

	--custom-source|-c)
        option="$2"
        domain="$3"

        if [ -z "$option" ]; then
            echo "[!] Missing argument: You must specify 'add' or 'remove'."
            echo "Usage: rmlwk --custom-source <add/remove> <domain>"
            exit 1
        fi

        if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
            echo "[!] Invalid option: Use 'add' or 'remove'."
            echo "Usage: rmlwk --custom-source <add/remove> <domain>"
            exit 1
        fi

        if [ -z "$domain" ]; then
            echo "[!] Missing domain: You must specify a domain."
            echo "Usage: rmlwk --custom-source <add/remove> <domain>"
            exit 1
        fi

        touch "$persist_dir/sources.txt"

        if [ "$option" = "add" ]; then
            if grep -qx "$domain" "$persist_dir/sources.txt"; then
                echo "[!] $domain is already in sources."
            else
                echo "$domain" >> "$persist_dir/sources.txt"
                log_message SUCCESS "Added $domain to sources."
                echo "[✓] Added $domain to sources."
            fi
        else
            if grep -qx "$domain" "$persist_dir/sources.txt"; then
                sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/sources.txt"
                log_message SUCCESS "Removed $domain from sources."
                echo "[✓] Removed $domain from sources."
            else
                log_message ERROR "Failed to remove $domain from sources, maybe wasn't even found?."
                echo "[!] $domain was not even found in sources."
            fi
        fi
        ;;

    --auto-update|-a)
        case "$2" in
            enable)
                enable_cron
                ;;
            disable)
                disable_cron
                ;;
            *)
                echo "[!] Invalid option for --auto-update / -a"
                echo "Usage: rmlwk <--auto-update|-a> <enable|disable>"
                ;;
        esac
        ;;

    --update-hosts|-u)
        start_time=$(date +%s)
        sed '/#/d' $persist_dir/sources.txt | grep http > /dev/null || {
        			abort "No hosts sources were found, Aborting."
        			}
        is_protection_paused && abort "Ad-block is paused. Please resume before running this command."

        if [ -d /data/adb/modules/Re-Malwack ]; then
            echo "[*] Upgrading Anti-Ads fortress 🏰"
            log_message "Updating protections..."
        else
            echo "[*] Building Anti-Ads fortress 🏰"
            log_message "Installing protection for the first time"
        fi
        nuke_if_we_dont_have_internet

        combined_file="${tmp_hosts}_all"
        > "$combined_file"

        # 1. Download + normalize base hosts
        echo "[*] Fetching base hosts..."
        hosts_list=$(grep -Ev '^#|^$' "$persist_dir/sources.txt" | sort -u)
        counter=0
        for host in $hosts_list; do
            counter=$((counter + 1))
            fetch "${tmp_hosts}${counter}" "$host" &
        done
        wait

        # Process in parallel
        job_limit=4
        job_count=0
        for i in $(seq 1 $counter); do
            (
                host_process "${tmp_hosts}${i}"
                cat "${tmp_hosts}${i}" >> "$combined_file"
            ) &
            job_count=$((job_count + 1))
            [ "$job_count" -ge "$job_limit" ] && wait && job_count=0
        done
        wait

        # 3. Download & process blocklists (cached + enabled)
        blocklists_to_install=""
        for bl in porn gambling fakenews social; do
            block_var="block_${bl}"
            eval enabled=\$$block_var
            cache_hosts="$persist_dir/cache/$bl/hosts"

            # Download & process only if blocklist is enabled
          if [ "$enabled" = "1" ]; then
              mkdir -p "$persist_dir/cache/$bl"
              echo "[*] Fetching blocklist: $bl"
              log_message "Fetching blocklist: $bl"
              fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${bl}-only/hosts"
              if [ "$bl" = "porn" ]; then
                  fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                  fetch "${cache_hosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts &
                  fetch "${cache_hosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing &
                  wait
              fi
          
              # Process downloaded hosts
              for file in "$persist_dir/cache/$bl/hosts"*; do
                  [ -f "$file" ] && host_process "$file"
              done
          
              # Append only if enabled
              cat "$persist_dir/cache/$bl/hosts"* >> "$combined_file"
              echo "[✓] Fetched $bl blocklist"
              log_message "Added $bl blocklist to combined file"
          else
              echo "[i] Skipped $bl blocklist (disabled)"
          fi
        done
        # 3b. Handle trackers blocklist if enabled
        if [ "$block_trackers" = "1" ]; then
            echo "[*] Fetching trackers blocklist..."
            log_message "Fetching trackers blocklist"
            mkdir -p "$persist_dir/cache/trackers"

            cache_hosts="$persist_dir/cache/trackers/hosts"
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardTracking.txt"
            brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
            case "$brand" in
                xiaomi|redmi|poco) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt" ;;
                samsung) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt" ;;
                oppo|realme) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt" ;;
                vivo) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt" ;;
                huawei) url="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt" ;;
                *) echo "[i] Your device brand isn't supported, using general trackers blocklist only." && url="" ;;
            esac

            host_process "${cache_hosts}1"
            [ -n "$url" ] && fetch "${cache_hosts}2" "$url" && host_process "${cache_hosts}2"

            cat "$persist_dir/cache/trackers/hosts"* >> "$combined_file"
            echo "[✓] Fetched trackers blocklist"
            log_message "Added trackers blocklist to combined file"
        fi
        echo "[*] Installing hosts"
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        install_hosts "all"

        # 4. Done
        refresh_blocked_counts
        update_status
        log_message SUCCESS "Successfully updated all hosts."
        [ ! "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ] && echo "[✓] Everything is now Good!"
        log_duration "update-hosts" "$start_time"
        ;;

    --help|-h|*)
        echo ""
        echo "[i] Usage: rmlwk [--argument] OPTIONAL: [--quiet]"
        echo "--update-hosts, -u: Update the hosts file."
        echo "--auto-update, -a <enable|disable>: Toggle auto hosts update."
        echo "--custom-source, -c <add|remove> <domain>: Add custom hosts source."
        echo "--reset, -r: Restore original hosts file."
        echo "--adblock-switch, -as: Toggle protections on/off"
        echo "--block-trackers, -bt <disable>, block trackers, use disable to unblock."
        echo "--block-porn, -bp <disable>: Block pornographic sites, use disable to unblock."
        echo "--block-gambling, -bg <disable>: Block gambling sites, use disable to unblock."
        echo "--block-fakenews, -bf <disable>: Block fake news sites, use disable to unblock."
        echo "--block-social, -bs <disable>: Block social media sites, use disable to unblock."
        echo "--whitelist, -w <add|remove> <domain>: Whitelist a domain."
        echo "--blacklist, -b <add|remove> <domain>: Blacklist a domain."
        echo "--help, -h: Display help."
        echo -e "\033[0;31m Example command: su -c rmlwk --update-hosts\033[0m"
        ;;
esac