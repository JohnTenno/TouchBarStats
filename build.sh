#!/bin/bash
# Builds TouchBarStats.app, installs it in /Applications and opens it.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/Apps.noindex/TouchBarStats.app
# Keep only the installed app, so launcher searches do not offer build copies.
trap 'rm -rf "$APP"' EXIT
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/TouchBarIcon.png Resources/AppIcon.icns Resources/claude.svg "$APP/Contents/Resources/"

echo "Building..."
swiftc -O -swift-version 5 -framework AppKit $(find Sources -name '*.swift') -o "$APP/Contents/MacOS/TouchBarStats"
codesign --force --sign - "$APP"

echo "Installing in /Applications..."
pkill -x TouchBarStats || true
# Wait for the old instance to exit, otherwise `open` fails with error -600.
while pgrep -x TouchBarStats >/dev/null; do sleep 0.2; done
rm -rf /Applications/TouchBarStats.app
cp -R "$APP" /Applications/
open /Applications/TouchBarStats.app
echo "Done."
