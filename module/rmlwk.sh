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
mkdir -p "$persist_dir/logs"


# ====== Functions ======

# Banner function
function rmlwk_banner() {
    # Skip banner if quiet mode is enabled
    [ "$quiet_mode" -eq 1 ] && return

    clear

    banner1=$(cat <<'EOF'
\033[0;31m    ____             __  ___      __                    __            
   / __ \___        /  |/  /___ _/ /      ______ ______/ /__          
  / /_/ / _ \______/ /|_/ / __ `/ / | /| / / __ `/ ___/ //_/       
 / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<             
/_/ |_|\___/     /_/  /_/\__,_/_/ |__/|__/\__,_/\___/_/|_|           
 
EOF
)
    banner2=$(cat <<'EOF'
\033[0;31m██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝
██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ 
██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ 
██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗
╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
)

    if command -v shuf >/dev/null 2>&1; then
        random_index=$(shuf -i 1-2 -n 1)
    else
        random_index=$(( ($(date +%s) % 2) + 1 ))
    fi

    case $random_index in
        1) echo -e "$banner1" ;;
        2) echo -e "$banner2" ;;
    esac

    printf '\033[0m'
    update_status
    echo " "
    echo "$version - $status_msg"
    printf '\033[0;31m'
    echo "================================================================="
    printf '\033[0m'
}

# Function to check hosts file reset state
function is_default_hosts() {
    [ "$blocked_mod" -eq 0 ] && [ "$blocked_sys" -eq 0 ] && return 0
    return 1
}

# Function to process hosts, maybe?
function host_process() {
    local file="$1"
    local tmp_file="${file}.tmp"
    
    # Exclude whitelist files
    case "$file" in
        *whitelist*)
            return 0
            ;;
    esac
    # Unified filtration: remove comments, empty lines, trim whitespaces
    sed '/^[[:space:]]*#/d; s/[[:space:]]*#.*$//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
    log_message "Filtering $file..."

    # Convert 127.0.0.1 entries except localhost to 0.0.0.0
    if grep -vq '^127\.0\.0\.1[[:space:]]*localhost$' "$file"; then
        log_message "Detected 127.0.0.1 ad-block method in $file, converting to 0.0.0.0..."
        sed '/^127\.0\.0\.1[[:space:]]*localhost$/! s/^127\.0\.0\.1[[:space:]]\+/0.0.0.0 /' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
    fi

    # Decompress multi-domain host entries
    if awk '$1 == "0.0.0.0" && NF > 2 { found = 1; exit } END { exit !found }' "$file"; then
        log_message "Detected compressed entries in $file, splitting..."
        awk '
            $1 == "0.0.0.0" && NF > 2 {
                for (i = 2; i <= NF; i++) {
                    print $1, $i
                }
                next
            }
            { print }
        ' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
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

# Functions for pause and resume ad-block

# 1 - Pause adblock
function pause_adblock() {
    # Check if protection is already paused
    if is_adblock_paused; then
        resume_adblock
        exit 0
    fi
    # Check if hosts file is reset
    if is_default_hosts; then
        echo "You cannot pause Ad-block while hosts is reset"
        exit
    fi
    log_message "Pausing Protections"
    echo "- Pausing Protections"
    cat $hosts_file > "$persist_dir/hosts.bak"
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
    chmod 644 "$hosts_file"
    sed -i 's/^adblock_switch=.*/adblock_switch=1/' "/data/adb/Re-Malwack/config.sh"
    refresh_blocked_counts
    update_status
    log_message "Protection has been paused."
    echo "- Protection has been paused."
}

# 2 - Resume adblock
function resume_adblock() {
    log_message "Resuming protection."
    echo "- Resuming protection"
    if [ -f "$persist_dir/hosts.bak" ]; then
        cat "$persist_dir/hosts.bak" > "$hosts_file"
        chmod 644 "$hosts_file"
        rm -f $persist_dir/hosts.bak
        sed -i 's/^adblock_switch=.*/adblock_switch=0/' "/data/adb/Re-Malwack/config.sh"
        refresh_blocked_counts
        update_status
        log_message "Protection has been resumed."
        echo "- Protection has been resumed."
    else
        log_message "No backup hosts file found to resume."
        echo "- No backup hosts file found to resume."
    fi
}

# function to check adblock pause
function is_adblock_paused() {
    if [ -f "$persist_dir/hosts.bak" ] && [ "$adblock_switch" -eq 1 ] ; then
        return 0
    else
        return 1
    fi
}

