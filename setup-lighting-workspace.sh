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

# Reuse the verified Python/west environment from the existing v0.3 workspace,
# but never reuse its west topdir or ZEPHYR_BASE.
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
    # A failed previous init can leave an empty/partial directory behind.
    # It is safe to remove only when it is not a west workspace yet.
    if [[ -d "$WORKSPACE" ]]; then
        echo "Removing partial workspace from previous failed init: $WORKSPACE"
        rm -rf "$WORKSPACE"
    fi

    mkdir -p "$(dirname "$WORKSPACE")"
    echo "Initializing isolated Corne Lighting workspace: $WORKSPACE"

    # west refuses to initialize a second workspace when invoked from inside an
    # already initialized workspace. Run init from $HOME, which is outside the
    # existing ~/zmk-dev/v0.3/zmk west topdir. The positional directory form is
    # compatible with the older west CLI in the verified v0.3 environment.
    (
        cd "$HOME"
        "$WEST" init \
            -m "$MANIFEST_URL" \
            --mr main \
            "$WORKSPACE"
    )
fi

echo "Updating ZMK + Lighting modules..."
(
    cd "$WORKSPACE"
    "$WEST" update
)

[[ -d "$WORKSPACE/zmk/app" ]] || fail "ZMK project missing after west update: $WORKSPACE/zmk"
[[ -d "$WORKSPACE/modules/zmk-feature-custom-settings" ]] || \
    fail "Custom Settings module missing after west update"

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
