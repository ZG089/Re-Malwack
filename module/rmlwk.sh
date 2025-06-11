#!/system/bin/sh

function rmlwk_banner() {
    clear

    banner1=$(cat <<'EOF'
\033[38;2;255;120;120m     ..      ...                             ...     ..      ..                       ..                                                ..      
\033[38;2;255;80;80m  :~"8888x :"%888x                         x*8888x.:*8888: -"888:               x .d88"    x=~                                    < .z@8"`      
\033[38;2;255;40;40m 8    8888Xf  8888>                       X   48888X `8888H  8888                5888R    88x.   .e.   .e.                         !@88E        
\033[38;2;255;0;0m X88x. ?8888k  8888X       .u             X8x.  8888X  8888X  !888>        u      '888R   '8888X.x888:.x888        u           .    '888E   u    
\033[38;2;235;0;0m '8888L'8888X  '%88X    ud8888.           X8888 X8888  88888   "*8%-    us888u.    888R    `8888  888X '888k    us888u.   .udR88N    888E u@8NL  
\033[38;2;210;0;0m  "888X 8888X:xnHH(`` :888'8888.          '*888!X8888> X8888  xH8>   .@88 "8888"   888R     X888  888X  888X .@88 "8888" <888'888k   888E`"88*"  
\033[38;2;180;0;0m    ?8~ 8888X X8888   d888 '88%"            `?8 `8888  X888X X888>   9888  9888    888R     X888  888X  888X 9888  9888  9888 'Y"    888E .dN.   
\033[38;2;150;0;0m  -~`   8888> X8888   8888.+"               -^  '888"  X888  8888>   9888  9888    888R     X888  888X  888X 9888  9888  9888        888E~8888   
\033[38;2;120;0;0m  :H8x  8888  X8888   8888L                    dx '88~x. !88~  8888>   9888  9888    888R    .X888  888X. 888~ 9888  9888  9888        888E '888&  
\033[38;2;100;0;0m  8888> 888~  X8888   '8888c. .+             .8888Xf.888x:!    X888X.: 9888  9888   .888B .  `%88%``"*888Y"    9888  9888  ?8888u../   888E  9888. 
\033[38;2;80;0;0m  48"` '8*~   `8888!`  "88888%            :""888":~"888"     `888*"  "888*""888"  ^*888%     `~     `"       "888*""888"  "8888P'  '"888*" 4888" 
\033[38;2;60;0;0m  ^-==""      `""       "YP'                 "~'    "~        ""     ^Y"   ^Y'     "%                        ^Y"   ^Y'     "P'       ""    ""   
EOF
)
    banner2=$(cat <<'EOF'
\033[38;2;255;102;102m:::::::..  .,::::::   .        :    :::.      ::: .::    .   .::::::.       .,-:::::  :::  .   
\033[38;2;255;51;51m;;;;``;;;; ;;;;''''   ;;,.    ;;;   ;;`;;     ;;; ';;,  ;;  ;;;' ;;`;;    ,;;;'````'  ;;; .;;,.
\033[38;2;204;0;0m[[[,/[[['  [[cccc    [[[[, ,[[[[, ,[[ '[[,   [[[  '[[, [[, [[' ,[[ '[[,  [[[         [[[[[/'  
\033[38;2;153;0;0m$$$$$$c    $$""""cccc$$$$$$$$"$$$c$$$cc$$$c  $$'    Y$c$$$c$P c$$$cc$$$c $$$        _$$$$,    
\033[38;2;102;0;0m888b "88bo,888oo,__  888 Y88" 888o888   888,o88oo,.__"88"888   888   888,`88bo,__,o,"888"88o, 
\033[38;2;51;0;0mMMMM   "W" """"YUMMM MMM  M'  "MMMYMM   ""` """"YUMMM "M "M"   YMM   ""`   "YUMMMMMP"MMM "MMP"
EOF
)
    banner3=$(cat <<'EOF'
\033[0;31m    ____             __  ___      __                    __            
   / __ \___        /  |/  /___ _/ /      ______ ______/ /__          
  / /_/ / _ \______/ /|_/ / __ `/ / | /| / / __ `/ ___/ //_/       
 / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<             
/_/ |_|\___/     /_/  /_/\__,_/_/ |__/|__/\__,_/\___/_/|_|           
 
EOF
)
    banner4=$(cat <<'EOF'
\033[0;31m ______     ______     __    __     ______     __         __     __     ______     ______     __  __    
/\  == \   /\  ___\   /\ "-./  \   /\  __ \   /\ \       /\ \  _ \ \   /\  __ \   /\  ___\   /\ \/ /    
\ \  __<   \ \  __\   \ \ \-./\ \  \ \  __ \  \ \ \____  \ \ \/ ".\ \  \ \  __ \  \ \ \____  \ \  _"-.  
 \ \_\ \_\  \ \_____\  \ \_\ \ \_\  \ \_\ \_\  \ \_____\  \ \__/".~\_\  \ \_\ \_\  \ \_____\  \ \_\ \_\ 
 \/_/ /_/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_/   \/_/   \/_/\/_/   \/_____/   \/_/\/_/ 
EOF
)
    banner5=$(cat <<'EOF'
\033[38;2;255;102;102m ██▀███  ▓█████  ███▄ ▄███▓ ▄▄▄       ██▓     █     █░ ▄▄▄       ▄████▄   ██ ▄█▀
\033[38;2;255;51;51m▓██ ▒ ██▒▓█   ▀ ▓██▒▀█▀ ██▒▒████▄    ▓██▒    ▓█░ █ ░█░▒████▄    ▒██▀ ▀█   ██▄█▒ 
\033[38;2;204;0;0m▓██ ░▄█ ▒▒███   ▓██    ▓██░▒██  ▀█▄  ▒██░    ▒█░ █ ░█ ▒██  ▀█▄  ▒▓█    ▄ ▓███▄░ 
\033[38;2;153;0;0m▒██▀▀█▄  ▒▓█  ▄ ▒██    ▒██ ░██▄▄▄▄██ ▒██░    ░█░ █ ░█ ░██▄▄▄▄██ ▒▓▓▄ ▄██▒▓██ █▄ 
\033[38;2;102;0;0m░██▓ ▒██▒░▒████▒▒██▒   ░██▒ ▓█   ▓██▒░██████▒░░██▒██▓  ▓█   ▓██▒▒ ▓███▀ ░▒██▒ █▄
\033[38;2;51;0;0m░ ▒▓ ░▒▓░░░ ▒░ ░░ ▒░   ░  ░ ▒▒   ▓▒█░░ ▒░▓  ░░ ▓░▒ ▒   ▒▒   ▓▒█░░ ░▒ ▒  ░▒ ▒▒ ▓▒
\033[38;2;0;0;0m  ░▒ ░ ▒░ ░ ░  ░░  ░      ░  ▒   ▒▒ ░░ ░ ▒  ░  ▒ ░ ░    ▒   ▒▒ ░  ░  ▒   ░ ░▒ ▒░
\033[38;2;0;0;0m  ░░   ░    ░   ░      ░     ░   ▒     ░ ░     ░   ░    ░   ▒   ░        ░ ░░ ░ 
\033[38;2;0;0;0m   ░        ░  ░       ░         ░  ░    ░  ░    ░          ░  ░░ ░      ░  ░   
\033[38;2;0;0;0m                                                                ░               
EOF
)
    banner6=$(cat <<'EOF'
\033[0;31m██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝
██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ 
██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ 
██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗
╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
)

    if command -v shuf >/dev/null 2>&1; then
        random_index=$(shuf -i 1-6 -n 1)
    else
        random_index=$(( ($(date +%s) % 6) + 1 ))
    fi

    case $random_index in
        1) echo -e "$banner1" ;;
        2) echo -e "$banner2" ;;
        3) echo -e "$banner3" ;;
        4) echo -e "$banner4" ;;
        5) echo -e "$banner5" ;;
        6) echo -e "$banner6" ;;
    esac
    
    printf '\033[0m'
    update_status
    echo " "
    echo "$version - $status_msg"
    printf '\033[0;31m'
    echo "================================================================="
    printf '\033[0m'
}

# Variables
persist_dir="/data/adb/Re-Malwack"
REALPATH=$(readlink -f "$0")
MODDIR=$(dirname "$REALPATH")
hosts_file="$MODDIR/system/etc/hosts"
system_hosts="/system/etc/hosts"
tmp_hosts="/data/local/tmp/hosts"
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
# tmp_hosts 0 = original hosts file, to prevent overwrite before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = downloaded hosts, to simplify process of install and remove function.
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"

mkdir -p "$persist_dir/logs"

# Read config
. "$persist_dir/config.sh"


# Functions for pause and resume ad-block
function pause_adblock() {
    if [ -f "$persist_dir/hosts.bak" ]; then
        echo "protection is already paused!"
        exit
    fi     
    log_message "Pausing Protections"
    echo "- Pausing Protections"
    cat $hosts_file > "$persist_dir/hosts.bak"
    printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
    chmod 644 "$hosts_file"
    update_status
    log_message "Protection has been paused."
    echo "- Protection has been paused."
}

function resume_adblock() {
    log_message "Resuming protection."
    echo "- Resuming protection"
    if [ -f "$persist_dir/hosts.bak" ]; then
        cat "$persist_dir/hosts.bak" > "$hosts_file"
        chmod 644 "$hosts_file"
        rm -f $persist_dir/hosts.bak
        update_status
        log_message "Protection has been resumed."
        echo "- Protection has been resumed."
    else
        log_message "No backup hosts file found to resume."
        echo "- No backup hosts file found to resume."
    fi
}

# New function to check if hosts.bak exists
function is_adblock_paused() {
    if [ -f "$persist_dir/hosts.bak" ]; then
        return 0
    else
        return 1
    fi
}

# Logging func
function log_message() {
    local message="$1"
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> $LOGFILE
}

function install_hosts() {
    type="$1"
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
    echo "# Re-Malwack $version" >> "$hosts_file"


    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}"* 2>/dev/null
    log_message "Successfully installed hosts."
}

function remove_hosts() {
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
}

function block_content() {
    local block_type=$1
    local status=$2
    cache_hosts="$persist_dir/cache/$block_type/hosts"

    if [ "$status" = 0 ] && [ -f "${cache_hosts}1" ]; then
        remove_hosts
        # Update config
        sed -i "s/^block_${block_type}=.*/block_${block_type}=0/" /data/adb/Re-Malwack/config.sh
    else
        # Download hosts only if no cached host found or during update
        nuke_if_we_dont_have_internet
        if [ ! -f "${cache_hosts}1" ] || [ "$status" = "update" ]; then
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
}

function tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

function abort() {
    log_message "Aborting: $1"
    echo -e "- \033[0;31m$1\033[0m"
    sleep 0.5
    exit 1
}

function nuke_if_we_dont_have_internet() {
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || abort "No internet connection detected, Aborting..."
}

# Fallback to busybox wget if curl binary is not available
function fetch() {
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local output_file="$1"
    local url="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -Ls "$url" > "$output_file" || { 
            log_message "Failed to download $url with curl"
            abort "Failed to download $url"
        }
        echo "" >> "$output_file"
    else
        busybox wget --no-check-certificate -qO - "$url" > "$output_file" || { 
            log_message "Failed to download $url with wget"
            abort "Failed to download $url"
        }
        echo "" >> "$output_file"
    fi
    log_message "Downloaded $url, stored in $output_file"
}

function update_status() {
    log_message "Fetching last hosts file update"
    last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1)
    log_message "Last hosts file update was in: $last_mod"
    if [ -f "$system_hosts" ]; then
        log_message "Grabbing system hosts file entries count"
        blocked_sys=$(grep -m 1 -q '0\.0\.0\.0' "$system_hosts" && awk '/^0\.0\.0\.0[[:space:]]/ {c++} END{print c+0}' "$system_hosts" 2>/dev/null)
    else
        blocked_sys=0
    fi
    log_message "System hosts entries count: $blocked_sys"
    if [ -f "$hosts_file" ]; then
        log_message "Grabbing module hosts file entries count"
        blocked_mod=$(grep -m 1 -q '0\.0\.0\.0' "$hosts_file" && awk '/^0\.0\.0\.0[[:space:]]/ {c++} END{print c+0}' "$hosts_file" 2>/dev/null)
    else
        blocked_mod=0
    fi
    log_message "module hosts entries count: $blocked_mod"
        if is_adblock_paused && [ "$blocked_mod" -gt 0 ]; then
            status_msg="Status: Ad-block is paused ⏸️"
        elif [ "$blocked_mod" -gt 10 ]; then
            if [ "$blocked_mod" -ne "$blocked_sys" ]; then
                status_msg="Status: Reboot required to apply changes 🔃 | Module blocks $blocked_mod domains, system hosts blocks $blocked_sys."
            else
                status_msg="Status: Protection is enabled ✅ | Blocking $blocked_mod domains | Last updated: $last_mod"
            fi
        elif [ -d /data/adb/modules_update/Re-Malwack ]; then
            status_msg="Status: Reboot required to apply changes 🔃 (pending module update)"
        else
            status_msg="Status: Protection is disabled due to reset ❌"
        fi

    sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
    log_message "$status_msg"
}


# Enable cron job for auto-update
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
        busybox crontab "$JOB_FILE" -c "$JOB_DIR"
        log_message "Cron job added."
        crond -c $JOB_DIR -L $persist_dir/logs/auto_update.log
        sed -i 's/^daily_update=.*/daily_update=1/' "/data/adb/Re-Malwack/config.sh"
        log_message "Auto-update has been enabled."
        echo "- Auto-update enabled."
    fi
}

# Function to disable auto-update
function disable_cron() {
    JOB_DIR="/data/adb/Re-Malwack/auto_update"
    JOB_FILE="$JOB_DIR/root"
    CRON_JOB="0 */12 * * * sh /data/adb/modules/Re-Malwack/rmlwk.sh --update-hosts && echo \"[$(date '+%Y-%m-%d %H:%M:%S')] - Running auto update.\" >> /data/adb/Re-Malwack/logs/auto_update.log"
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
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


# Skip banner if running from Magisk Manager
[ -z "$MAGISKTMP" ] && rmlwk_banner


# Main Logic
case "$(tolower "$1")" in
    --pause-adblock|-pa)
        pause_adblock
        ;;
    --resume-adblock|-ra)
        resume_adblock
        ;;
    --reset|-r)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume before running this command."
            exit 1
        fi
        log_message "Reverting the changes."
        echo "- Reverting the changes..."
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        update_status
        log_message "Successfully reverted changes."
	    echo "- Successfully reverted changes."
        ;;

    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs)
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
                echo "- Removing block entries for ${block_type} sites."
                block_content "$block_type" 0
                log_message "Unblocked ${block_type} sites successfully." && echo "- Unblocked ${block_type} sites successfully."
            fi
        else
            if [ "$block_toggle" = 1 ]; then
                echo "- $block_type block is already enabled"
            else
                echo "- Adding block entries for ${block_type} sites."
                block_content "$block_type" 1
                log_message "Blocked ${block_type} sites successfully." && echo "- Blocked ${block_type} sites successfully."
            fi
        fi
        update_status
        ;;

    --whitelist|-w)
        if is_adblock_paused; then
            echo "- Ad-block is paused. Please resume it before running this command."
            exit 1
        fi
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
            log_message "Failed to remove $domain from sources."
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

        # Update hosts for global whitelist
        mkdir -p "$persist_dir/cache/whitelist"
        fetch "$persist_dir/cache/whitelist/whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt
        fetch "$persist_dir/cache/whitelist/social_whitelist.txt" https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt

        # Update hosts for custom block
        [ -d "$persist_dir/cache/porn" ] && block_content "porn" "update" &
        [ -d "$persist_dir/cache/gambling" ] && block_content "gambling" "update" &
        [ -d "$persist_dir/cache/fakenews" ] && block_content "fakenews" "update" &
        [ -d "$persist_dir/cache/social" ] && block_content "social" "update" &
        wait

        echo "- Installing hosts"
        printf "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        install_hosts "base"

        # Check config and apply update
        [ "$block_porn" = 1 ] && block_content "porn" && log_message "Updating porn sites blocklist..."
        [ "$block_gambling" = 1 ] && block_content "gambling" && log_message "Updating gambling sites blocklist..."
        [ "$block_fakenews" = 1 ] && block_content "fakenews" && log_message "Updating Fake news sites blocklist..."
        [ "$block_social" = 1 ] && block_content "social" && log_message "Updating Social sites blocklist..."
        update_status
        log_message "Successfully updated hosts."
        if [ ! "$MODDIR" = "/data/adb/modules_update/Re-Malwack" ]; then
            echo "- Everything is now Good!"
        fi
        ;;

    
    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument]"
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