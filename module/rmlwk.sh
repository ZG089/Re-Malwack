#!/system/bin/sh

function malvack_banner() {
    clear
    echo -e "\033[0;31m                                      .--.                            "
    echo -e "\033[0;31m                                   .=*#=                              "
    echo -e "\033[0;31m                                 .+###+                               "
    echo -e "\033[0;31m                                .*#####-                              "
    echo -e "\033[0;31m                               .*##***-**=:                           "
    echo -e "\033[0;31m                             .*###-    .=*##+-.                       "
    echo -e "\033[0;31m                             .-+**        .-=*##+=:                   "
    echo -e "\033[0;31m                   .:.           ::           -*####+-.               "
    echo -e "\033[0;31m                   -*#*+:     -*##+.            .-+####+-.           "
    echo -e "\033[0;31m                     .:*#+***+#*:                  .-+###*           "
    echo -e "\033[0;31m                      :*#######*.                     .:-.           "
    echo -e "\033[0;31m                      +*********-                                     "
    echo -e "\033[0;31m              +#+.   .:::::  ::::    :*#:                             "
    echo -e "\033[0;31m               :+#+==#####* .####*==*#+:                              "
    echo -e "\033[0;31m                 .---##*-: :+####+---.                                "
    echo -e "\033[0;31m                     ##=  :#*+*##=                                    "
    echo -e "\033[0;31m                 .=++###**#+   *#*++-                                 "
    echo -e "\033[0;31m                =##=--####- .-=#*--+#*-                               "
    echo -e "\033[0;31m               =*=.   .+#+ -##*=.   .+*:                              "
    echo -e "\033[0;31m                        .. :-:                                        "
    echo -e "\033[0;37m        ╔────────────────────────────────────────╗"
    echo -e "\033[0;37m        │░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│"
    echo -e "\033[0;37m        │░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│"
    echo -e "\033[0;37m        │░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│"
    echo -e "\033[0;37m        ╚────────────────────────────────────────╝\033[0m"
}

# Variables
persist_dir="/data/adb/Re-Malwack"
MODDIR="${0%/*}"
hosts_file="$MODDIR/system/etc/hosts"
tmp_dir="/data/local/tmp/rmlwk_tmp"
tmp_hosts="$tmp_dir/hosts"
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"

# Create necessary directories
mkdir -p "$persist_dir/logs" "$tmp_dir"

# Read config
. "$persist_dir/config.sh"

# Skip banner if running from Magisk Manager
[ -z "$MAGISKTMP" ] && malvack_banner

# Define a logging function
function log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> $LOGFILE
}

function install_hosts() {
    type="$1"
    log_message "Starting to install $type hosts."
    
    # Prepare original hosts
    cp -f "$hosts_file" "${tmp_hosts}0"
    
    # Process blacklist once
    if [ -s "$persist_dir/blacklist.txt" ]; then
        log_message "Preparing Blacklist..."
        grep -v "^[[:space:]]*#\|^[[:space:]]*$" "$persist_dir/blacklist.txt" | awk '{print "0.0.0.0 " $0}' > "${tmp_hosts}b"
    fi
    
    # Update hosts
    log_message "Updating hosts..."
    grep -v "^[[:space:]]*#\|^[[:space:]]*$" "${tmp_hosts}"[!0] | tr -s ' ' > "$tmp_hosts"
    # Use LC_ALL=C for faster sorting
    LC_ALL=C sort -u "${tmp_hosts}0" "$tmp_hosts" > "$hosts_file"
    
    # Process whitelist
    log_message "Processing Whitelist..."
    social_whitelist="$persist_dir/cache/whitelist/social_whitelist.txt"
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    # Filter whitelist
    if [ "$block_social" -ne 1 ]; then
        whitelist_file="$whitelist_file $social_whitelist"
        log_message "Adding social whitelist"
    else
        log_message "Social Block enabled, Whitelist won't be applied"
    fi
    
    # Process whitelist more efficiently
    if [ -n "$whitelist_file" ]; then
        # Use cat and grep once instead of multiple file reads
        cat $whitelist_file 2>/dev/null | grep -v "^[[:space:]]*#\|^[[:space:]]*$" | sort -u > "${tmp_hosts}w_domains"
        
        if [ -s "${tmp_hosts}w_domains" ]; then
            # Convert domains to hosts format
            awk '{print "0.0.0.0 " $0}' "${tmp_hosts}w_domains" > "${tmp_hosts}w"
            
            # Filtering
            grep -v -F -f "${tmp_hosts}w" "$hosts_file" > "$tmp_hosts.filtered"
            mv "$tmp_hosts.filtered" "$hosts_file"
        fi
    fi

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Successfully installed hosts."
}

