# Checking and disabling other hosts modules
# Some nerds are installing multiple adblock modules after installing Re-Malwack
# Thinking that will push adblocking to max, but it only causes conflicts and issues 😭
for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    [ "$module_id" == "Re-Malwack" ] && continue
    if [ -f "${module}/system/etc/hosts" ]; then
        [ -f "/data/adb/modules/$module_id/disable" ] && continue
        touch "/data/adb/modules/$module_id/disable"
    fi
done

# Mount hosts manually if KernelSU .nomount / APatch .litemode_enable and mountify exist
if [ -d /data/adb/modules/mountify ]
    && { [ "$KSU_MAGIC_MOUNT" = "true" ] && [ -f /data/adb/ksu/.nomount ]; }
    || { [ "$APATCH_BIND_MOUNT" = "true" ] && [ -f /data/adb/.litemode_enable ]; }; then
    mount --bind "$MODPATH/system/etc/hosts" /system/etc/hosts
fi
