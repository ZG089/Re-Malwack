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
sleep 0.2
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.2
ui_print "- ⚙ Module Version: $(grep_prop version $TMPDIR/module.prop)"
sleep 0.2
ui_print "- 📱 Device Brand: $(getprop ro.product.brand)"
sleep 0.2
ui_print "- 📱 Device Model: $(getprop ro.product.model)"
sleep 0.2
ui_print "- 🤖 Android Version: $(getprop ro.build.version.release)"
sleep 0.2
ui_print "- ⚙ Device Arch: $(getprop ro.product.cpu.abi)"
sleep 0.2
ui_print "- 🛠 Kernel version: $(uname -r)"
sleep 0.2
ui_print "- ⌛ Current Time: $(date "+%d, %b - %H:%M %Z")"
ui_print ""
sleep 0.2
ui_print "                                    /"
ui_print " ----------------------------------"
ui_print " "
ui_print "[INSTALLATION BEGINS]"
sleep 0.2

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

# Check for conflicts
pm list packages | grep -q org.adaway && abort "- Adaway is detected, Please disable to prevent conflicts."

for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    # Skip our own module
    [ "$module_id" == "Re-Malwack" ] && continue

    # Check for conflict by looking for a hosts file in the module
    if [ -f "${module}/system/etc/hosts" ]; then
        # Check if the module is already disabled
        if [ -f "/data/adb/modules/$module_id/disable" ]; then
            continue
        fi
        module_name="$(grep_prop name "${module}/module.prop")"
        ui_print "- Disabling conflicting module: $module_name"
        touch "/data/adb/modules/$module_id/disable"
    fi
done

# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

# let's check do we have internet or not.
ping -c 1 -w 5 google.com &>/dev/null || abort "- This module requires internet connection to download protections."

# Download hosts files
ui_print "- Preparing Shields 🛡️"
mkdir -p $MODPATH/system/etc
counter=1
pids=""
while read -r url; do
    if [ -n "$url" ]; then
        wget --no-check-certificate -O "hosts${counter}" "$url" &>/dev/null &
        pids="$pids $!"
        counter=$((counter + 1))
    fi
done < <(echo "$hostsFileURL")

# Wait for all downloads to complete
for pid in $pids; do
    wait $pid || abort "- Download failed. Please check your internet connection and try again."
done

# Check if all files were downloaded successfully
for i in $(seq 1 $((counter-1))); do
    if [ ! -f "hosts${i}" ]; then
        abort "- Download failed. Please check your internet connection and try again."
    fi
done

ui_print "- Preparing weapons to kill malware 🔫"
cat /system/etc/hosts hosts* 2>/dev/null | sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//g' | sort -u > $MODPATH/system/etc/hosts
ui_print "- Your device is now armed against ads, malware and more 🛡"

# Add a persistent directory to save configuration
config_file="/data/adb/Re-Malwack/config.sh"
types="block_porn block_gambling block_fakenews block_social"
if [ -f "$config_file" ]; then
    for type in $types; do
        grep -q "^$type=" "$config_file" || echo "$type=0" >> "$config_file"
    done
else
    mkdir -p "/data/adb/Re-Malwack"
    for type in $types; do
        echo "$type=0"
    done > "$config_file"
fi

mkdir /sdcard/Re-Malwack

# set permissions
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
chmod 755 $MODPATH/action.sh
chmod 755 "/data/adb/Re-Malwack/config.sh"
