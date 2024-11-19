ui_print "
  ╔────────────────────────────────────────╗
  │░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
  │░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
  │░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
  ╚────────────────────────────────────────╝
"
sleep 0.5
echo "       Updating Defenses...."
if ! ping -w 3 google.com &>/dev/null; then

    echo "       This module requires internet connection to download"
    abort "        Some utilities, please connect to a mobile network and try again."
fi
# Download the hosts file and save it as "hosts"
wget data/local/tmp/hosts https://hosts.ubuntu101.co.za/hosts

echo "       Preparing New weapons🔫..."
{
    for j_cole in /system/etc/hosts data/local/tmp/hosts; do
        cat $j_cole
        echo ""
    done
} | sort | uniq > /data/adb/modules/Re-Malwack/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "hosts" ]; then
    abort "       Looks like there is a problem with some weapons, maybe check your internet connection?"
else 
    echo "       Everthing is fine now, Enjoy 😉"
    sleep 0.5
fi
