#!/usr/bin/env bash
set -euo pipefail

# Corne v2 + original BLE Micro Pro
# Local build helper for the isolated ZMK v0.3 + DYA workspace.
#
# The original ~/zmk-dev/v0.3 workspace is intentionally left untouched.
# Run ./setup-lighting-workspace.sh once before the first Lighting build.
#
# Usage:
#   ./build-local.sh          # left + right
#   ./build-local.sh all
#   ./build-local.sh left
#   ./build-local.sh right
#   ./build-local.sh led-test-left
#   ./build-local.sh led-test-right
#   ./build-local.sh reset

TARGET="${1:-all}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ZMK_WORKSPACE:-$HOME/zmk-dev/corne-v2-bmp-v03}"
ZMK_DIR="${ZMK_DIR:-$WORKSPACE/zmk}"
ENV_SH="${ZMK_ENV_SH:-$HOME/zmk-dev/v0.3/env.sh}"
BUILD_ROOT="${BUILD_ROOT:-$WORKSPACE/build/corne-v2-bmp}"
COPY_UF2="${COPY_UF2:-$HOME/bin/copy-uf2}"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -d "$ZMK_DIR/app" ]] || fail "Corne Lighting ZMK app directory not found: $ZMK_DIR/app (run ./setup-lighting-workspace.sh)"
[[ -f "$ENV_SH" ]] || fail "Verified v0.3 env.sh not found: $ENV_SH"
[[ -f "$PROJECT_DIR/config/corne.conf" ]] || fail "Missing config/corne.conf"
[[ -f "$PROJECT_DIR/config/corne.keymap" ]] || fail "Missing config/corne.keymap"
[[ -d "$PROJECT_DIR/boards/arm/ble_micro_pro" ]] || fail "Missing ble_micro_pro board definition"
[[ -d "$ZMK_DIR/app/snippets/studio-rpc-usb-uart" ]] || fail "ZMK Studio snippet not found in this ZMK tree"
[[ -x "$COPY_UF2" ]] || fail "copy-uf2 not found/executable: $COPY_UF2"

# Reuse the already verified Python/west + Zephyr SDK environment, but do not
# let an inherited ZEPHYR_BASE force west back into the old workspace.
# shellcheck disable=SC1090
source "$ENV_SH"
unset ZEPHYR_BASE || true

WEST="$(command -v west || true)"
[[ -n "$WEST" ]] || fail "west not found after sourcing $ENV_SH"

ACTUAL_TOPDIR="$(cd "$ZMK_DIR" && west topdir 2>/dev/null || true)"
[[ -n "$ACTUAL_TOPDIR" ]] || fail "west workspace not found from: $ZMK_DIR"
[[ "$ACTUAL_TOPDIR" == "$WORKSPACE" ]] || fail "Unexpected west topdir: $ACTUAL_TOPDIR (expected $WORKSPACE)"

mkdir -p "$BUILD_ROOT"

echo "============================================================"
echo " Corne v2 + BLE Micro Pro / ZMK v0.3 DYA local build"
echo "============================================================"
echo "Workspace : $WORKSPACE"
echo "ZMK       : $ZMK_DIR"
echo "West      : $WEST"
echo "West top  : $ACTUAL_TOPDIR"
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
    local studio="$4"
    local led_test="${5:-no}"
    local build_dir="$BUILD_ROOT/$side"
    local uf2="$build_dir/zephyr/zmk.uf2"
    local -a args

    echo "------------------------------------------------------------"
    echo "Building $side: board=ble_micro_pro shield=$shield studio=$studio led_test=$led_test"
    echo "------------------------------------------------------------"

    args=(
        build
        -p always
        -s "$ZMK_DIR/app"
        -d "$build_dir"
        -b ble_micro_pro
    )

    if [[ "$studio" == "yes" ]]; then
        args+=( -S studio-rpc-usb-uart )
    fi

    args+=(
        --
        -DSHIELD="$shield"
        -DZMK_CONFIG="$PROJECT_DIR/config"
        -DBOARD_ROOT="$PROJECT_DIR"
    )

    if [[ "$studio" == "yes" ]]; then
        args+=(
            -DCONFIG_ZMK_STUDIO=y
            -DCONFIG_ZMK_CUSTOM_SETTINGS_STUDIO_RPC=y
            -DCONFIG_ZMK_STUDIO_RPC_RX_BUF_SIZE=128
            -DCONFIG_ZMK_STUDIO_RPC_CUSTOM_SUBSYSTEM_REQUEST_PAYLOAD_MAX_BYTES=96
        )
    fi

    if [[ "$led_test" == "yes" ]]; then
        args+=( -DCONFIG_ZMK_CORNE_LIGHTING_LED_TEST=y )
    fi

    (
        cd "$ACTUAL_TOPDIR"
        west "${args[@]}"
    )

    [[ -f "$uf2" ]] || fail "UF2 was not generated: $uf2"

    echo "Copying UF2 to Windows..."
    "$COPY_UF2" "$uf2" zmk-dev v0.3 corne-v2-bmp "$out_name"
    echo "OK: $out_name"
    echo
}

case "$TARGET" in
    all)
        build_half left  corne_left  corne-v2-bmp-left.uf2  yes no
        build_half right corne_right corne-v2-bmp-right.uf2 no  no
        ;;
    left)
        build_half left corne_left corne-v2-bmp-left.uf2 yes no
        ;;
    right)
        build_half right corne_right corne-v2-bmp-right.uf2 no no
        ;;
    led-test-left)
        build_half led-test-left corne_left corne-v2-bmp-led-test-left.uf2 yes yes
        ;;
    led-test-right)
        build_half led-test-right corne_right corne-v2-bmp-led-test-right.uf2 no yes
        ;;
    reset)
        build_half reset settings_reset corne-v2-bmp-settings-reset.uf2 no no
        ;;
    *)
        fail "Usage: $0 [all|left|right|led-test-left|led-test-right|reset]"
        ;;
esac

echo "============================================================"
echo "Build complete"
if [[ "$TARGET" == led-test-* ]]; then
    echo "LED TEST: LEDs 1-27 stay on together at low-brightness white."
else
    echo "Left firmware includes ZMK Studio + Custom Settings RPC."
fi
echo "============================================================"
