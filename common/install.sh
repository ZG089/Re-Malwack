# Credits in acsii for "Re-Malwack Lite" + Intro # [Luna] 5:44PM HUH?????????
ui_print " 
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝
"
sleep 1
ui_print "   Welcome to Re-Malwack installation wizard!"
ui_print " "
sleep 1.5
ui_print "   The Installation will only take few moments ⚡"
sleep 1
ui_print " "
ui_print "- Checking internet connection..."

# let's check do we have internet or not.
if ! ping -w 1 google.com; then
	ui_print "- This module requires internet connection to download"
	abort "  Some utilities, please connect to a mobile network and try again."
fi

 # Download the hosts file and save it as "hosts"
ui_print "- Downloading hosts file..."
wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts0" $TMPDIR/hosts0
wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts1" $TMPDIR/hosts1
wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts2" $TMPDIR/hosts2
wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts3" $TMPDIR/hosts3
cat $TMPDIR/hosts0 $TMPDIR/hosts1 $TMPDIR/hosts2 $TMPDIR/hosts3 | sort | uniq > $TMPDIR/hosts
# cleaning up
rm $TMPDIR/hosts0
rm $TMPDIR/hosts1
rm $TMPDIR/hosts2
rm $TMPDIR/hosts3 

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
