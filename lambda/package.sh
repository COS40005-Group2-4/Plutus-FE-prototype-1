#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
OUTPUT="$SCRIPT_DIR/package.zip"

echo "Cleaning build directory..."
rm -rf "$BUILD_DIR" "$OUTPUT"
mkdir -p "$BUILD_DIR"

echo "Installing dependencies (targeting Lambda linux/x86_64)..."
pip3 install \
  -r "$SCRIPT_DIR/requirements.txt" \
  -t "$BUILD_DIR" \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.13 \
  --only-binary=:all: \
  --quiet

echo "Copying source code..."
cp -r "$SCRIPT_DIR/shared" "$BUILD_DIR/"
cp -r "$SCRIPT_DIR/categorize" "$BUILD_DIR/"
cp -r "$SCRIPT_DIR/insights" "$BUILD_DIR/"
cp -r "$SCRIPT_DIR/report_insights" "$BUILD_DIR/report_insights/"

echo "Creating deployment package..."
cd "$BUILD_DIR"
zip -r "$OUTPUT" . -x "*.pyc" "__pycache__/*" "*.dist-info/*" --quiet

echo "Package created: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
