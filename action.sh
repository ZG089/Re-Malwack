echo "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝
"
sleep 0.5
echo "- Upgrading Defenses🛡️, this may take a while...."
if ! ping -w 1 google.com; then
    echo "- Failed to upgrade. Please check your internet connection."
    sleep 2
    exit 1
fi

# Download the hosts file and save it as "hosts"
        wget -O /sdcard/hosts1 https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts #122k hosts
        wget -O /sdcard/hosts2 https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt
        wget -O /sdcard/hosts3 https://hblock.molinero.dev/hosts # 458k hosts
echo "- Preparing New weapons🔫..."
{
    for j_cole in /system/etc/hosts /sdcard/hosts1 /sdcard/hosts2 /sdcard/hosts3 ; do
        cat $j_cole
        echo ""
    done
} | sort | uniq > /data/adb/modules/Re-Malwack/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "/sdcard/hosts3" ]; then
    echo "- Looks like there is a problem with some weapons, check your internet connection and try again"
    sleep 3
else 
    echo "- Everthing is fine now, Enjoy 😉"
    rm /sdcard/hosts*
    sleep 1.5
fi
