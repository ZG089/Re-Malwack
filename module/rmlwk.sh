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
    local tmp_file="${file}.tmp"
    # Exclude whitelist files
    echo "$file" | tr '[:upper:]' '[:lower:]' | grep -q "whitelist" && return 0

    # Unified filtration: remove comments, empty lines, trim whitespaces, handles windows-formatted hosts 
    log_message "Filtering $file..."
    sed -i '/^[[:space:]]*#/d; s/[[:space:]]*#.*$//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\r$//' "$file"

    # Decompress multi-domain host entries
    if awk '$1 == "0.0.0.0" && NF > 2 { exit 0 } END { exit 1 }' "$file"; then
        log_message WARN "Detected compressed entries in $file, splitting..."
        awk '
            $1 == "0.0.0.0" && NF > 2 {
                for (i = 2; i <= NF; i++) {
                    print $1, $i
                }
                next
            }
            { print }
        ' "$file" > "$tmp_file"
        mv "$tmp_file" "$file"
    fi
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
    [ -f "$persist_dir/hosts.bak" ] && [ "$adblock_switch" -eq 1 ]
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

# 1 - Install hosts
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

    # Update hosts
    log_message "Merging hosts"
    LC_ALL=C sort -u "${tmp_hosts}"[!0] "${tmp_hosts}0" > "${tmp_hosts}merged.sorted"
    log_message "Unifying hosts"
    LC_ALL=C comm -23 "${tmp_hosts}merged.sorted" "${tmp_hosts}w" > "$hosts_file"

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message SUCCESS "Successfully installed $type hosts."
    log_duration "install_hosts ($type)" "$start_time"
}

# 2 - Remove hosts
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
        echo "- Warning: Hosts file is empty. Restoring default entries."
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
    if [ "$status" = 0 ]; then
        if [ ! -f "${cache_hosts}1" ]; then # Fallback in case cached hosts was deleted
            echo "[!] Cached blocklist for '$block_type' not found!"
            echo "[*] Re-downloading the blocklist to proceed with disabling."
            echo "[!] Please do not modify or delete /data/adb/Re-Malwack directory files."
            echo "[i] If you think a cleaner app accidentally removed one of the files, Please add the directory to the exceptions list."
            log_message WARN "Missing cached blocklist for $block_type — auto-redownloading."
            nuke_if_we_dont_have_internet
            mkdir -p "$persist_dir/cache/$block_type"
            fetch "${cache_hosts}1" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts &
                fetch "${cache_hosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing &
                wait
            fi
        fi
        # Applying updated hosts
        install_hosts "$block_type"
        remove_hosts
        # Update config
        sed -i "s/^block_${block_type}=.*/block_${block_type}=0/" /data/adb/Re-Malwack/config.sh
    else
        # Download hosts only if no cached host found or during update
        if [ ! -f "${cache_hosts}1" ] || [ "$status" = "update" ]; then
            nuke_if_we_dont_have_internet
            mkdir -p "$persist_dir/cache/$block_type"
            echo "[*] Downloading & Applying hosts for $block_type block."
            log_message "Downloading hosts for $block_type block."
            fetch "${cache_hosts}1" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://raw.githubusercontent.com/Sinfonietta/hostfiles/refs/heads/master/pornography-hosts &
                fetch "${cache_hosts}4" https://raw.githubusercontent.com/columndeeply/hosts/refs/heads/main/safebrowsing &
                wait
            fi
            
        # Normalize downloaded hosts
            job_limit=4
            job_count=0
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                host_process "$file"
                job_count=$((job_count + 1))
                [ "$job_count" -ge "$job_limit" ] && wait && job_count=0
            done
            wait
        fi

        # Skip install if called from hosts update
        if [ "$status" = "update" ]; then
            block_var="block_${block_type}"
            eval enabled=\$$block_var
            if [ "$enabled" != "1" ]; then
                log_message WARN "Skipping install of $block_type blocklist: toggle is OFF"
                echo "[i] Skipping install of $block_type blocklist: toggle is OFF."
            fi
            return 0
        fi
        sed -i "s/^block_${block_type}=.*/block_${block_type}=1/" /data/adb/Re-Malwack/config.sh
        cp -f "${cache_hosts}"* "/data/local/tmp"
        [ "$status" = 0 ] && remove_hosts || install_hosts "$block_type"
    fi
    log_duration "block_content ($block_type, $status)" "$start_time"
}

# shortcase
function tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# uhhhhh
function abort() {
    log_message "Aborting: $1"
    echo "-$1"
    sleep 0.5
    exit 1
}

# Bruh It's clear already what this function does ._.
function nuke_if_we_dont_have_internet() {
    ping -c 1 -w 5 8.8.8.8 &>/dev/null || abort "[!] No internet connection detected, Please connect to a network then try again."
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

# 1 - Include error logging
exec 2>>"$LOGFILE"
# 2 - Trap runtime errors
trap '
err_code=$?
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$timestamp] - Runtime ERROR ❌ at line $LINENO (exit code: $err_code)" >> "$LOGFILE"
' ERR

