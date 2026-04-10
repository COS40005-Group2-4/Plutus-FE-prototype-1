#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/plutus-backend"

echo "=== Plutus macOS Build ==="

# Check prerequisites
command -v go >/dev/null 2>&1 || { echo "ERROR: Go is not installed"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter is not installed"; exit 1; }

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    GOARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    GOARCH="amd64"
else
    echo "ERROR: Unsupported architecture: $ARCH"
    exit 1
fi

# Step 1: Compile Go backend
echo "--- Compiling Go backend (darwin/$GOARCH) ---"
cd "$BACKEND_DIR"
CGO_ENABLED=1 GOOS=darwin GOARCH=$GOARCH \
    go build -o "$PROJECT_DIR/libplutus.dylib" -buildmode=c-shared .
echo "Built libplutus.dylib ($(du -h "$PROJECT_DIR/libplutus.dylib" | cut -f1))"

# Step 2: Flutter build
echo "--- Building Flutter macOS app ---"
cd "$PROJECT_DIR"
flutter pub get
flutter build macos --release --dart-define-from-file=app.env

# Output
APP_PATH="$PROJECT_DIR/build/macos/Build/Products/Release/Plutus.app"
if [ -d "$APP_PATH" ]; then
    echo ""
    echo "=== Build successful ==="
    echo "Output: $APP_PATH"
    echo "Size: $(du -sh "$APP_PATH" | cut -f1)"
else
    echo "ERROR: Build output not found at $APP_PATH"
    exit 1
fi
