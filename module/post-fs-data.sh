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
