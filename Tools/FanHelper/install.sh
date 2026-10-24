#!/bin/bash
# Builds the root fan helper and installs it as a LaunchDaemon (requires sudo, once).
set -euo pipefail
cd "$(dirname "$0")/../.."

LABEL=com.tenno.TouchBarStats.FanHelper
BINARY=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist

echo "Building the helper..."
mkdir -p build
swiftc -O -swift-version 5 Sources/Metrics/SMC/*.swift Sources/FanControl/Client/FanCommand.swift \
    Sources/FanControl/Client/FanHelperEndpoint.swift Tools/FanHelper/*.swift -o build/fan-helper
codesign --force --sign - build/fan-helper

echo "Installing (asks for your password)..."
sudo launchctl bootout system/$LABEL 2>/dev/null || true
sudo mkdir -p /Library/PrivilegedHelperTools
sudo install -o root -g wheel -m 755 build/fan-helper "$BINARY"
sudo install -o root -g wheel -m 644 Tools/FanHelper/$LABEL.plist "$PLIST"
sudo launchctl bootstrap system "$PLIST"
echo "Helper installed and running."