# 3 - Trap final script exit
trap '
exit_code=$?
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

case $exit_code in
    0)
        echo "[$timestamp] - Script ran successfully ✅ - No errors" >> "$LOGFILE"
        ;;
    1)   msg="General error ❌" ;;
    126) msg="Command invoked cannot execute ❌" ;;
    127) msg="Command not found ❌" ;;
    130) msg="Terminated by Ctrl+C (SIGINT) ❌" ;;
    137) msg="Killed (possibly OOM or SIGKILL) ❌" ;;
    *)   msg="Unknown error ❌ (code $exit_code)" ;;
esac

[ $exit_code -ne 0 ] && echo "[$timestamp] - $msg at line $LINENO (exit code: $exit_code)" >> "$LOGFILE"
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
        is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."
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

    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs)
        start_time=$(date +%s)
        is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."
        case "$1" in
            --block-porn|-bp) block_type="porn" ;;
            --block-gambling|-bg) block_type="gambling" ;;
            --block-fakenews|-bf) block_type="fakenews" ;;
            --block-social|-bs) block_type="social" ;;
        esac
        status="$2"
        eval "block_toggle=\"\$block_${block_type}\""

        if [ "$status" = "disable" ] || [ "$status" = 0 ]; then
            if [ "$block_toggle" = 0 ]; then
                echo "- $block_type block is already disabled"
            else
                log_message "Disabling ${block_type} has been initiated." && echo "[*] Removing block entries for ${block_type} sites."
                block_content "$block_type" 0
                log_message SUCCESS "Unblocked ${block_type} sites successfully." && echo "[✓] Unblocked ${block_type} sites successfully."
            fi
        else
            if [ "$block_toggle" = 1 ]; then
                echo "[!] ${block_type} block is already enabled"
            else
                log_message "Enabling/Adding block entries for $block_type has been initiated."
                echo "[*] Adding block entries for ${block_type} sites."
                block_content "$block_type" 1
                log_message SUCCESS "Blocked ${block_type} sites successfully." && echo "[*] Blocked ${block_type} sites successfully."
            fi
        fi
        refresh_blocked_counts
        update_status
        log_duration "block-$block_type" "$start_time"
        ;;

    --whitelist|-w)
        is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."
        is_default_hosts && abort "[i] You cannot whitelist links while hosts is reset."
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
        is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."
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
        is_protection_paused && abort "[!] Ad-block is paused. Please resume before running this command."

        if [ -d /data/adb/modules/Re-Malwack ]; then
            echo "[*] Upgrading Anti-Ads fortress 🏰"
            log_message "Updating protections..."
        else
            echo "[*] Building Anti-Ads fortress 🏰"
            log_message "Installing protection for the first time"
        fi
        nuke_if_we_dont_have_internet
        # Re-Malwack general hosts
        # Load sources from the file, ignoring comments
        hosts_list=$(grep -Ev '^#|^$' "$persist_dir/sources.txt" | sort -u)
        echo "[>] Loaded hosts sources from sources.txt, fetching hosts"
        # Download hosts in parallel
        counter=0
        for host in $hosts_list; do
            counter=$((counter + 1))
            fetch "${tmp_hosts}${counter}" "$host" &
        done
        wait
        # process hosts in parallel
        job_limit=4
        job_count=0
        for i in $(seq 1 $counter); do
            host_process "${tmp_hosts}${i}" &
            job_count=$((job_count + 1))
            [ "$job_count" -ge "$job_limit" ] && wait && job_count=0
        done
        wait

        # Run blocklist updates *in sequence* for better log clarity
        [ -d "$persist_dir/cache/porn" ] && block_content "porn" "update"
        [ -d "$persist_dir/cache/gambling" ] && block_content "gambling" "update"
        [ -d "$persist_dir/cache/fakenews" ] && block_content "fakenews" "update"
        [ -d "$persist_dir/cache/social" ] && block_content "social" "update"

        echo "[*] Installing base hosts"
        printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
        install_hosts "base"

        # Apply configured blocks
        [ "$block_porn" = 1 ] && block_content "porn" && log_message "Applied porn blocklist"
        [ "$block_gambling" = 1 ] && block_content "gambling" && log_message "Applied gambling blocklist"
        [ "$block_fakenews" = 1 ] && block_content "fakenews" && log_message "Applied fake news blocklist"
        [ "$block_social" = 1 ] && block_content "social" && log_message "Applied social blocklist"

        refresh_blocked_counts
        update_status
        log_message SUCCESS "Successfully updated all hosts."
        [ ! "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ] && echo "[✓] Everything is now Good!"
        log_duration "update-hosts" "$start_time"
        ;;

    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument] OPTIONAL: [--quiet]"
        echo "--update-hosts, -u: Update the hosts file."
        echo "--auto-update, -a <enable|disable>: Toggle auto hosts update."
        echo "--custom-source, -c <add|remove> <domain>: Add custom hosts source."
        echo "--reset, -r: Restore original hosts file."
        echo "--adblock-switch, -as: Toggle protections on/off"
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
