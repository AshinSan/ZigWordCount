#!/bin/sh

set -e

APP_NAME="zwc"
OUT_DIR="release"
BUILD_TYPES="ReleaseFast"

# Clean previos builds

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

build() {
    TARGET="$1"
    EXT="$2"
    OUTPUT="$APP_NAME-$TARGET$EXT"

    echo "Building for $TARGET..."
    zig build -Dtarget=$TARGET -Doptimize=ReleaseFast

    BIN_PATH="zig-out/bin/${APP_NAME}${EXT}"
    cp "$BIN_PATH" "$OUT_DIR/$OUTPUT"
    (cd "$OUT_DIR" && zip "$OUTPUT.zip" "$OUTPUT")
    rm "$OUT_DIR/$OUTPUT"
}

# Linux x86_64
build "x86_64-linux" ""

# Windows x86_64
build "x86_64-windows" ".exe"

# macOS Intel
build "x86_64-macos" ""

# macOS Apple Silicon
build "aarch64-macos" ""

echo "All builds complete. Files are in $OUT_DIR/"