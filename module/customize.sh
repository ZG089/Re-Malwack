REPLACE=""
DO_WE_HAVE_ANYTHING_TO_EXTRACT=true
DO_WE_REALLY_NEED_ADDONS=false
SKIPUNZIP=1
for i in "common/functions.sh" "common/install.sh"; do
  unzip -qjo "$ZIPFILE" $i -d $TMPDIR || abort "- Failed to unpack module resources, please try again"
done
source $TMPDIR/functions.sh
. $TMPDIR/install.sh