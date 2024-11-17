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
ui_print "   Checking internet connection..."

# let's check do we have internet or not.
if ! ping -w 1 google.com; then
    ui_print "   This module requires internet connection to download"
    abort "    Some utilities, please connect to a mobile network and try again."
fi

 # Download the hosts file and save it as "hosts"
ui_print "   Downloading hosts file..."
for i in $(seq 0 3); do
    rm $TMPDIR/hosts
    touch $TMPDIR/hosts
    wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts${i}" "$TMPDIR/hosts${i}"
    cat $TMPDIR/hosts0 $TMPDIR/hosts1 $TMPDIR/hosts2 $TMPDIR/hosts3 /system/etc/hosts | sort | uniq >> $MODPATH/system/etc/hosts
    rm $TMPDIR/hosts${i}
done

# let's see if the file was downloaded or not.
if [ ! -f "$TMPDIR/hosts" ]; then
    abort "   The ad-blocker file is missing, please try again."
else 
    ui_print "   The new hosts file is downloaded successfully ✓"
fi

ui_print "   Currently protecting a/an $(getprop ro.product.brand) device, model: $(getprop ro.product.model) 🛡"
ui_print "   Installing hosts file into your device..."
chown 0 $MODPATH/system/bin/rmlwk $MODPATH/system/etc/hosts
chgrp 0 $MODPATH/system/etc/hosts
chgrp 2000 $MODPATH/system/bin/rmlwk
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
