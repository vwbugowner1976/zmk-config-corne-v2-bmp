# zmk-config-corne-v2-bmp

ZMK v0.3 configuration for Corne v2 with the original BLE Micro Pro (non-boost), SK6812MINI RGB LEDs, ZMK Studio, and the local `ai-build` workflow.

## Target

- Corne v2 (Pro Micro compatible)
- Original BLE Micro Pro / BL654 / nRF52840
- ZMK v0.3.x local build workspace: `~/zmk-dev/v0.3`
- Verified west topdir: `~/zmk-dev/v0.3/zmk`
- Verified environment setup: `source ~/zmk-dev/v0.3/env.sh`
- Left half: ZMK central, USB HID to PC, ZMK Studio over USB
- Right half: ZMK peripheral
- RGB: 27 LEDs per half

## ZMK Studio

Only the left/central firmware is built with ZMK Studio support.

The build adds:

```text
-S studio-rpc-usb-uart
-DCONFIG_ZMK_STUDIO=y
```

The keymap includes `&studio_unlock` on the far-right home-row key of the Lower layer.

## Initial setup

```bash
cd ~/zmk-dev/v0.3/projects
git clone https://github.com/vwbugowner1976/zmk-config-corne-v2-bmp.git
cd zmk-config-corne-v2-bmp
chmod +x build-local.sh ai-build ai-share
```

For an existing checkout:

```bash
cd ~/zmk-dev/v0.3/projects/zmk-config-corne-v2-bmp
git pull --ff-only
chmod +x build-local.sh ai-build ai-share
```

## Normal build: ai-build

Use `ai-build` as the normal entry point.

Left only:

```bash
./ai-build left
```

Both halves:

```bash
./ai-build all
```

Other targets:

```bash
./ai-build right
./ai-build reset
```

`ai-build` runs `build-local.sh`, captures the complete build log, summarizes errors, and always creates AI-shareable context files.

Generated locally:

```text
.ai/build-YYYYMMDD-HHMMSS.log
.ai/context-YYYYMMDD-HHMMSS.txt
.ai/latest-context.txt
.ai/local-analysis.txt
.ai/share-latest.txt
```

The Windows sharing helper automatically copies `.ai/share-latest.txt` to:

```text
C:\Users\<Windows user>\Downloads\AI-Build\
```

with these names:

```text
zmk-config-corne-v2-bmp-share-latest.txt
zmk-config-corne-v2-bmp-YYYYMMDD-HHMMSS.txt
share-latest.txt
```

The project-specific filename prevents collisions with other projects.

When a build fails, send/upload `zmk-config-corne-v2-bmp-share-latest.txt`; there is no need to paste the full terminal log into ChatGPT.

## Why build-local.sh sources env.sh

For this v0.3 workspace, invoking `/home/stc/zmk-dev/v0.3/.venv/bin/west` directly from the project directory is not enough. The verified flow is:

```bash
cd ~/zmk-dev/v0.3
source env.sh
cd ~/zmk-dev/v0.3/zmk
west topdir
```

Expected topdir:

```text
/home/stc/zmk-dev/v0.3/zmk
```

`build-local.sh` now performs this initialization and validates the topdir before building.

## Direct build-local.sh use

`build-local.sh` remains available for debugging:

```bash
./build-local.sh left
./build-local.sh right
./build-local.sh all
./build-local.sh reset
```

For normal operation, prefer `./ai-build ...` so the diagnostic context is always created.

## Notes

The Corne shield itself is not duplicated here. ZMK v0.3 already provides `corne_left` and `corne_right`. This repository only adds the BLE Micro Pro board definition and keyboard configuration.
