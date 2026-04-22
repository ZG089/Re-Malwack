#!/system/bin/sh

REALPATH=$(readlink -f "$0" 2>/dev/null)
[ -n "$REALPATH" ] || REALPATH="$0"
MODDIR=$(dirname "$REALPATH")

. "$MODDIR/lib/defs.sh"
. "$MODDIR/lib/util.sh"
. "$MODDIR/lib/logging.sh"
. "$MODDIR/lib/status.sh"
. "$MODDIR/lib/fetch.sh"
. "$MODDIR/lib/hosts.sh"
. "$MODDIR/lib/protection.sh"
. "$MODDIR/lib/blocklists.sh"
. "$MODDIR/lib/auto_update.sh"
. "$MODDIR/lib/commands.sh"

rmlwk_prepare_runtime
log_message "Running Re-Malwack version $version"
rmlwk_detect_hosts_target

if [ "$WEBUI" = "true" ]; then
    refresh_blocked_counts
    update_status
fi

rmlwk_setup_error_trap
rmlwk_prepare_cli_flags "$@"

[ -z "$MAGISKTMP" ] && [ "$quiet_mode" = 0 ] && rmlwk_banner
log_message INFO "========== End of pre-main logic =========="

case "$(tolower "$1")" in
    --profile|-p) 
        if [ "$2" = "create" ] || [ "$2" = "delete" ] || [ "$2" = "list" ]; then
            cmd_profile "$2" "$3" "$4"
        else
            cmd_profile "$2"
        fi
        ;;
    --adblock-switch|-as) pause_protections ;;
    --reset|-r) cmd_reset ;;
    --export-logs|-e) export_logs ;;
    --query-domain|-q)
        start_time=$(get_current_time)
        query_domain "$2"
        end_time=$(get_current_time)
        log_duration "Querying domain: $2" "$start_time" "$end_time"
        ;;
    --block-porn|-bp|--block-gambling|-bg|--block-fakenews|-bf|--block-social|-bs|--block-trackers|-bt|--block-safebrowsing|-bsb)
        cmd_toggle_blocklist "$1" "$2"
        ;;
    --whitelist|-w) cmd_whitelist "$@" ;;
    --blacklist|-b) cmd_blacklist "$@" ;;
    --custom-source|-c) cmd_custom_source "$@" ;;
    --custom-rule|-cr) cmd_custom_rule "$@" ;;
    --dns-logging) cmd_dns_logging "$2" ;;
    --auto-update|-a)
        case "$2" in
            enable) enable_auto_update ;;
            disable) disable_auto_update ;;
            *) 
                echo "[!] Invalid option for --auto-update / -a"
                echo "Usage: rmlwk <--auto-update|-a> <enable|disable>"
                ;;
        esac
        ;;
    --update-hosts|-u) cmd_update_hosts ;;
    --help|-h|*) show_help ;;
esac
