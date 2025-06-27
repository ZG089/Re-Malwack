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
mkdir -p $persist_dir/logs $persist_dir/counts $persist_dir/cache/whitelist

# we need to change PATH in order to achieve some stuff.
# this will get overritten after a new login.
export PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH 

# ====== Functions ======
function rmlwk_banner() {
    # Skip banner if quiet mode is enabled
    [ "$quiet_mode" -eq 1 ] && return 0
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
    printf "\033c"
    case "$((($(date +%s) % 2) + 1))" in
        1)
            for seq in $(seq 0 59); do
                printf "#"
            done
            echo -e "\n\n$banner1"
        ;;
        2)
            for seq in $(seq 0 83); do
                printf "#"
            done
            echo -e "\n\n$banner2"
        ;;
    esac
    printf '\033[0m'
    update_status
    #echo "$version - $status_msg"
    printf '\033[0;31m'
    for seqq in $(seq 0 $seq); do
        printf "#"
    done
    printf '\n\033[0m'
}

# Function to check hosts file reset state
is_default_hosts() {
    grep -qvE '^#|^$' "$1" || return 1
    grep -qvE '^127\.0\.0\.1 localhost$|^::1 localhost$' "$1" && return 1
    return 0
}

# Function to count blocked entries and store them
refresh_blocked_counts() {
    blocked_mod=$(grep -c '^0\.0\.0\.0[[:space:]]' "$hosts_file" 2>/dev/null)
    blocked_sys=$(grep -c '^0\.0\.0\.0[[:space:]]' "$system_hosts" 2>/dev/null)
    #
    echo "${blocked_mod:-0}" > "$persist_dir/counts/blocked_mod.count"
    echo "${blocked_sys:-0}" > "$persist_dir/counts/blocked_sys.count"
}

# 1 - Pause adblock
function pause_adblock() {
    # Check if protection is already paused
    is_adblock_paused && abort "Protection is already passed."
    # Check if hosts file is reset
    is_default_hosts "$hosts_file" && abort "You cannot pause Ad-block while hosts is reset" 
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
    [[ -f "$persist_dir/hosts.bak" && "adblock_switch" -eq 1 ]]
}

# Logging func - Literally helpful for any dev :D no it's not.
function log_message() {
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" >> $LOGFILE
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
    log_message "Updating hosts..."
    sed '/#/d; /!/d; s/[[:space:]]\+/ /g; /^$/d; s/\r$//; /^127\.0\.0\.1[ \t]*localhost$/! s/^127\.0\.0\.1[ \t]*/0.0.0.0 /' "${tmp_hosts}"[!0] |
    sort -u - "${tmp_hosts}0" |
    grep -Fxvf "${tmp_hosts}w" > "$hosts_file"
    echo "# Re-Malwack $version" >> "$hosts_file" # i need explaination buddy.

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

    # Arrange cached hosts
    sed '/#/d; /^$/d; s/^[[:space:]]*//; s/\t/ /g; s/  */ /g' "${cache_hosts}"* | sort -u > "${tmp_hosts}1"

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
        if [ ! -f "${cache_hosts}1" ]; then
            echo "- Warning: Cached blocklist for '$block_type' not found!"
            echo "- Re-downloading the blocklist to proceed with disabling."
            echo "- Please do not modify or delete /data/adb/Re-Malwack directory files."
            echo " - If you think a cleaner app accidentally removed one of the files, Please add the directory to the exceptions list."
            log_message "Missing cached blocklist for $block_type — auto-redownloading."
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
            echo "- Downloading hosts for $block_type."
            log_message "Downloading hosts for $block_type."
            fetch "${cache_hosts}1" https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt & 
                fetch "${cache_hosts}3" https://www.someonewhocares.org/hosts/hosts &
                wait
            fi
        fi

        # Skip install if called from hosts update
        [ "$status" = "update" ] && return 0
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
    echo -e "- \033[0;31m$1\033[0m"
    sleep 0.5
    exit 1
}

# Bruh It's clear already what this function does ._. yeah so what? i was a bit dumb and came up with this dumb ahh idea to name a function.
function nuke_if_we_dont_have_internet() {
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || abort "No internet connection detected, Aborting..."
}

# Fetches hosts from sources.txt
# Don't be concerned from these filenames when checking cached files during hosts downloading/processing
# tmp_hosts 0 = This is the original hosts file, to prevent overwriting before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = This is the downloaded hosts, to simplify process of install and remove function.
function fetch() {
    local output_file="$1"
    local url="$2"

    # Curly hairyyy- *ahem* bruh what???? you deadahh fr?? =
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
    log_message "Downloaded $url, stored in $output_file"
}

