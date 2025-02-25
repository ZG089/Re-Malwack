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
tmp_hosts="/data/local/tmp/hosts"
# tmp_hosts 0 = original hosts file, to prevent overwrite before cat process complete, ensure coexisting of different block type.
# tmp_hosts 1-9 = downloaded hosts, to simplify process of install and remove function.
LOGFILE="$persist_dir/logs/Re-Malwack_$(date +%Y-%m-%d_%H:%M).log"

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
    log_message "Starting to install hosts."
    # Prepare original hosts
    cp -f "$hosts_file" "${tmp_hosts}0"

    # Prepare blacklist
    log_message "Preparing Blacklist..."
    [ -s "$persist_dir/blacklist.txt" ] && sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$persist_dir/blacklist.txt" | awk '{print "0.0.0.0 " $0}' > "${tmp_hosts}b"

    # Update hosts
    log_message "Updating hosts..."
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/\t/ /g; s/  */ /g' "${tmp_hosts}"[!0] > "$tmp_hosts"
    sort -u "${tmp_hosts}0" "$tmp_hosts" > "$hosts_file"
    
    # Process whitelist
    log_message "Processing Whitelist..."
    social_whitelist="$persist_dir/cache/whitelist/social_whitelist.txt"
    whitelist_file="$persist_dir/cache/whitelist/whitelist.txt"
    [ -s "$persist_dir/whitelist.txt" ] && whitelist_file="$whitelist_file $persist_dir/whitelist.txt"

    # Filter whitelist
    log_message "Filtering Whitelist..."
    if [ "$block_social" -eq 1 ]; then
        log_message "Social Block enable triggered, Whitelist won't be applied"
    else
        whitelist_file="$whitelist_file $social_whitelist"
    fi
    
    # Read and sort whitelist entries from all files
    whitelist=$(cat $whitelist_file | sort -u)
    if [ -n "$whitelist" ]; then
        echo "$whitelist" | sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | awk '{print "0.0.0.0 " $0}' > "${tmp_hosts}w"
        awk 'NR==FNR {seen[$0]=1; next} !seen[$0]' "${tmp_hosts}w" "$hosts_file" > "$tmp_hosts"
        cat "$tmp_hosts" > "$hosts_file"
    fi

    # Clean up
    chmod 644 "$hosts_file"
    log_message "Cleaning up..."
    rm -f "${tmp_hosts}*" 2>/dev/null
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
        # Update config
        sed -i "s/^block_${block_type}=.*/block_${block_type}=1/" /data/adb/Re-Malwack/config.sh

        # Skip install if called from hosts update
        [ "$status" = "update" ] && return 0
        cp -f "${cache_hosts}"* "/data/local/tmp"
        [ "$status" = 0 ] && remove_hosts || install_hosts
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
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || abort "Please check your internet connection and try again."
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

# Check Root
if [ "$(id -u)" -ne 0 ]; then
    abort "Root is required to run this script."
fi

# Main Logic
case "$(tolower "$1")" in
    --reset)
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

    --blacklist)
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

    --custom-source)
        option="$2"
        domain="$3"

        if [ "$option" != "add" ] && [ "$option" != "remove" ] || [ -z "$domain" ]; then
            echo "usage: rmlwk --custom-source <add/remove> <domain>"
            display_custom_sources=$(cat "$persist_dir/custom-source.txt" 2>/dev/null)
            [ ! -z "$display_custom_sources" ] && echo -e "Current custom sources:\n$display_custom_sources" || echo "Current custom sources: no saved custom sources"
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

    --update-hosts)
        log_message "Starting to update hosts..."
        echo "- Downloading updates, Please wait."
        nuke_if_we_dont_have_internet

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

        echo "- Applying update."
        echo "127.0.0.1 localhost\n::1 localhost" > "$hosts_file"
        install_hosts

        # Check config and apply update
        [ "$block_porn" = 1 ] && block_content "porn" && log_message "Updating porn sites blocklist..."
        [ "$block_gambling" = 1 ] && block_content "gambling" && log_message "Updating gambling sites blocklist..."
        [ "$block_fakenews" = 1 ] && block_content "fakenews" && log_message "Updating Fake news sites blocklist..."
        [ "$block_social" = 1 ] && block_content "social" && log_message "Updating Social sites blocklist..."
        update_status
        log_message "Successfully updated hosts."
        echo "- Done."
        ;;

    --help|-h|*)
        echo ""
        echo "Usage: rmlwk [--argument]"
        echo "--reset: Restore original hosts file."
        echo "--block-porn <disable>: Block pornographic sites, use disable to unblock."
        echo "--block-gambling <disable>: Block gambling sites, use disable to unblock."
        echo "--block-fakenews <disable>: Block fake news sites, use disable to unblock."
        echo "--block-social <disable>: Block social media sites, use disable to unblock."
        echo "--whitelist <add/remove> <domain>: Whitelist a domain."
        echo "--blacklist <add/remove> <domain>: Blacklist a domain."
        echo "--update-hosts: Update the hosts file."
        echo "--custom-source <add/remove> <domain>: Add your preferred hosts source."
        echo "--help, -h: Display help."
        echo -e "\033[0;31m Example command: su -c rmlwk --update-hosts\033[0m"
        ;;
esac
