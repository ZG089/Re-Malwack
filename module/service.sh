#!/system/bin/sh
# This is the service script of Re-Malwack
# It is executed during device boot

# =========== Variables ===========
MODDIR="${0%/*}"
persist_dir="/data/adb/Re-Malwack"
zn_module_dir="/data/adb/modules/hostsredirect"
system_hosts="/system/etc/hosts"
is_zn_detected=0
FALLBACK_SCRIPT="$persist_dir/auto_update_fallback.sh"
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
JOB_DIR="$persist_dir/auto_update"
JOB_FILE="$JOB_DIR/root"
LOGFILE="$persist_dir/logs/service.log"
rmlwkExec=true

# =========== Functions ===========
# Load Re-Malwack core functions
. "$MODDIR/rmlwk_functions.sh"

# Detect cron provider
detect_cron_provider() {
    if command -v busybox >/dev/null 2>&1 && busybox crond --help >/dev/null 2>&1; then
        echo busybox
    elif command -v toybox >/dev/null 2>&1 && toybox crond --help >/dev/null 2>&1; then
        echo toybox
    else
        return 1
    fi
}

# Helper function for applets usage
cron_cmd() {
    case "$CRON_PROVIDER" in
        busybox) echo "busybox $1" ;;
        toybox)  echo "toybox $1" ;;
    esac
}

#  =========== Preparation ===========

# 1 - Sourcing config file
. $persist_dir/config.sh

# 2 - creating logs dir in case if not created
mkdir -p "$persist_dir/logs"
# 3 - Remove previous logs (preserve dns.log, Zygisk companion may already have it open)
find "$persist_dir/logs" -maxdepth 1 -type f ! -name 'dns.log' -delete 2>/dev/null

# 4 - Log errors
exec 2>>"$persist_dir/logs/service.log"

# 4.1 - Log module version and service start
version=$(grep '^version=' "$MODDIR/module.prop" | cut -d= -f2-)
log_message INFO "service.sh Started"
log_message INFO "Re-Malwack Version: $version"

# 5 - Check if zygisk host redirect module is enabled
if [ -d "$zn_module_dir" ] && [ ! -f "$zn_module_dir/disable" ] && [ ! -f "$zn_module_dir/remove" ]; then
    is_zn_detected=1
    hosts_file="/data/adb/hostsredirect/hosts"
    log_message INFO "Zygisk host redirect module detected, using /data/adb/hostsredirect/hosts as target hosts file"
else
    hosts_file="$MODDIR/system/etc/hosts"
    log_message INFO "Using standard mount method with $MODDIR/system/etc/hosts"
fi

# 5.1 - Determine mode based on zn-hostsredirect detection
if [ "$is_zn_detected" -eq 1 ]; then
    mode="hosts mount mode: zn-hostsredirect"
else
    mode="hosts mount mode: Standard mount"
fi

# 6 - Module status determination preparations
mount_failed=0
remount_hosts || mount_failed=1
mkdir -p "$persist_dir/counts"
refresh_blocked_counts
last_mod=$(stat -c '%y' "$hosts_file" 2>/dev/null | cut -d'.' -f1)
log_message INFO "System hosts entries count: $blocked_sys"
log_message INFO "Module hosts entries count: $blocked_mod"
[ -s "$persist_dir/custom_rules.txt" ] && custom_entries=$(wc -l < "$persist_dir/custom_rules.txt") || custom_entries=0
log_message INFO "Custom rules entries count: $custom_entries"
[ -s "$persist_dir/blacklist.txt" ] && blacklist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/blacklist.txt") || blacklist_count=0
log_message INFO "Blacklist entries count: $blacklist_count"
[ -s "$persist_dir/whitelist.txt" ] && whitelist_count=$(grep -c '^[^#[:space:]]' "$persist_dir/whitelist.txt") || whitelist_count=0
log_message INFO "Whitelist entries count: $whitelist_count"
if [ -f "$persist_dir/counts/sources.counts" ]; then
    while IFS="|" read -r src count; do
        if [ -n "$src" ] && [ -n "$count" ]; then
            log_message INFO "Host source $src has $count entries"
        fi
    done < "$persist_dir/counts/sources.counts"
