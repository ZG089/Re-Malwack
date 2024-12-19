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
	LIBDI
MODVER=`grep_prop version $TMPDIR/module.prop`
DEV=`grep_prop author $TMPDIR/module.prop`
Model=`getprop ro.product.model`
Brand=`getprop ro.product.brand` 
Architecture=`getprop ro.product.cpu.abi`
Android=`getprop ro.system.build.version.release`
Time=$(date "+%d, %b - %H:%M %Z")

ui_print "
╔────────────────────────────────────────╗
│░█▀▄░█▀▀░░░░░█▄█░█▀█░█░░░█░█░█▀█░█▀▀░█░█│
│░█▀▄░█▀▀░▄▄▄░█░█░█▀█░█░░░█▄█░█▀█░█░░░█▀▄│
│░▀░▀░▀▀▀░░░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀│
╚────────────────────────────────────────╝"
ui_print "- Welcome to Re-Malwack installation wizard!"
sleep 0.5
ui_print ""
ui_print " ----------------------------------"
ui_print "                                   \ "
ui_print ""
sleep 0.5
ui_print "- ⚙ Module Version: $MODVER"
sleep 0.5
ui_print "- 📱 Device Brand: $Brand"
sleep 0.5
ui_print "- 📱 Device Model: $Model"
sleep 0.5
ui_print "- 🤖 Android Version: $Android"
sleep 0.5
ui_print "- ⚙ Device Arch: $Architecture"
sleep 0.5
ui_print "- 🛠 Kernel version: $(uname -r)"
sleep 0.5
ui_print "- ⌛ Current Time: $Time"
ui_print ""
sleep 0.5
ui_print "                                    /"
ui_print " ----------------------------------"                           

sleep 1
ui_print " "
sleep 1.5
ui_print "- Installation process will only take few moments ⚡"
sleep 1

# rcm lore.
if ! $BOOTMODE; then
	ui_print "- Only uninstallation is supported in recovery"
	touch $MODPATH/remove
	[ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
	recovery_cleanup
	cleanup
	rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
	abort "- Uninstallation is finished! Thanks for using Re-Malwack"
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
tempFileToStoretempFileToStoreModuleNames=$(mktemp)
pm list packages | sed 's/package://' | grep -q org.adaway && abort "- Adaway is detected, aborting the installation..."
for i in /data/adb/modules/*; do
    # skip this instance if we got into our own module dir.
    if [ "$(grep_prop id ${i}/module.prop)" == "Re-Malwack" ]; then
        continue
    fi

    # idk man whatever...
    if [ -f "${i}/system/etc/hosts" ]; then
        modules_count=$(($modules_count + 1))
        #echo "     $(grep_prop name ${i}/module.prop) might conflict with this module.."
	echo -e "$(grep_prop name ${i}/module.prop)\n" >> $tempFileToStoreModuleNames
    fi
done
if [ "$modules_count" -ge "1" ]; then
    echo "     Notice: The following modules will be disabled to proceed the installation:"
    for i in "$(cat $tempFileToStoreModuleNames)"; do
        echo -e "\t\t$i"
	touch /data/adb/modules/$i/disable
    done
fi
echo "- All good!"

# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

# let's check do we have internet or not.
ui_print "- Checking internet connection..."
if ! ping -w 3 google.com &>/dev/null; then
    abort "- This module requires internet connection to download protections."
fi
# Download the hosts file and save it as "hosts"
ui_print "- Preparing Shields🛡️..."
wget -O hosts1 https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts #122k hosts
wget -O hosts2 https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus-compressed.txt
wget -O hosts3 https://hblock.molinero.dev/hosts # 458k hosts

# merge bombs to get a big nuke
mkdir -p $MODPATH/system/etc
ui_print "- Preparing weapons to kill malware🔫..."
{
    for j_cole in /system/etc/hosts hosts1 hosts2 hosts3 ; do
        cat $j_cole
        echo ""
    done
} | sort | uniq > $MODPATH/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "hosts3" ]; then
    abort "- Looks like there is a problem with some weapons, maybe check your internet connection?"
else 
    ui_print "- Your device is now armed against ads, malware and more 🛡"
    sleep 0.5
fi

# set perms
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
chmod 755 $MODPATH/action.sh