function remove_hosts() {
    log_message "Starting to remove hosts."
    # Prepare original hosts
    cp -f "$hosts_file" "${tmp_hosts}0"

    # Arrange cached hosts more efficiently
    grep -v "^[[:space:]]*#\|^[[:space:]]*$" "${cache_hosts}"* | tr -s ' ' | sort -u > "${tmp_hosts}1"

    # Remove from hosts file using grep
    grep -v -F -f "${tmp_hosts}1" "${tmp_hosts}0" > "$hosts_file"

    # Restore to default entries if hosts file is empty
    if [ ! -s "$hosts_file" ]; then
        echo "- Warning: Hosts file is empty. Restoring default entries."
        log_message "Detected empty hosts file"
        log_message "Restoring default entries..."
        printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
    fi

    log_message "Successfully removed hosts."
}

function block_content() {
    local block_type=$1
    local status=$2
    cache_hosts="$persist_dir/cache/$block_type/hosts"
    
    # Create cache directory if it doesn't exist
    mkdir -p "$persist_dir/cache/$block_type"

    if [ "$status" = 0 ] && [ -f "${cache_hosts}1" ]; then
        remove_hosts
        # Update config
        sed -i "s/^block_${block_type}=.*/block_${block_type}=0/" "$persist_dir/config.sh"
    else
        # Download hosts only if no cached host found or during update
        if [ "$status" = "update" ] || [ ! -f "${cache_hosts}1" ]; then
            nuke_if_we_dont_have_internet
            echo "- Downloading hosts for $block_type."
            log_message "Downloading hosts for $block_type."
            
            # Download hosts in background for parallel processing
            fetch "${cache_hosts}1" "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/${block_type}-only/hosts" &
            
            if [ "$block_type" = "porn" ]; then
                fetch "${cache_hosts}2" "https://raw.githubusercontent.com/johnlouie09/Anti-Porn-HOSTS-File/refs/heads/master/HOSTS.txt" &
                fetch "${cache_hosts}3" "https://www.someonewhocares.org/hosts/hosts" &
            fi
            wait
        fi

        # Skip install if called from hosts update
        [ "$status" = "update" ] && return 0
        
        # Update config
        sed -i "s/^block_${block_type}=.*/block_${block_type}=1/" "$persist_dir/config.sh"
        
        # Use symlinks instead of copying files for better performance
        for f in "${cache_hosts}"*; do
            ln -sf "$f" "$tmp_dir/$(basename "$f")"
        done
        
        [ "$status" = 0 ] && remove_hosts || install_hosts "$block_type"
    fi
}

function tolower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

function abort() {
    log_message "Aborting: $1"
    echo -e "- \033[0;31m$1\033[0m"
    exit 1
}

function nuke_if_we_dont_have_internet() {
    ping -c 1 -w 3 1.1.1.1 &>/dev/null || abort "No internet connection detected, Aborting..."
}

# Fetch function with retry and timeout
function fetch() {
    PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    local output_file="$1"
    local url="$2"
    local retries=2
    local timeout=10
    
    # Make directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"

    if command -v curl >/dev/null 2>&1; then
        curl --connect-timeout $timeout -m $timeout -sL -o "$output_file" "$url" && 
            log_message "Downloaded $url" || 
            { 
                # Retry on failure
                for i in $(seq 1 $retries); do
                    log_message "Retry $i downloading $url"
                    curl --connect-timeout $timeout -m $timeout -sL -o "$output_file" "$url" && 
                        { log_message "Successfully downloaded $url on retry $i"; break; } || 
                        { [[ $i -eq $retries ]] && { log_message "Failed to download $url after $retries retries"; return 1; }; }
                    sleep 1
                done
            }
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout=$timeout --tries=$retries --no-check-certificate -q -O "$output_file" "$url" && 
            log_message "Downloaded $url" || 
            { log_message "Failed to download $url with wget"; return 1; }
    else
        log_message "Neither curl nor wget is available."
        abort "No supported download tools (curl/wget) found."
    fi
}

