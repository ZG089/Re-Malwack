# Set variables
[ $API -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
[ -z $DEBUG ] && DEBUG=false
INFO=$NVBASE/modules/.$MODID-files
ORIGDIR="$MAGISKTMP/mirror"

# aaaaaaaaaaaaaa
if $DYNLIB; then
	LIBPATCH="\/vendor"
	LIBDIR=/system/vendor
else
	LIBPATCH="\/system"
	LIBDIR=/system
fi

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

# rcm lore.
if ! $BOOTMODE; then
	ui_print "   Only uninstallation is supported in recovery"
	touch $MODPATH/remove
	[ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
	recovery_cleanup
	cleanup
	rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
	abort "   Uninstallation is finished!"
fi

# prevent initializing add-ons if we dont have to.
if [ "$DO_WE_REALLY_NEED_ADDONS" == "true" ]; then
	if [ "$(ls -A $MODPATH/common/addon/*/install.sh 2>/dev/null)" ]; then
		ui_print "   Running Addons...."
		for i in $MODPATH/common/addon/*/install.sh; do
			ui_print "   Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
			. $i
		done
	fi
fi

# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	ui_print "   Extracting module files..."
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

# let's check do we have internet or not.
ui_print "   Checking internet connection..."
if ! ping -w 1 google.com; then
    ui_print "   This module requires internet connection to download"
    abort "    Some utilities, please connect to a mobile network and try again."
fi

# Download the hosts file and save it as "hosts"
ui_print "   Downloading hosts file..."
rm $TMPDIR/hosts
touch $TMPDIR/hosts
for i in $(seq 0 3); do
    wget "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts${i}" "$TMPDIR/hosts${i}"
done

# mod and nuke those temp files
cat $TMPDIR/hosts0 $TMPDIR/hosts1 $TMPDIR/hosts2 $TMPDIR/hosts3 /system/etc/hosts | sort | uniq >> $MODPATH/system/etc/hosts
rm $TMPDIR/hosts0 $TMPDIR/hosts1 $TMPDIR/hosts2 $TMPDIR/hosts3

# let's backup the file to revert the changes.
cp /system/etc/hosts $MODPATH/hosts.bak

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
