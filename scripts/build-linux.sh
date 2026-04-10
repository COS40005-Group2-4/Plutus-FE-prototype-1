#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/plutus-backend"

echo "=== Plutus Linux Build ==="

# Check prerequisites
command -v go >/dev/null 2>&1 || { echo "ERROR: Go is not installed"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter is not installed"; exit 1; }

# Step 1: Compile Go backend
echo "--- Compiling Go backend (linux/amd64) ---"
cd "$BACKEND_DIR"
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
    go build -o "$PROJECT_DIR/libplutus.so" -buildmode=c-shared .
echo "Built libplutus.so ($(du -h "$PROJECT_DIR/libplutus.so" | cut -f1))"

# Copy to linux/ directory where CMakeLists.txt expects it
cp "$PROJECT_DIR/libplutus.so" "$PROJECT_DIR/linux/libplutus.so"
echo "Copied libplutus.so to linux/"

# Step 2: Flutter build
echo "--- Building Flutter Linux app ---"
cd "$PROJECT_DIR"
flutter pub get
flutter build linux --release --dart-define-from-file=app.env

# Output
BUNDLE_PATH="$PROJECT_DIR/build/linux/x64/release/bundle"
if [ -d "$BUNDLE_PATH" ]; then
    echo ""
    echo "=== Build successful ==="
    echo "Output: $BUNDLE_PATH"
    echo "Size: $(du -sh "$BUNDLE_PATH" | cut -f1)"
    echo ""
    echo "To run: $BUNDLE_PATH/plutus"
else
    echo "ERROR: Build output not found at $BUNDLE_PATH"
    exit 1
fi
