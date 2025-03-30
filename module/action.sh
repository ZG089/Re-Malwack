MODDIR="/data/adb/modules/Re-Malwack"
persist_dir="/data/adb/Re-Malwack"
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

# APRIL_FOOLS
function april_fools() {
    touch $persist_dir/get_pranked
    clear
    echo -e "\033[0;31m !!!!!!!!!!!!!!!!"
    echo -e "\033[0;31m !!!  DANGER  !!!"
    echo -e "\033[0;31m !!!!!!!!!!!!!!!!"
    sleep 3
    echo -e "\033[0;31m - Your device is now hacked."
    sleep 1.5
    echo -e "\033[0;31m - Bricking the device in"
    sleep 0.5
    echo -e "\033[0;31m 3..."
    sleep 1
    echo -e "\033[0;31m 2..."
    sleep 1
    echo -e "\033[0;31m 1..."
    sleep 3
    am start -a android.intent.action.VIEW -d "https://youtu.be/dQw4w9WgXcQ" 2>&1
    echo "- Happy April Fools!"
    echo "- XD"
    exit
    log_message "Happy April Fools!"
}

# Trigger April Fools prank :)
# Only starts at April 1st
if [ "$(date +%m%d)" = "0401" ] && [ ! -f "$persist_dir/get_pranked" ]; then
    if [ "$(shuf -i 0-1 -n 1)" = "0" ]; then # Chance of happening: 50%
        sleep 2
        echo ""
        echo -e "\033[0;31m - FATAL ERROR OCCURED!\033[0m\n"
        sleep 2
        april_fools
    fi
else
    rm -f $persist_dir/get_pranked    
fi

sh "$MODDIR/rmlwk.sh" --update-hosts || abort "- Failed to update hosts."