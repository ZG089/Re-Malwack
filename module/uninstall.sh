APP_PACKAGE="me.itejo443.remalwack.App"
rm -rf /data/adb/Re-Malwack /data/adb/*/bin/rmlwk
pm path "$APP_PACKAGE" > /dev/null 2>&1 && pm uninstall $APP_PACKAGE
if [ -f $INFO ]; then
    while read LINE; do
        if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
            continue
        elif [ -f "$LINE~" ]; then
            mv -f $LINE~ $LINE
        else
            rm -f $LINE
            while true; do
                LINE=$(dirname $LINE)
                [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
            done
        fi
    done < $INFO
    rm -f $INFO
fi