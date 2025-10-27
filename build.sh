#!/usr/bin/env bash
set -e

# Install Flutter stable channel
if [ -d "flutter_sdk/.git" ]; then
  echo "flutter_sdk exists — fetching latest"
  git -C flutter_sdk fetch --all --prune
  git -C flutter_sdk reset --hard origin/stable
else
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
fi
export PATH="$PWD/flutter_sdk/bin:$PATH"

# Show version to verify
flutter --version

# Configure Flutter for web
flutter config --enable-web --no-analytics

# Get dependencies
flutter pub get

# Build for web
flutter build web --release