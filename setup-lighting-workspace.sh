#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ZMK_WORKSPACE:-$HOME/zmk-dev/corne-v2-bmp-v03}"
ENV_SH="${ZMK_ENV_SH:-$HOME/zmk-dev/v0.3/env.sh}"
MANIFEST_URL="https://github.com/vwbugowner1976/zmk-config-corne-v2-bmp"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -f "$ENV_SH" ]] || fail "Verified v0.3 env.sh not found: $ENV_SH"

# shellcheck disable=SC1090
source "$ENV_SH"
unset ZEPHYR_BASE || true
WEST="$(command -v west || true)"
[[ -n "$WEST" ]] || fail "west not found after sourcing $ENV_SH"

if [[ -d "$WORKSPACE/.west" ]]; then
    echo "Workspace already initialized: $WORKSPACE"
    if [[ -d "$WORKSPACE/config/.git" ]]; then
        echo "Updating workspace manifest clone..."
        git -C "$WORKSPACE/config" pull --ff-only
    fi
else
    mkdir -p "$(dirname "$WORKSPACE")"
    echo "Initializing isolated Corne Lighting workspace: $WORKSPACE"
    "$WEST" init \
        -m "$MANIFEST_URL" \
        --mr main \
        --mf config/west.yml \
        -t "$WORKSPACE"
fi

echo "Updating ZMK + Lighting modules..."
(
    cd "$WORKSPACE"
    "$WEST" update
)

[[ -d "$WORKSPACE/zmk/app" ]] || fail "ZMK project missing after west update: $WORKSPACE/zmk"

ACTUAL_TOPDIR="$(cd "$WORKSPACE/zmk" && "$WEST" topdir)"
[[ "$ACTUAL_TOPDIR" == "$WORKSPACE" ]] || fail "Unexpected west topdir: $ACTUAL_TOPDIR"

echo
 echo "============================================================"
echo "Corne Lighting workspace ready"
echo "Workspace : $WORKSPACE"
echo "ZMK       : $WORKSPACE/zmk"
echo "ZMK commit: $(git -C "$WORKSPACE/zmk" rev-parse --short HEAD)"
echo "Project   : $PROJECT_DIR"
echo "============================================================"
echo "Next: ./ai-build left"
