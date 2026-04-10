#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/plutus-backend"
JNILIBS_DIR="$PROJECT_DIR/android/app/src/main/jniLibs"

echo "=== Plutus Android Build ==="

# Check prerequisites
command -v go >/dev/null 2>&1 || { echo "ERROR: Go is not installed"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "ERROR: Flutter is not installed"; exit 1; }

# Find Android NDK
find_ndk() {
    # Check ANDROID_NDK_HOME first
    if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "$ANDROID_NDK_HOME" ]; then
        echo "$ANDROID_NDK_HOME"
        return
    fi

    # Check ANDROID_HOME/ndk/
    if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
        local latest
        latest=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | sort -V | tail -1)
        if [ -n "$latest" ]; then
            echo "$ANDROID_HOME/ndk/$latest"
            return
        fi
    fi

    # Check Flutter's bundled NDK via local.properties
    local android_sdk
    android_sdk=$(grep 'sdk.dir' "$PROJECT_DIR/android/local.properties" 2>/dev/null | cut -d= -f2 | tr -d ' ' || true)
    if [ -n "$android_sdk" ] && [ -d "$android_sdk/ndk" ]; then
        local latest
        latest=$(ls -1 "$android_sdk/ndk" 2>/dev/null | sort -V | tail -1)
        if [ -n "$latest" ]; then
            echo "$android_sdk/ndk/$latest"
            return
        fi
    fi

    echo ""
}

NDK_PATH=$(find_ndk)
if [ -z "$NDK_PATH" ]; then
    echo "ERROR: Android NDK not found."
    echo "Set ANDROID_NDK_HOME or install NDK via Android Studio SDK Manager."
    exit 1
fi
echo "Using NDK: $NDK_PATH"

# Determine host OS for NDK toolchain path
HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$HOST_OS" = "darwin" ]; then
    NDK_HOST="darwin-x86_64"
elif [ "$HOST_OS" = "linux" ]; then
    NDK_HOST="linux-x86_64"
else
    echo "ERROR: Unsupported host OS for Android NDK: $HOST_OS"
    exit 1
fi

NDK_TOOLCHAIN="$NDK_PATH/toolchains/llvm/prebuilt/$NDK_HOST/bin"
if [ ! -d "$NDK_TOOLCHAIN" ]; then
    echo "ERROR: NDK toolchain not found at $NDK_TOOLCHAIN"
    exit 1
fi

# Minimum Android API level
MIN_API=21

# Step 1: Compile Go backend for arm64
echo "--- Compiling Go backend (android/arm64) ---"
mkdir -p "$JNILIBS_DIR/arm64-v8a"
cd "$BACKEND_DIR"
CGO_ENABLED=1 \
    GOOS=android \
    GOARCH=arm64 \
    CC="$NDK_TOOLCHAIN/aarch64-linux-android${MIN_API}-clang" \
    go build -o "$JNILIBS_DIR/arm64-v8a/libplutus.so" -buildmode=c-shared .
echo "Built arm64-v8a/libplutus.so ($(du -h "$JNILIBS_DIR/arm64-v8a/libplutus.so" | cut -f1))"

# Step 2: Compile Go backend for x86_64
echo "--- Compiling Go backend (android/amd64) ---"
mkdir -p "$JNILIBS_DIR/x86_64"
cd "$BACKEND_DIR"
CGO_ENABLED=1 \
    GOOS=android \
    GOARCH=amd64 \
    CC="$NDK_TOOLCHAIN/x86_64-linux-android${MIN_API}-clang" \
    go build -o "$JNILIBS_DIR/x86_64/libplutus.so" -buildmode=c-shared .
echo "Built x86_64/libplutus.so ($(du -h "$JNILIBS_DIR/x86_64/libplutus.so" | cut -f1))"

# Step 3: Generate keystore if needed
KEYSTORE_PATH="$PROJECT_DIR/android/app/plutus-release.keystore"
KEY_PROPS="$PROJECT_DIR/android/key.properties"

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo "--- Generating release keystore ---"
    echo "You will be prompted for keystore details."
    echo "(For testing, you can use simple passwords and dummy info)"
    echo ""
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -alias plutus \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000
    echo "Keystore generated at: $KEYSTORE_PATH"
fi

if [ ! -f "$KEY_PROPS" ]; then
    echo ""
    echo "--- Creating key.properties ---"
    read -sp "Enter keystore password: " STORE_PASS
    echo ""
    read -sp "Enter key password: " KEY_PASS
    echo ""

    cat > "$KEY_PROPS" << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=plutus
storeFile=plutus-release.keystore
EOF
    echo "Created key.properties"
fi

# Step 4: Flutter build
echo "--- Building Flutter Android APK ---"
cd "$PROJECT_DIR"
flutter pub get
flutter build apk --release --dart-define-from-file=app.env

# Output
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo ""
    echo "=== Build successful ==="
    echo "APK: $APK_PATH"
    echo "Size: $(du -h "$APK_PATH" | cut -f1)"
else
    echo "ERROR: APK not found at $APK_PATH"
    exit 1
fi
