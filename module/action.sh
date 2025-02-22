# logging system
function log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $message" >> "/sdcard/Re-Malwack/logs.txt"
}
MODDIR="/data/adb/modules/Re-Malwack"
function abort() {
    echo "- $1"
    sleep 0.5
    exit 1
}

echo "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝
"
sleep 0.5
echo "- Upgrading weapons 🔫"
log_message "Updating hosts via Action"
sh "$MODDIR/system/bin/rmlwk" --update-hosts || abort "- Failed to update hosts."

echo "- Everthing is fine now, Enjoy 😉"
log_message "Update hosts via Action is done.