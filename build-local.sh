#!/usr/bin/env bash
set -euo pipefail

# Corne v2 + original BLE Micro Pro
# Local build helper for the existing ZMK v0.3 workspace.
#
# Usage:
#   ./build-local.sh          # left + right
#   ./build-local.sh all
#   ./build-local.sh left
#   ./build-local.sh right
#   ./build-local.sh reset

TARGET="${1:-all}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ZMK_WORKSPACE:-$HOME/zmk-dev/v0.3}"
ZMK_DIR="${ZMK_DIR:-$WORKSPACE/zmk}"
WEST="${WEST:-$WORKSPACE/.venv/bin/west}"
BUILD_ROOT="${BUILD_ROOT:-$WORKSPACE/build/corne-v2-bmp}"
COPY_UF2="${COPY_UF2:-$HOME/bin/copy-uf2}"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -d "$ZMK_DIR/app" ]] || fail "ZMK v0.3 app directory not found: $ZMK_DIR/app"
[[ -x "$WEST" ]] || fail "west not found/executable: $WEST"
[[ -f "$PROJECT_DIR/config/corne.conf" ]] || fail "Missing config/corne.conf"
[[ -f "$PROJECT_DIR/config/corne.keymap" ]] || fail "Missing config/corne.keymap"
[[ -d "$PROJECT_DIR/boards/arm/ble_micro_pro" ]] || fail "Missing ble_micro_pro board definition"
[[ -x "$COPY_UF2" ]] || fail "copy-uf2 not found/executable: $COPY_UF2"

mkdir -p "$BUILD_ROOT"

echo "============================================================"
echo " Corne v2 + BLE Micro Pro / ZMK v0.3 local build"
echo "============================================================"
echo "Workspace : $WORKSPACE"
echo "ZMK       : $ZMK_DIR"
echo "Project   : $PROJECT_DIR"
echo "Build     : $BUILD_ROOT"
echo

if [[ -d "$ZMK_DIR/.git" ]]; then
    echo -n "ZMK rev   : "
    git -C "$ZMK_DIR" describe --tags --always --dirty 2>/dev/null || true
    echo -n "ZMK commit: "
    git -C "$ZMK_DIR" rev-parse --short HEAD 2>/dev/null || true
    echo
fi

build_half() {
    local side="$1"
    local shield="$2"
    local out_name="$3"
    local build_dir="$BUILD_ROOT/$side"
    local uf2="$build_dir/zephyr/zmk.uf2"

    echo "------------------------------------------------------------"
    echo "Building $side: board=ble_micro_pro shield=$shield"
    echo "------------------------------------------------------------"

    "$WEST" build \
        -p always \
        -s "$ZMK_DIR/app" \
        -d "$build_dir" \
        -b ble_micro_pro \
        -- \
        -DSHIELD="$shield" \
        -DZMK_CONFIG="$PROJECT_DIR/config" \
        -DBOARD_ROOT="$PROJECT_DIR"

    [[ -f "$uf2" ]] || fail "UF2 was not generated: $uf2"

    echo "Copying UF2 to Windows..."
    "$COPY_UF2" "$uf2" zmk-dev v0.3 corne-v2-bmp "$out_name"
    echo "OK: $out_name"
    echo
}

case "$TARGET" in
    all)
        build_half left  corne_left  corne-v2-bmp-left.uf2
        build_half right corne_right corne-v2-bmp-right.uf2
        ;;
    left)
        build_half left corne_left corne-v2-bmp-left.uf2
        ;;
    right)
        build_half right corne_right corne-v2-bmp-right.uf2
        ;;
    reset)
        build_half reset settings_reset corne-v2-bmp-settings-reset.uf2
        ;;
    *)
        fail "Usage: $0 [all|left|right|reset]"
        ;;
esac

echo "============================================================"
echo "Build complete"
echo "Windows destination: D:\\ZMK-Firmware\\zmk-dev\\v0.3\\corne-v2-bmp"
echo "============================================================"