# Logging func - Literally helpful for any dev :D
function log_message() {
    message="$1"
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> $LOGFILE
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
    [ -s "$persist_dir/blacklist.txt" ] && sed '/#/d; /^$/d' "$persist_dir/blacklist.txt" | awk '{print "0.0.0.0", $0}' >> "${tmp_hosts}0"

    # Process whitelist
    log_message "Processing Whitelist..."
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"

    if [ "$block_social" -eq 0 ]; then
        whitelist_file="$whitelist_file $persist_dir/cache/whitelist/social_whitelist.txt"
    else
        log_message "Social Block triggered, Social whitelist won't be applied"
    fi

    # Append user-defined whitelist if it exists
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    # Debugging - Check each whitelist file individually
    for file in $whitelist_file; do
        if [ ! -f "$file" ]; then
            log_message "WARNING: Whitelist file $file does not exist!"
        elif [ ! -s "$file" ]; then
            log_message "WARNING: Whitelist file $file is empty!"
        else
            log_message "Whitelist file $file found with content."
        fi
    done

    # Merge whitelist files into one
    cat $whitelist_file | sed '/#/d; /^$/d' | sort -u | awk '{print "0.0.0.0", $0}' > "${tmp_hosts}w"

    # If whitelist is empty, log and skip filtering
    if [ ! -s "${tmp_hosts}w" ]; then
        log_message "Whitelist is empty. Skipping whitelist filtering."
        echo "" > "${tmp_hosts}w"
    fi

    # Update hosts
    log_message "Finalizing..."
    sort -u "${tmp_hosts}"[!0] "${tmp_hosts}0" | grep -Fxvf "${tmp_hosts}w" > "$hosts_file"

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message "Successfully installed hosts."
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
        log_message "Detected empty hosts file"
        log_message "Restoring default entries..."
        echo -e "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
    fi

    # Clean up
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message "Successfully removed hosts."
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
            echo "- Warning: Cached blocklist for '$block_type' not found!"
            echo "- Re-downloading the blocklist to proceed with disabling."
            echo "- Please do not modify or delete /data/adb/Re-Malwack directory files."
            echo " - If you think a cleaner app accidentally removed one of the files, Please add the directory to the exceptions list."
            log_message "Missing cached blocklist for $block_type — auto-redownloading."
            nuke_if_we_dont_have_internet
            mkdir -p "$persist_dir/cache/$block_type"
            fetch "${cache_hosts}1" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://www.someonewhocares.org/hosts/hosts &
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
            echo "- Downloading hosts for $block_type block."
            log_message "Downloading hosts for $block_type block."
            fetch "${cache_hosts}1" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt &
                fetch "${cache_hosts}3" https://www.someonewhocares.org/hosts/hosts &
                wait
            fi
            
            # Normalize downloaded hosts
            for file in "$persist_dir/cache/$block_type/hosts"*; do
                host_process "$file"
            done
        fi

        # Skip install if called from hosts update
        if [ "$status" = "update" ]; then
            block_var="block_${block_type}"
            eval enabled=\$$block_var
            if [ "$enabled" != "1" ]; then
                log_message "Skipping install of '$block_type' blocklist: toggle is OFF"
                echo "INFO: Skipping install of '$block_type' blocklist: toggle is OFF."
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
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || abort "No internet connection detected, Please connect to a network then try again."
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
        curl -Ls "$url" > "$output_file" || {
            log_message "Failed to download $url with curl"
            echo "WARNING: Failed to download hosts from $url"
        }
        echo "" >> "$output_file"
    else # Else we gotta just fallback to windows ge- my bad I mean winget.
        busybox wget --no-check-certificate -qO - "$url" > "$output_file" || {
            log_message "Failed to download $url with wget"
            echo "WARNING: Failed to download hosts from $url"
        }
        echo "" >> "$output_file"
    fi
    log_message "Downloaded hosts from $url, stored in $output_file"
    log_duration "fetch and process hosts file from ($url)" "$start_time"
}

