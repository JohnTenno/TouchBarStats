#!/bin/bash
# Builds and runs the logic tests (without the Touch Bar part or the app).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
swiftc -swift-version 5 $(find Sources/Metrics/Model Sources/Metrics/Readers Sources/Metrics/SMC Sources/Metrics/Presentation \
    Sources/FanControl/Client Sources/Settings/Model Sources/Media/FrameGeometry.swift -name '*.swift') Tests/*.swift -o build/tests
./build/tests
swiftc -swift-version 5 -parse-as-library Sources/ClaudeUsage/Model/CommandRunner.swift Tests/Process/main.swift -o build/process-tests
./build/process-tests
