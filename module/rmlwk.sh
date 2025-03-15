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
REALPATH=$(readlink -f "$0")
MODDIR=$(dirname "$REALPATH")
hosts_file="$MODDIR/system/etc/hosts"
tmp_hosts="/data/local/tmp/hosts"
# tmp_hosts 0 = original hosts file, to prevent overwrite before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = downloaded hosts, to simplify process of install and remove function.
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H%M%S).log"

mkdir -p "$persist_dir/logs"

# Read config
. "$persist_dir/config.sh"

# Skip banner if running from Magisk Manager
[ -z "$MAGISKTMP" ] && malvack_banner

# Define a logging function
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
    echo "" > "$hosts_file" 

    # Prepare blacklist
    log_message "Preparing Blacklist..."
    [ -s "$persist_dir/blacklist.txt" ] && sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$persist_dir/blacklist.txt" | awk '{print "0.0.0.0 " $0}' > "${tmp_hosts}b"

    # Update hosts
    log_message "Updating hosts..."
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/\t/ /g; s/  */ /g' "${tmp_hosts}"[!0] > "$tmp_hosts"
    sort -u "${tmp_hosts}0" "$tmp_hosts" > "$hosts_file"
    
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

    # Read and merge whitelist properly
    whitelist=""
    for file in $whitelist_file; do
        [ -s "$file" ] && whitelist="$whitelist$(cat "$file")"$'\n'
    done
    whitelist=$(echo "$whitelist" | sort -u)

    # If whitelist is empty, log and skip filtering
    if [ -z "$whitelist" ]; then
        log_message "Whitelist is empty. Skipping whitelist filtering."
    else
        echo "$whitelist" | sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' > "${tmp_hosts}w"

        while IFS= read -r domain; do
            # Escape special characters in domain for sed
            escaped_domain=$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')

            # Remove from hosts file
            sed -i "/^0\.0\.0\.0 $escaped_domain$/d" "$hosts_file"
            log_message "Filtered whitelist: Removed $domain from hosts file."
        done < "${tmp_hosts}w"
    fi


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
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/\t/ /g; s/  */ /g' "${cache_hosts}"* | sort -u > "${tmp_hosts}1"

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
        curl -sL -o "$output_file" "$url" && log_message "Downloaded $url" || { 
            log_message "Failed to download $url with curl"; 
            abort "Failed to download $url"; 
        }
    elif command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -q -O "$output_file" "$url" && log_message "Downloaded $url" || { 
            log_message "Failed to download $url with wget"; 
            abort "Failed to download $url"; 
        }
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
if [ "$(id -u)" -ne 0 ]; then
    abort "Root is required to run this script."
fi

# Main Logic
case "$(tolower "$1")" in
    --reset|-r)
        log_message "Reverting the changes."
        echo "- Reverting the changes..."
        echo "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        chmod 644 "$hosts_file"

        # Reset blocklist values to 0
        sed -i 's/^block_\(.*\)=.*/block_\1=0/' "$persist_dir/config.sh"
        update_status
        log_message "Successfully reverted changes."
	    echo "- Successfully reverted changes."
        ;;

    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs)
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
        echo "❌ Missing argument: You must specify 'add' or 'remove'."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi
    
    if [ "$option" != "add" ] && [ "$option" != "remove" ]; then
        echo "❌ Invalid option: Use 'add' or 'remove'."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi

    if [ -z "$domain" ]; then
        echo "❌ Missing domain: You must specify a domain."
        echo "Usage: rmlwk --custom-source <add/remove> <domain>"
        exit 1
    fi
    
    touch "$persist_dir/custom-source.txt"
    
    if [ "$option" = "add" ]; then
        if grep -qx "$domain" "$persist_dir/custom-source.txt"; then
            echo "ℹ️  $domain is already in custom sources."
        else
            echo "$domain" >> "$persist_dir/custom-source.txt"
            log_message "Added $domain to custom source."
            echo "✅ Added $domain to custom source."
        fi
    else
        if grep -qx "$domain" "$persist_dir/custom-source.txt"; then
            sed -i "/^$(printf '%s' "$domain" | sed 's/[]\/$*.^|[]/\\&/g')$/d" "$persist_dir/custom-source.txt"
            log_message "Removed $domain from custom source."
            echo "✅ Removed $domain from custom source."
        else
            log_message "Failed to remove $domain from custom source."
            echo "❌ $domain was not found in custom sources."
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
                echo "❌ Invalid option for --auto-update / -a"
                echo "Usage: rmlwk <--auto-update|-a> <enable|disable>"
                ;;
        esac
        ;;

    --update-hosts|-u)
        if [ -d /data/adb/modules/Re-Malwack ]; then
            echo "[UPGRADING ANTI-ADS FORTRESS 🏰]"
        else
            echo "[BUILDING ANTI-ADS FORTRESS 🏰]"
        fi 
        nuke_if_we_dont_have_internet
        echo "- Downloading base hosts."
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

        # custom source
        if [ -s "$persist_dir/custom-source.txt" ]; then
            custom_hosts=$(cat "$persist_dir/custom-source.txt")
        else
            custom_hosts=""
        fi

        # Download hosts in parallel
        hosts_list=$(echo "$general_hosts $custom_hosts" | sort -u)
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
        echo "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        install_hosts "base"

        # Check config and apply update
        [ "$block_porn" = 1 ] && block_content "porn" && log_message "Updating porn sites blocklist..."
        [ "$block_gambling" = 1 ] && block_content "gambling" && log_message "Updating gambling sites blocklist..."
        [ "$block_fakenews" = 1 ] && block_content "fakenews" && log_message "Updating Fake news sites blocklist..."
        [ "$block_social" = 1 ] && block_content "social" && log_message "Updating Social sites blocklist..."
        update_status
        if [ ! -d /data/adb/modules_update/Re-Malwack ]; then # If the script is NOT running in root manager (during updating)
            log_message "Successfully updated hosts."
            echo "- Everything is now Good!"
        else
            log_message "Successfully updated hosts."
        fi
        ;;

    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument]"
        echo "--update-hosts, -u: Update the hosts file."
        echo "--auto-update, -a <enable|disable>: Toggle auto hosts update."
        echo "--custom-source, -c <add|remove> <domain>: Add custom hosts source."
        echo "--reset, -r: Restore original hosts file."
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