# Updates module status, modifying module description in module.prop
function update_status() {
    start_time=$(date +%s)
    log_message "Fetching last hosts file update"
    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file
    log_message "Last hosts file update was in: $last_mod"

    # System hosts count
    if [ ! -d "/data/adb/modules/Re-Malwack" ]; then
        log_message "First install detected (module directory missing)."
    fi

    # Module hosts count
    blocked_sys=$(cat "$persist_dir/counts/blocked_sys.count" 2>/dev/null)
    blocked_mod=$(cat "$persist_dir/counts/blocked_mod.count" 2>/dev/null)
    log_message "System hosts entries count: $blocked_sys"
    log_message "Module hosts entries count: $blocked_mod"

    # Here goes the part where we actually determine module status
    if is_adblock_paused; then
        status_msg="Status: Protection is paused ⏸️"
    elif [ -d /data/adb/modules_update/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (pending module update)"
    elif [ -d /data/adb/modules_update/Re-Malwack ] && [ ! -d /data/adb/modules/Re-Malwack ]; then
        status_msg="Status: Reboot required to apply changes 🔃 (First time install)"
    elif [ "$blocked_mod" -gt 10 ]; then
        if [ "$blocked_mod" -ne "$blocked_sys" ]; then # Only for cases when mount breaks between module hosts and system hosts
            status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
        else
            status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains | Last updated: $last_mod"
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
        echo "- Auto update is already enabled"
    else
        # Create directory and file if they don't exist
        mkdir -p "$JOB_DIR"
        touch "$JOB_FILE"
        echo "$CRON_JOB" >> "$JOB_FILE"
        if ! busybox crontab "$JOB_FILE" -c "$JOB_DIR"; then
            echo "Failed to enable auto update: cron-side error."
            log_message "Failed to enable auto update: cron-side error."
        else
            log_message "Cron job added."
            crond -c $JOB_DIR -L $persist_dir/logs/auto_update.log
            sed -i 's/^daily_update=.*/daily_update=1/' "/data/adb/Re-Malwack/config.sh"
            log_message "Auto-update has been enabled."
            echo "- Auto-update enabled."
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
        echo "- Auto update is already disabled"
    else    
        rm -rf "$JOB_DIR"
        log_message "Cron job removed."

        # Disable auto-update
        sed -i 's/^daily_update=.*/daily_update=0/' "/data/adb/Re-Malwack/config.sh"
        log_message "Auto-update has been disabled."
        echo "- Auto-update disabled."
    fi
}

# Now enough functions and variables, Let's start the real work 😎

# Sourcing config file
. "$persist_dir/config.sh"

# Error logging lore

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
        pause_adblock
        log_duration "pause_or_resume_adblock" "$start_time"
        ;;
    --reset|-r)
        start_time=$(date +%s)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume before running this command."
            exit 1
        fi
        log_message "Resetting hosts command triggered, resetting..."
        echo "- Reverting the changes..."
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        refresh_blocked_counts
        update_status
        log_message "Successfully reverted changes."
	    echo "- Successfully reverted changes."
        log_duration "reset" "$start_time"
        ;;

    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs)
        start_time=$(date +%s)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume before running this command."
            exit 1
        fi
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
                log_message "Disabling ${block_type} has been initiated." && echo "- Removing block entries for ${block_type} sites."
                block_content "$block_type" 0
                log_message "Unblocked ${block_type} sites successfully." && echo "- Unblocked ${block_type} sites successfully."
            fi
        else
            if [ "$block_toggle" = 1 ]; then
                echo "- ${block_type} block is already enabled"
            else
                log_message "Enabling/Adding block entries for $block_type has been initiated."
                echo "- Adding block entries for ${block_type} sites."
                block_content "$block_type" 1
                log_message "Blocked ${block_type} sites successfully." && echo "- Blocked ${block_type} sites successfully."
            fi
        fi
        refresh_blocked_counts
        update_status
        log_duration "block-$block_type" "$start_time"
        ;;

    --whitelist|-w)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume it before running this command."
            exit 1
        fi
        if is_default_hosts; then
            echo "- You cannot whitelist links while hosts is reset."
            exit 1
        fi
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
            echo "usage: rmlwk --whitelist <add/remove> <domain>"
            display_whitelist=$(cat "$persist_dir/whitelist.txt" 2>/dev/null)
            [ ! -z "$display_whitelist" ] && echo -e "Current whitelist:\n$display_whitelist" || echo "Current whitelist: no saved whitelist"
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
                    echo "$domain is already whitelisted"
                elif ! grep -Eq "$pattern" "$hosts_file"; then
                    echo "- $domain not found in hosts file. Nothing to whitelist."
                    exit 1
                else
                    # Parse entries to whitelist
                    grep -E "$pattern" "$hosts_file" | awk '{print $2}' | sort -u | while read -r matched; do
                        echo "$matched" >> "$persist_dir/whitelist.txt"
                    done
                    # Remove entries from hosts
                    echo "- The following domain(s) matched and were whitelisted:"
                    printf "%s\n" "$matched_domains"
                    log_message "Whitelisted domains: $(printf "%s " $matched_domains)"
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
                    log_message "Removed $domain and matching entries from whitelist. They will be re-blocked on the next update." && echo "- $domain removed from whitelist."
                else
                    echo "- $domain isn't in whitelist."
                    exit 1
                fi
            fi
        fi
        refresh_blocked_counts
        update_status
        ;;

    --blacklist|-b)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume before running this command."
            exit 1
        fi
        option="$2"
        domain="$3"

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --blacklist <add/remove> <domain>"
            display_blacklist=$(cat "$persist_dir/blacklist.txt" 2>/dev/null)
            [ ! -z "$display_blacklist" ] && echo -e "Current blacklist:\n$display_blacklist" || echo "Current blacklist: no saved blacklist"
        else
            touch "$persist_dir/blacklist.txt"
            if [ "$option" = "add" ]; then
                # Add domain to blacklist.txt and add to hosts if it isn't there
                grep -qx "$domain" "$persist_dir/blacklist.txt" || echo "$domain" >> "$persist_dir/blacklist.txt"
                if grep -q "0\.0\.0\.0 $domain" "$hosts_file"; then
                    echo "- $domain is already blacklisted."
                else
                    # Ensure newline at end before appending
                    [ -s "$hosts_file" ] && tail -c1 "$hosts_file" | grep -qv $'\n' && echo "" >> "$hosts_file"
                    echo "0.0.0.0 $domain" >> "$hosts_file" && echo "- Blacklisted $domain."
                    update_status
                    log_message "Blacklisted $domain."
                fi
            else
                # Remove domain from blacklist.txt if found
                if grep -qxF "$domain" "$persist_dir/blacklist.txt"; then
                    sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/blacklist.txt";
                    log_message "Removed $domain from blacklist."
                    echo "- $domain removed from blacklist."
                else
                    echo "- $domain isn't found in blacklist."
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
        echo "- Missing argument: You must specify 'add' or 'remove'."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi

    if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
        echo "- Invalid option: Use 'add' or 'remove'."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi

    if [ -z "$domain" ]; then
        echo "- Missing domain: You must specify a domain."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi

    touch "$persist_dir/sources.txt"

    if [ "$option" = "add" ]; then
        if grep -qx "$domain" "$persist_dir/sources.txt"; then
            echo "- $domain is already in sources."
        else
            echo "$domain" >> "$persist_dir/sources.txt"
            log_message "Added $domain to sources."
            echo "- Added $domain to sources."
        fi
    else
        if grep -qx "$domain" "$persist_dir/sources.txt"; then
            sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/sources.txt"
            log_message "Removed $domain from sources."
            echo "- Removed $domain from sources."
        else
            log_message "Failed to remove $domain from sources, maybe wasn't even found?."
            echo "- $domain was not even found in sources."
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
                echo "- Invalid option for --auto-update / -a"
                echo "Usage: rmlwk <--auto-update|-a> <enable|disable>"
                ;;
        esac
        ;;

    --update-hosts|-u)
        start_time=$(date +%s)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume before running this command."
            exit 1
        fi
        if [ -d /data/adb/modules/Re-Malwack ]; then
            echo "[UPGRADING ANTI-ADS FORTRESS 🏰]"
            log_message "Updating protections..."
        else
            echo "[BUILDING ANTI-ADS FORTRESS 🏰]"
            log_message "Installing protection for the first time"
        fi
        nuke_if_we_dont_have_internet
        echo "- Downloading hosts..."
        # Re-Malwack general hosts
        # Load sources from the file, ignoring comments
        hosts_list=$(grep -Ev '^#|^$' "$persist_dir/sources.txt" | sort -u)

        # Download hosts in parallel
        for host in $hosts_list; do
            counter="$((counter + 1))"
            fetch "${tmp_hosts}${counter}" "$host" &
        done
        wait

        # Update hosts for custom block
        [ -d "$persist_dir/cache/porn" ] && block_content "porn" "update" &
        [ -d "$persist_dir/cache/gambling" ] && block_content "gambling" "update" &
        [ -d "$persist_dir/cache/fakenews" ] && block_content "fakenews" "update" &
        [ -d "$persist_dir/cache/social" ] && block_content "social" "update" &
        wait

        # Process each downloaded hosts file with host_process
        for i in $(seq 1 $counter); do
            host_process "${tmp_hosts}${i}"
        done

        echo "- Installing hosts"
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        install_hosts "base"

        # Check config and apply update
        [ "$block_porn" = 1 ] && block_content "porn" && log_message "Updating porn sites blocklist..."
        [ "$block_gambling" = 1 ] && block_content "gambling" && log_message "Updating gambling sites blocklist..."
        [ "$block_fakenews" = 1 ] && block_content "fakenews" && log_message "Updating Fake news sites blocklist..."
        [ "$block_social" = 1 ] && block_content "social" && log_message "Updating Social sites blocklist..."
        refresh_blocked_counts
        update_status
        log_message "Successfully updated hosts."
        if [ ! "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ]; then
            echo "- Everything is now Good!"
        fi
        log_duration "update-hosts" "$start_time"
        ;;

    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument] OPTIONAL: [--quiet]"
        echo "--update-hosts, -u: Update the hosts file."
        echo "--auto-update, -a <enable|disable>: Toggle auto hosts update."
        echo "--custom-source, -c <add|remove> <domain>: Add custom hosts source."
        echo "--reset, -r: Restore original hosts file."
        echo "--pause-adblock, -pa: Pauses protection"
        echo "--resume-adblock, -ra: Resumes protection"
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