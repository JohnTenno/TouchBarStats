#!/bin/bash
# Builds FanBoost and runs the fan at maximum for 10 s (requires sudo).
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build
swiftc -O -swift-version 5 Sources/Metrics/SMC/*.swift Tools/FanBoost/*.swift -o build/fan-boost
sudo ./build/fan-boost