fi

identify_enabled_blocklists

if [ -f "$persist_dir/counts/blocklists.counts" ]; then
    while IFS="|" read -r bl count; do
        if [ -n "$bl" ] && [ -n "$count" ]; then
            log_message INFO "Blocklist $bl has $count entries"
        fi
    done < "$persist_dir/counts/blocklists.counts"
fi

# =========== Main script logic ===========

# symlink rmlwk to manager path
if [ "$KSU" = "true" ]; then
    log_message INFO "Root manager: KernelSU"
    [ -L "/data/adb/ksu/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ksu/bin/rmlwk" && log_message SUCCESS "symlink created at /data/adb/ksu/bin/rmlwk"
elif [ "$APATCH" = "true" ]; then
    log_message INFO "Root manager: APatch"
    [ -L "/data/adb/ap/bin/rmlwk" ] || ln -sf "$MODDIR/rmlwk.sh" "/data/adb/ap/bin/rmlwk" && log_message SUCCESS "symlink created at /data/adb/ap/bin/rmlwk"
else
    log_message INFO "Root manager: Magisk"
    [ -w /sbin ] && magisktmp=/sbin
    [ -w /debug_ramdisk ] && magisktmp=/debug_ramdisk
    ln -sf "$MODDIR/rmlwk.sh" "$magisktmp/rmlwk" && log_message SUCCESS "symlink created at $magisktmp/rmlwk"
fi

if [ "$dns_logging" = "1" ]; then
    # Ensure log file exists with proper permissions before Zygisk hooks init
    touch "$persist_dir/logs/dns.log"
    chmod 0666 "$persist_dir/logs/dns.log"
    log_message SUCCESS "DNS logger initialized successfully."
else
    [ -f "$persist_dir/logs/dns.log" ] && rm -f "$persist_dir/logs/dns.log" 2>/dev/null
fi

# Here goes the part where we actually determine module status
rm -f "$persist_dir/reboot_required"
if [ -f "$persist_dir/mode_ready" ] && [ "$blocked_mod" -gt 0 ]; then
    # Clear mode_ready flag if hosts file has blocked entries
    rm -f "$persist_dir/mode_ready"
    log_message INFO "Cleared mode_ready flag, hosts file has $blocked_mod blocked entries"
fi

if [ "$mount_failed" -eq 1 ]; then
    status_msg="Status: ❌ Critical Error Detected (Hosts Mount Failure). Please check your root manager settings and disable any conflicted module(s)."
else
    [ -z "$profile" ] && profile="default"
    capitalized_profile="$(echo "$profile" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
    if [ "$dns_logging" = "1" ]; then
        if [ -f "$persist_dir/counts/dns.count" ]; then
            dns_count=$(cat "$persist_dir/counts/dns.count" 2>/dev/null)
            [ -z "$dns_count" ] && dns_count="0"
            dns_status=" | 🔍 DNS Logging: ON ($dns_count blocked)"
        else
            dns_status=" | 🔍 DNS Logging: ON"
        fi
    else
        dns_status=""
    fi

    if [ -f "$persist_dir/mode_ready" ]; then
        status_msg="Status: Protection is idle 💤 (Awaiting hosts update) | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif is_protection_paused; then
        status_msg="Status: Protection is paused ⏸️ | ⚙️ Profile: $capitalized_profile${dns_status}"
    elif is_default_hosts; then
        if [ "$blacklist_count" -gt 0 ]; then
            plural="entries are active"
            [ "$blacklist_count" -eq 1 ] && plural="entry is active"
            status_msg="Status: Protection is reset ❌ | Only $blacklist_count blacklist $plural | ⚙️ Profile: $capitalized_profile${dns_status}"
        else
            status_msg="Status: Protection is reset ❌ | ⚙️ Profile: $capitalized_profile${dns_status}"
        fi
    elif [ "$blocked_mod" -ge 0 ]; then
        # Set success message if not set to error
        if [ -z "$status_msg" ]; then
            if [ "$(date +%m%d)" = "0401" ]; then
                blocking_info="Loaded $blocked_mod malware"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Loaded $((blocked_mod - blacklist_count)) malware + $blacklist_count (blacklist)"
                status_msg="Status: Protection is Vulnerable ✅ | $blocking_info | ⚙️ Profile: $capitalized_profile${dns_status}"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Allowlists:$enabled_blocklists"

                sed -i 's/^name=.*/name=Re-Malware | Not just a normal malware module ✨/' "$MODDIR/module.prop"
                sed -i 's/^banner=.*/banner=banner_alt.png/' "$MODDIR/module.prop"
            else
                blocking_info="Loaded $blocked_mod blocking rules"
                [ "$blacklist_count" -gt 0 ] && blocking_info="Loaded $((blocked_mod - blacklist_count)) blocking rules + $blacklist_count (blacklist)"
                status_msg="Status: Protection is enabled ✅ | $blocking_info | ⚙️ Profile: $capitalized_profile${dns_status}"
                [ "$whitelist_count" -gt 0 ] && status_msg="$status_msg | Whitelist: $whitelist_count"
                [ "$custom_entries" -gt 0 ] && status_msg="$status_msg | Custom rules: $custom_entries"
                [ -n "$enabled_blocklists" ] && status_msg="$status_msg | Enabled Blocklists:$enabled_blocklists"

                sed -i 's/^name=.*/name=Re-Malwack | Not just a normal ad-blocker module ✨/' "$MODDIR/module.prop"
                sed -i 's/^banner=.*/banner=banner.png/' "$MODDIR/module.prop"
            fi
        fi
    fi
fi

# Check if auto-update is enabled
if [ "$daily_update" = 1 ]; then
    # Checking fallback script existance 
    if [ -f "$FALLBACK_SCRIPT" ]; then
        log_message INFO "Auto update enabled (fallback mode), ensuring fallback script is running."
        nohup "$FALLBACK_SCRIPT" >/dev/null 2>&1 &
        sleep 1
        if ! kill -0 "$(cat $persist_dir/logs/auto_update.pid 2>/dev/null)" 2>/dev/null; then
            # This action was taken in case a user reboot the device after installing an update and SOME HOW
            # the fallback script failed to start again, so we just disable auto update to prevent further issues.
            log_message ERROR "Failed to start fallback auto update script, disabling auto update completely..."
            rm -f "$FALLBACK_SCRIPT"
            sed -i 's/^daily_update=.*/daily_update=0/' "$persist_dir/config.sh"
        fi

    # Checking crond existance
    elif [ -f "$JOB_FILE" ]; then
        log_message INFO "Auto update enabled (cron mode), verifying crond existence."
        CRON_PROVIDER=$(detect_cron_provider) || {
        log_message WARN "No cron provider detected at boot."
        return
        }
        CROND=$(cron_cmd crond)
        log_message INFO "Found crond, initiating auto update..."
        log_message INFO "Using $CRON_PROVIDER applets."
        $CROND -b -c "$JOB_DIR" -L "$persist_dir/logs/auto_update-cron.log"
        sleep 1.5
        CROND_PID="$(busybox pgrep -f "crond.*$JOB_DIR" | head -n 1 || true)"
        [ -n "$CROND_PID" ] && log_message SUCCESS "Crond started! PID: $CROND_PID" || log_message ERROR "Failed to start crond." # No fallbacks here because this SHOULD work else imma-
    fi
fi

# Apply module status into module description
sed -i "s/^description=.*/description=$status_msg/" "$MODDIR/module.prop"
log_message INFO "$status_msg"

log_message INFO "service.sh Finished."