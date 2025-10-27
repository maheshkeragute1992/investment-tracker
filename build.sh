#!/usr/bin/env bash
set -e

# Install Flutter stable channel
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
export PATH="$PWD/flutter_sdk/bin:$PATH"

# Show version to verify
flutter --version

# Configure Flutter for web
flutter config --enable-web --no-analytics

# Get dependencies
flutter pub get

# Build for web
flutter build web --release