# Credits in acsii for "Re-Malwack Lite" + Intro # [Luna] 5:44PM HUH?????????
ui_print " 
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
│░█░░░▀█▀░▀█▀░█▀▀                             │
│░█░░░░█░░░█░░█▀▀                             │
│░▀▀▀░▀▀▀░░▀░░▀▀▀                             │
╚────────────────────────────────────────╝
"
sleep 1
ui_print "   Welcome to Re-Malwack Lite installation wizard!"
ui_print " "
sleep 1.5
ui_print "   The Installation will only few seconds ⚡"
sleep 1
ui_print " "
ui_print "- Downloading the latest hosts file..."

# let's check do we have internet or not.
if ! ping -w 1 google.com; then
	ui_print "- This module requires internet connection to download"
	abort "  Some utilities, please connect to a mobile network and try again."
fi

 # Download the hosts file and save it as "hosts"
su -c wget "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" $TMPDIR/hosts

# let's see if the file was downloaded or not.
if [ ! -f "$TMPDIR/hosts" ]; then
	abort "- The file wasn't downloaded, please try again."
else 
	ui_print "- The new hosts file is downloaded successfully ✓"
fi

ui_print "- Currently protecting a/an $(getprop ro.product.brand) device, model: $(getprop ro.product.model) 🛡"
ui_print "- Installing hosts file"
cat $TMPDIR/hosts /etc/hosts | sort | uniq > $MODPATH/system/etc/hosts
chmod 0644 $MODPATH/system/etc/hosts