function update_status() {
    if grep -q '0.0.0.0' "$hosts_file"; then
        string="description=Status: Protection is enabled ✅ | Last updated: $(date)"
        status="Protection is enabled ✅ | Last updated: $(date)"
    else
        string="description=Status: Protection is disabled due to reset ❌"
        status="Protection is disabled due to reset ❌"
    fi
    sed -i "s/^description=.*/$string/g" $MODDIR/module.prop
    log_message "$status"
}

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
        echo "✅ Auto-update enabled."
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
        echo "❌ Auto-update disabled."
    fi
}

# Check Root
[ "$(id -u)" -ne 0 ] && abort "Root is required to run this script."

# Main Logic
case "$(tolower "$1")" in
    --reset)
        log_message "Reverting the changes."
        echo "- Reverting the changes..."
        printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        update_status
        log_message "Successfully reverted changes."
        echo "- Successfully reverted changes."
        ;;

    --block-porn|--block-gambling|--block-fakenews|--block-social)
        block_type=${1#--block-}
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

    --whitelist)
        option="$2"
        domain="$3"
        
        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --whitelist <add/remove> <domain>"
            [ -f "$persist_dir/whitelist.txt" ] && echo -e "Current whitelist:\n$(cat "$persist_dir/whitelist.txt")" || echo "Current whitelist: no saved whitelist"
        else
            touch "$persist_dir/whitelist.txt"
            if [ "$option" = "add" ]; then
                # Add domain to whitelist.txt and remove from hosts
                grep -qx "$domain" "$persist_dir/whitelist.txt" && echo "$domain is already whitelisted" || echo "$domain" >> "$persist_dir/whitelist.txt"
                sed -i "/0\.0\.0\.0 $domain/d" "$hosts_file" 2>/dev/null
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

    --blacklist)
        option="$2"
        domain="$3"

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --blacklist <add/remove> <domain>"
            [ -f "$persist_dir/blacklist.txt" ] && echo -e "Current blacklist:\n$(cat "$persist_dir/blacklist.txt")" || echo "Current blacklist: no saved blacklist"
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

    --custom-source)
        option="$2"
        domain="$3"

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --custom-source <add/remove> <domain>"
            [ -f "$persist_dir/custom-source.txt" ] && echo -e "Current custom sources:\n$(cat "$persist_dir/custom-source.txt")" || echo "Current custom sources: no saved custom sources"
        else
            touch "$persist_dir/custom-source.txt"
            if [ "$option" = "add" ]; then
                grep -qx "$domain" "$persist_dir/custom-source.txt" && echo "$domain is already in custom sources" || echo "$domain" >> "$persist_dir/custom-source.txt"
                log_message "Added $domain to custom source."
                echo "- Added $domain to custom source."
            else
                sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/custom-source.txt"
                log_message "Removed $domain from custom source."
                echo "- $domain removed from custom source."
            fi
        fi
        ;;

    --auto-update)
        case "$2" in
            enable)
                enable_cron
                ;;
            disable)
                disable_cron
                ;;
            *)
                echo "❌ Invalid option for --auto-update"
                echo "Usage: rmlwk --auto-update <enable|disable>"
                ;;
        esac
        ;;

    --update-hosts)
        if [ -d /data/adb/modules/Re-Malwack ]; then
            log_message "Starting to update hosts..."
            echo "- Upgrading protection fortress 🏰🛡"
        else
            echo "- Building protection fortress 🏰🛡"   
        fi
        nuke_if_we_dont_have_internet
        
        # Clean temporary directory first
        rm -rf "$tmp_dir"
        mkdir -p "$tmp_dir"

        # Re-Malwack general hosts
        general_hosts="
        https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
        https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt
        https://o0.pages.dev/Pro/hosts.txt
        https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt
        https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileAds.txt
        https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileSpyware.txt
        https://hblock.molinero.dev/hosts
        "

        # Add custom sources if available
        if [ -s "$persist_dir/custom-source.txt" ]; then
            while IFS= read -r line; do
                general_hosts+=("$line")
            done < "$persist_dir/custom-source.txt"
        fi

        # Download hosts in parallel with better tracking
        counter=0
        for host in "${general_hosts[@]}"; do
            counter=$((counter + 1))
            fetch "${tmp_hosts}${counter}" "$host" &
            # Limit concurrent downloads to avoid overwhelming the system
            [ $((counter % 5)) -eq 0 ] && wait
        done
        wait

        # Update hosts for global whitelist
        mkdir -p "$persist_dir/cache/whitelist"
        fetch "$persist_dir/cache/whitelist/whitelist.txt" "https://raw.githubusercontent.com/ZG089/Re-Malwack/main/whitelist.txt" &
        fetch "$persist_dir/cache/whitelist/social_whitelist.txt" "https://raw.githubusercontent.com/ZG089/Re-Malwack/main/social_whitelist.txt" &
        wait

        # Process different content blocks in parallel
        echo "- Training the ad-killer army ⚔"
        # Initialize hosts file with default entries
        printf "127.0.0.1 localhost\n::1 localhost\n" > "$hosts_file"
        
        # Update hosts for custom block types in parallel
        ([ -d "$persist_dir/cache/porn" ] || mkdir -p "$persist_dir/cache/porn") && block_content "porn" "update" &
        ([ -d "$persist_dir/cache/gambling" ] || mkdir -p "$persist_dir/cache/gambling") && block_content "gambling" "update" &
        ([ -d "$persist_dir/cache/fakenews" ] || mkdir -p "$persist_dir/cache/fakenews") && block_content "fakenews" "update" &
        ([ -d "$persist_dir/cache/social" ] || mkdir -p "$persist_dir/cache/social") && block_content "social" "update" &
        wait
        
        # Install base hosts first
        install_hosts "base"

        # Apply block types in parallel based on config
        if [ "$block_porn" = 1 ]; then
            block_content "porn" 1 &
            log_message "Updating porn sites blocklist..."
        fi
        
        if [ "$block_gambling" = 1 ]; then
            block_content "gambling" 1 &
            log_message "Updating gambling sites blocklist..."
        fi
        
        if [ "$block_fakenews" = 1 ]; then
            block_content "fakenews" 1 &
            log_message "Updating Fake news sites blocklist..."
        fi
        
        if [ "$block_social" = 1 ]; then
            block_content "social" 1 &
            log_message "Updating Social sites blocklist..."
        fi
        wait
        
        update_status
        
        # Clean up temporary files
        rm -rf "$tmp_dir"
        
        if [ -d /data/adb/modules/Re-Malwack ]; then
            log_message "Successfully updated hosts."
            echo "- All done!"
        else
            return 0
        fi
        ;;

    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument]"
        echo "--update-hosts: Update the hosts file."
        echo "--auto-update <enable|disable>: Toggle auto hosts update"
        echo "--custom-source <add|remove> <domain>: Add your preferred hosts source."
        echo "--reset: Restore original hosts file."
        echo "--block-porn <disable>: Block pornographic sites, use disable to unblock."
        echo "--block-gambling <disable>: Block gambling sites, use disable to unblock."
        echo "--block-fakenews <disable>: Block fake news sites, use disable to unblock."
        echo "--block-social <disable>: Block social media sites, use disable to unblock."
        echo "--whitelist <add|remove> <domain>: Whitelist a domain."
        echo "--blacklist <add|remove> <domain>: Blacklist a domain."
        echo "--help, -h: Display help."
        echo -e "\033[0;31m Example command: su -c rmlwk --update-hosts\033[0m"
        ;;
esac

# Final cleanup
[ -d "$tmp_dir" ] && rm -rf "$tmp_dir"