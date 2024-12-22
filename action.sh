MODDIR="/data/adb/modules/Re-Malwack"

echo "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝
"
sleep 0.5
echo "- Upgrading Defenses 🛡️"
if ! ping -w 1 google.com &>/dev/null ; then
    echo "- Failed to upgrade. Please check your internet connection."
    sleep 2
    exit 1
fi

# Download the hosts file and save it as "hosts"
wget --no-check-certificate -O /sdcard/hosts1 https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts &>/dev/null || abort "Failed to download hosts file."
wget --no-check-certificate -O /sdcard/hosts2 https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt &>/dev/null || abort "Failed to download hosts file." 
wget --no-check-certificate -O /sdcard/hosts3 https://o0.pages.dev/Pro/hosts.txt &>/dev/null || abort "Failed to download hosts file."
wget --no-check-certificate -O /sdcard/hosts4 https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt &>/dev/null || abort "Failed to download hosts file."
wget --no-check-certificate -O /sdcard/hosts5 https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileAds.txt &>/dev/null || abort "Failed to download hosts file."
wget --no-check-certificate -O /sdcard/hosts6 https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileSpyware.txt &>/dev/null || abort "Failed to download hosts file."
echo "- Preparing New weapons 🔫"

for j_cole in /system/etc/hosts /sdcard/hosts1 /sdcard/hosts2 /sdcard/hosts3 /sdcard/hosts4 /sdcard/hosts5 /sdcard/hosts6; do
    cat "$j_cole"
    echo ""
done | grep -vE '^[[:space:]]*#' | grep -vE '^[[:space:]]*$' | sort | uniq > "$MODDIR/system/etc/hosts"

# let's see if the file was downloaded or not.
if [ ! -f "/sdcard/hosts6" ]; then
    echo "- Looks like there is a problem with some weapons, check your internet connection and try again"
else
    string="description=Status: Protection is enabled ✅ | protection update date: $(date)"
    sed -i "s/^description=.*/$string/g" $MODDIR/module.prop 
    echo "- Everthing is fine now, Enjoy 😉"
    rm /sdcard/hosts*
fi
