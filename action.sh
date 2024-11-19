echo "
  ╔────────────────────────────────────────╗
  │░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
  │░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
  │░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
  ╚────────────────────────────────────────╝
"
sleep 0.5
echo "       Upgrading Defenses🛡️...."
if ! ping -w 3 google.com &>/dev/null; then

    echo "       An error occured, check your internet connection "
    exit
fi
# Download the hosts file and save it as "hosts"
wget -O /sdcard/hosts https://hosts.ubuntu101.co.za/hosts

echo "       Preparing New weapons🔫..."
{
    for j_cole in /system/etc/hosts /sdcard/hosts ; do
        cat $j_cole
        echo ""
    done
} | sort | uniq > /data/adb/modules/Re-Malwack/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "/sdcard/hosts" ]; then
    echo "       Looks like there is a problem with some weapons, maybe check your internet connection?"
else 
    echo "       Everthing is fine now, Enjoy 😉"
    rm /sdcard/hosts
    sleep 1
fi
