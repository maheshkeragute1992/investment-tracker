#!/bin/bash
set -e

# Download and extract Flutter 3.35.7
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.7-stable.tar.xz | tar -xJ

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

# Configure Flutter for web
flutter config --enable-web --no-analytics

# Get dependencies
flutter pub get

# Build for web
flutter build web --release