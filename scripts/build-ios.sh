#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Plutus iOS Build ==="
echo "Note: FFI backend is not available on iOS (uses stub)."
echo ""

# Check prerequisites
command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter is not installed"; exit 1; }

if [ "$(uname -s)" != "Darwin" ]; then
    echo "ERROR: iOS builds require macOS with Xcode."
    exit 1
fi

command -v xcodebuild >/dev/null 2>&1 || { echo "ERROR: Xcode is not installed"; exit 1; }

# Step 1: Flutter build (no codesign for local/dev builds)
echo "--- Building Flutter iOS app (no codesign) ---"
cd "$PROJECT_DIR"
flutter pub get
flutter build ios --release --no-codesign --dart-define-from-file=app.env

# Output
APP_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"
if [ -d "$APP_PATH" ]; then
    echo ""
    echo "=== Build successful ==="
    echo "Output: $APP_PATH"
    echo "Size: $(du -sh "$APP_PATH" | cut -f1)"
    echo ""
    echo "To install on a device, open ios/Runner.xcworkspace in Xcode"
    echo "and configure signing with your Apple Developer account."
else
    echo "ERROR: Build output not found at $APP_PATH"
    exit 1
fi
