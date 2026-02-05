#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH

# Replace with your repository details
REPO_OWNER="itejo443"
REPO_NAME="ReMalwack-app"

# App package name
APP_PACKAGE="me.itejo443.remalwack"

# Temporary directory to store the APK
TEMP_DIR="/data/local/tmp/rmlwk-app"
APK_PATH="$TEMP_DIR/app.apk"

# Define service directory and self-delete script path
SERVICE_DIR="/data/adb/service.d"
SELF_DELETE="$SERVICE_DIR/rmlwk-auto_app_rm.sh"

# Create necessary directories
mkdir -p "$TEMP_DIR"

download() {
	if command -v curl > /dev/null 2>&1; then
		curl --connect-timeout 10 -Lsf "$1"
    else
		busybox wget -T 10 --no-check-certificate -qO - "$1"
    fi
}    

# Get the latest release URL using curl, grep, and sed
latest_release_url=$(download "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" \
    | grep '"browser_download_url":' \
    | sed -E 's/.*"browser_download_url": "(.*\.apk)".*/\1/')

# Check if the URL is valid
if [ -z "$latest_release_url" ]; then
	echo "[✗] Could not fetch the latest release URL."
	exit 1
fi

echo "[i] Latest APK URL: $latest_release_url"

# Download the APK file using download()
if ! download "$latest_release_url" > "$APK_PATH"; then
	echo "[✗] APK download failed."
	exit 1
fi

# Safety check (empty / broken file)
if [ ! -s "$APK_PATH" ]; then
	echo "[✗] Downloaded APK is empty or corrupted."
	exit 1
fi

# Install the APK as a user app
if ! pm install -r "$APK_PATH" >/dev/null 2>&1; then
	echo "[✗] Installation failed!"
	mkdir -p /sdcard/Download/rmlwk-app
	cp -f "$APK_PATH" /sdcard/Download/rmlwk-app/app.apk
	echo "[i] Please manually install app from /sdcard/Download/rmlwk-app"
	exit 1
fi

# Check if the installation was successful by verifying the app's presence
if pm path "$APP_PACKAGE" >/dev/null 2>&1; then
	echo "[✓] Re-Malwack QuickTile Add-on installed successfully!"
	# Create self-delete script to remove the app if the module is uninstalled
	mkdir -p "$SERVICE_DIR"
	cat > "$SELF_DELETE" << 'EOF'
#!/system/bin/sh
sleep 10
MODULE_DIR="/data/adb/modules/Re-Malwack"
APP_PKG="me.itejo443.remalwack"
SELF="$0"

if [ ! -d "$MODULE_DIR" ] && pm path "$APP_PKG" >/dev/null 2>&1; then
	pm uninstall "$APP_PKG"
	rm -f "$SELF"
fi
exit 0
EOF
	chmod 755 "$SELF_DELETE"
else
	echo "[✗] App installation verification failed."
	exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"