# Updates module status, modifying module description in module.prop
function update_status() {
    start_time=$(date +%s)
    log_message "Fetching last hosts file update"
    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1) # Checks last modification date for hosts file
    log_message "Last hosts file update was in: $last_mod"

    # System hosts count
    if [ ! -d "/data/adb/modules/Re-Malwack" ]; then
        blocked_sys=0
        log_message "First install detected (module directory missing)."
    elif is_default_hosts "$system_hosts"; then
        blocked_sys=0
        log_message "System hosts file has default entries only."
    else
        blocked_sys=$(cat "$persist_dir/counts/blocked_sys.count" 2>/dev/null)
        blocked_sys=${blocked_sys:-0}
    fi
    log_message "System hosts entries count: $blocked_sys"

    # Module hosts count
    if is_default_hosts "$hosts_file"; then
        blocked_mod=0
        log_message "Module hosts file seems to be reset."
    else
        blocked_mod=$(cat "$persist_dir/counts/blocked_mod.count" 2>/dev/null)
        blocked_mod=${blocked_mod:-0}
    fi
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
    elif is_default_hosts "$system_hosts" && is_default_hosts "$hosts_file"; then
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

# are we deadahh? like fr? why we need to check the dependencies everytime when we need to access it? it feels dumb bro
for requiredDependencies in curl shuf; do
    command -v $requiredDependencies &>/dev/null || abort "Missing dependencies. Please install curl and shuf to proceed."
done

# and i wonder......
[ "$(tolower "$1")" == "--reset|-r|--block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs|--whitelist|-w|--blacklist|-b|--update-hosts|-u" ] && is_adblock_paused && abort "- Ad-block is paused. Please resume before running this command."

# ====== Main Logic ======
case "$(tolower "$1")" in
    --pause-adblock|-pa)
        start_time=$(date +%s)
        pause_adblock
        log_duration "pause_adblock" "$start_time"
        ;;
    --resume-adblock|-ra)
        start_time=$(date +%s)
        resume_adblock
        log_duration "resume_adblock" "$start_time"
        ;;
    --reset|-r)
        start_time=$(date +%s)
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
        option="$2"
        domain="$3"
        
        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --whitelist <add/remove> <domain>"
            display_whitelist=$(cat "$persist_dir/whitelist.txt" 2>/dev/null)
            [ ! -z "$display_whitelist" ] && echo -e "Current whitelist:\n$display_whitelist" || echo "Current whitelist: no saved whitelist"
        else
            touch "$persist_dir/whitelist.txt"
            if [ "$option" = "add" ]; then
                # Add domain to whitelist.txt and remove from hosts
                grep -qx "$domain" "$persist_dir/whitelist.txt" && echo "$domain is already whitelisted" || echo "$domain" >> "$persist_dir/whitelist.txt"
                sed "/0\.0\.0\.0 $domain/d" "$hosts_file" > "$tmp_hosts"
                cat "$tmp_hosts" > "$hosts_file"
                rm -f "$tmp_hosts"
                log_message "Added $domain to whitelist." && echo "- Added $domain to whitelist."
            else
                # Remove domain from whitelist.txt if found
                if grep -qxF "$domain" "$persist_dir/whitelist.txt"; then
                    sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/whitelist.txt";
                    log_message "Removed $domain from whitelist." && echo "- $domain removed from whitelist."
                else
                    echo "- $domain isn't in whitelist."
                fi
            fi
        fi
        refresh_blocked_counts
        update_status
        ;;

    --blacklist|-b)
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
        abort "Usage: rmlwk --custom-source <add/remove> <domain>"
    fi
    
    if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
        echo "- Invalid option: Use 'add' or 'remove'."
        abort "Usage: rmlwk --custom-source <add/remove> <domain>"
    fi

    if [ -z "$domain" ]; then
        echo "- Missing domain: You must specify a domain."
        abort "Usage: rmlwk --custom-source <add/remove> <domain>"
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
        if [ -d /data/adb/modules/Re-Malwack ]; then
            echo "Updating hosts..."
            log_message "Updating protections..."
        else
            echo "Installing necessory stuff for the first time setup..."
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
            fetch "${tmp_hosts}${counter}" "$host"
        done

        # Update hosts for custom block
        [ -d "$persist_dir/cache/porn" ] && block_content "porn" "update"
        [ -d "$persist_dir/cache/gambling" ] && block_content "gambling" "update"
        [ -d "$persist_dir/cache/fakenews" ] && block_content "fakenews" "update"
        [ -d "$persist_dir/cache/social" ] && block_content "social" "update" 

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
        [ "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ] || echo "- Everything is now Good!"
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
