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
ui_print "     Welcome to Re-Malwack installation wizard!"
ui_print " "
sleep 1.5
ui_print "     Installation process will only take few moments ⚡"
sleep 1

# rcm lore.
if ! $BOOTMODE; then
	ui_print "     Only uninstallation is supported in recovery"
	touch $MODPATH/remove
	[ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
	recovery_cleanup
	cleanup
	rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
	abort "     Uninstallation is finished! Thanks for using Re-Malwack"
fi

# prevent initializing add-ons if we dont have to.
if [ "$DO_WE_REALLY_NEED_ADDONS" == "true" ]; then
	if [ "$(ls -A $MODPATH/common/addon/*/install.sh 2>/dev/null)" ]; then
		ui_print "     Running Addons...."
		for i in $MODPATH/common/addon/*/install.sh; do
			ui_print "     Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
			. $i
		done
	fi
fi

#checking for conflicts
ui_print "     Checking for conflicts"

abort() { echo "$1" && exit 1;}

mods=$(find /data/adb/modules | grep /system/etc/hosts | grep -v 'Re-Malwack' | awk '{while(match($0, /\/data\/adb\/modules\/([^\/]+)/)) {print substr($0, RSTART+20, RLENGTH-20); $0=substr($0, RSTART+RLENGTH)}}' | sort | uniq)
apps=$(pm list packages | grep 'org.adaway' | sed 's/package://')

nah() {
  [ "$1" = 0 ] && { a='mods' && b="$mods";} ||\
                  { a='apps' && b="$apps";}
  echo "     Error! conflicts found,"\
       "please uninstall the following $a first:\n$b"
}

[ ! -z "$mods" ] && abort "$(nah 0)"
[ ! -z "$apps" ] && abort "$(nah 1)"
echo "     All good!"

# make an bool to prevent extracting things if we dont have anything to extract...
if [ "$DO_WE_HAVE_ANYTHING_TO_EXTRACT" == "true" ]; then
	unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
fi

# let's check do we have internet or not.
ui_print "     Checking internet connection..."
if ! ping -w 3 google.com &>/dev/null; then

    ui_print "     This module requires internet connection to download"
    abort "      Some utilities, please connect to a mobile network and try again."
fi
# Download the hosts file and save it as "hosts"
ui_print "     Preparing Shields 🛡️..."
wget -O hosts1 https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate-compressed.txt
wget -O hosts2 https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

# merge bombs to get a big nuke
mkdir -p $MODPATH/system/etc
ui_print "     Preparing weapons to kill malware🔫..."
{
    for j_cole in /system/etc/hosts hosts1 hosts2; do
        cat $j_cole
        echo ""
    done
} | sort | uniq > $MODPATH/system/etc/hosts

# let's see if the file was downloaded or not.
if [ ! -f "hosts1" ]; then
    abort "     Looks like there is a problem with some weapons, maybe check your internet connection?"
else 
    ui_print "     Your $(getprop ro.product.brand) device, model $(getprop ro.product.model) is now armed against ads, malware and more 🛡"
    sleep 0.5
fi

# set perms
chmod 644 $MODPATH/system/etc/hosts
chmod 755 $MODPATH/system/bin/rmlwk
chmod 755 $MODPATH/action.sh
