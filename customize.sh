# who tf wrote this lmao, should have made this as an array lmao.
REPLACE="/system/etc/hosts
/system/etc/hosts.tmp
"
DO_WE_HAVE_ANYTHING_TO_EXTRACT=false
DO_WE_REALLY_NEED_ADDONS=true
SKIPUNZIP=1
for i in "common/functions.sh" "common/install.sh" "system"; do
  unzip -qjo "$ZIPFILE" $i -d $TMPDIR || abort "- Failed to unpack module resources, please try again"
done
source $TMPDIR/functions.sh
. $TMPDIR/install.sh
