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

# let's store the url links here to make the installation easier.
# we have uhhh, 6 links now..
hostsFileURL="
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt
https://o0.pages.dev/Pro/hosts.txt
https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt
https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileAds.txt
https://raw.githubusercontent.com/r-a-y/mobile-hosts/refs/heads/master/AdguardMobileSpyware.txt
"

ui_print "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝"
ui_print "    Welcome to Re-Malwack installation wizard!"
sleep 0.5
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.5
ui_print "- ⚙ Module Version: $(grep_prop version $TMPDIR/module.prop)"
sleep 0.5
ui_print "- 📱 Device Brand: $(getprop ro.product.brand)"
sleep 0.5
ui_print "- 📱 Device Model: $(getprop ro.product.model)"
sleep 0.5
ui_print "- 🤖 Android Version: $(getprop ro.build.version.release)"
sleep 0.5
ui_print "- ⚙ Device Arch: $(getprop ro.product.cpu.abi)"
sleep 0.5
ui_print "- 🛠 Kernel version: $(uname -r)"
sleep 0.5
ui_print "- ⌛ Current Time: $(date "+%d, %b - %H:%M %Z")"
ui_print ""
sleep 0.5
ui_print "                                    /"
ui_print " ----------------------------------"
ui_print " "
sleep 1
ui_print "[INSTALLATION BEGINS]"
sleep 1

# rcm lore.
if ! $BOOTMODE; then
	ui_print "- Only uninstallation is supported in recovery"
	touch $MODPATH/remove
	[ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
	recovery_cleanup
	cleanup
	rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
	abort "- Uninstallation is finished, Thank you for using Re-Malwack!"
fi

# prevent initializing add-ons if we dont have to.
if [ "$DO_WE_REALLY_NEED_ADDONS" == "true" ]; then
	if [ "$(ls -A $MODPATH/common/addon/*/install.sh 2>/dev/null)" ]; then
		ui_print "- Running Addons...."
		for i in $MODPATH/common/addon/*/install.sh; do
			ui_print "- Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
			. $i
		done
	fi
fi

# check for conflicts
ui_print "- Checking for conflicts...."
tempFileToStoreConflicts=$(
    if touch /data/local/tmp/tempFile; then
        echo "/data/local/tmp/tempFile"
    else
        echo "/sdcard/tempFile"
    fi
)

pm list packages | sed 's/package://' | grep -q org.adaway && abort "- Adaway is detected, Please disable to prevent conflicts."

for i in /data/adb/modules/*; do
    # Skip this instance if we are in our own module directory
    if [ "$(grep_prop id ${i}/module.prop)" == "Re-Malwack" ]; then
        continue
    fi
    # Check for conflict by looking for a hosts file in the module
    if [ -f "${i}/system/etc/hosts" ]; then
        modules_count=$(($modules_count + 1))
        # Save both the name and ID to the temp file (name|id format)
        echo "$(grep_prop name ${i}/module.prop)|$(grep_prop id ${i}/module.prop)" >> $tempFileToStoreConflicts
    fi
done

if [ "$modules_count" -ge "1" ]; then
    echo "- Notice: The following modules will be disabled to prevent conflicts:"
    while IFS='|' read -r moduleName moduleID; do
        echo "- $moduleName"
        # Create the disable file in the corresponding module directory
        touch "/data/adb/modules/$moduleID/disable"
    done < $tempFileToStoreConflicts
fi


# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

# let's check do we have internet or not.
ui_print "- Checking internet connection..."
ping -w 3 google.com &>/dev/null || abort "- This module requires internet connection to download protections."

# Download hosts files
ui_print "- Preparing Shields🛡️..."
counter=1
echo "$hostsFileURL" | while read -r url; do
    # Skip empty lines
    [ -n "$url" ] || continue

    # Download using wget
    wget --no-check-certificate -O "hosts${counter}" "$url" &>/dev/null || {
        abort "- Failed to download hosts file from $url"
    }
    counter=$((counter + 1))
done

# Merge files into a single hosts file
mkdir -p $MODPATH/system/etc
ui_print "- Preparing weapons to kill malware🔫.. (Please wait)"
{
    for file in /system/etc/hosts hosts1 hosts2 hosts3 hosts4 hosts5 hosts6 ; do
        [ -f "$file" ] && cat "$file"
        echo ""
    done
} | grep -vE '^[[:space:]]*#' | grep -vE '^[[:space:]]*$' | sort | uniq > $MODPATH/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "hosts6" ]; then
    abort "- Looks like there is a problem with some weapons, maybe check your internet connection?"
else 
    ui_print "- Your device is now armed against ads, malware and more 🛡"
    sleep 0.5
fi

# set perms
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
chmod 755 $MODPATH/action.sh
# cleanup
rm -rf $tempFileToStoreConflicts
