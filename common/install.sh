# ahem, it's only for like idk
source $TMPDIR/functions.sh

ui_print " 
   ___ ___    __  __   _   _ __      ___   ___ _  __
  | _ \ __|__|  \/  | /_\ | |\ \    / /_\ / __| |/ /
  |   / _|___| |\/| |/ _ \| |_\ \/\/ / _ \ (__| ' < 
  |_|_\___|  |_|  |_/_/ \_\____\_/\_/_/ \_\___|_|\_\
                                                 
"
ui_print "      Welcome to Re-Malwack installation wizard!"
ui_print " "
sleep 1.5

# Check for min/max api version
if [ -z $MINAPI ] || [ $API -lt $MINAPI ]; then
  abort "- This ROM doesn't meet the minimum api level requirements, exiting..."
elif [ -z $MAXAPI ] || [ $API -gt $MAXAPI ]; then
  abort "- This ROM doesn't meet the maximum api level requirements, exiting.."
fi

# extract the hosts and the shell script.
ui_print "      Extracting Packages..."
if $BOOTMODE; then
  unzip -o "$ZIPFILE" 'system' -d /data/adb/modules_update/Re-Malwack/
fi

# fake the installation duration by adding a sleep cmd to let users wait and think that 
# this module is doing tons of jobs at once.
sleep 1.5
ui_print "      The module installation has been finished!"
