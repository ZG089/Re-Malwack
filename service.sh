MODDIR="/data/adb/modules/Re-Malwack"
string="description=Status: Protection is enabled ✅ | protection update date: $(date)"
sed -i "s/^description=.*/$string/g" $MODDIR/module.prop