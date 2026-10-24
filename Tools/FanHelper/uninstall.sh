#!/bin/bash
# Stops and removes the fan helper; stopping it leaves the fans in automatic.
set -euo pipefail
LABEL=com.tenno.TouchBarStats.FanHelper
sudo launchctl bootout system/$LABEL 2>/dev/null || true
sudo rm -f /Library/PrivilegedHelperTools/$LABEL /Library/LaunchDaemons/$LABEL.plist
echo "Helper desinstalado."
