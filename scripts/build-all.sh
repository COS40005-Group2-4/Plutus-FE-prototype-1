#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_OS=$(uname -s)

echo "=== Plutus Build All ==="
echo "Host OS: $HOST_OS"
echo ""

FAILED=()
SUCCEEDED=()

run_build() {
    local name="$1"
    local script="$2"
    echo ""
    echo "=========================================="
    echo "  Building: $name"
    echo "=========================================="
    if bash "$script"; then
        SUCCEEDED+=("$name")
    else
        echo "WARNING: $name build failed"
        FAILED+=("$name")
    fi
}

# Always available: Android
run_build "Android" "$SCRIPT_DIR/build-android.sh"

# Platform-specific
case "$HOST_OS" in
    Darwin)
        run_build "macOS" "$SCRIPT_DIR/build-macos.sh"
        run_build "iOS" "$SCRIPT_DIR/build-ios.sh"
        ;;
    Linux)
        run_build "Linux" "$SCRIPT_DIR/build-linux.sh"
        ;;
    *)
        echo "WARNING: Host OS $HOST_OS — skipping desktop builds."
        echo "Use build-windows.bat on Windows."
        ;;
esac

# Summary
echo ""
echo "=========================================="
echo "  Build Summary"
echo "=========================================="
echo "Succeeded: ${SUCCEEDED[*]:-none}"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Failed: ${FAILED[*]}"
    exit 1
else
    echo "All builds successful!"
fi
