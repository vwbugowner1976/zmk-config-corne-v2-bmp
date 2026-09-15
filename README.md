# zmk-config-corne-v2-bmp

ZMK v0.3 configuration for Corne v2 with the original BLE Micro Pro (non-boost), SK6812MINI RGB LEDs, and ZMK Studio support.

## Target

- Corne v2 (Pro Micro compatible)
- Original BLE Micro Pro / BL654 / nRF52840
- ZMK v0.3.x local build workspace: `~/zmk-dev/v0.3`
- Left half: ZMK central, USB HID to PC, ZMK Studio over USB
- Right half: ZMK peripheral
- Both halves may be USB powered
- RGB: 27 LEDs per half

## ZMK Studio

Only the left/central firmware is built with ZMK Studio support.

The local build script adds:

```text
-S studio-rpc-usb-uart
-DCONFIG_ZMK_STUDIO=y
```

The keymap includes `&studio_unlock` on the far-right home-row key of the Lower layer.

To unlock Studio:

1. Hold the left thumb Lower key.
2. Press the far-right home-row key.
3. Connect the left half to ZMK Studio over USB.

The keymap also includes three reserved layers (`Extra 1` to `Extra 3`) that can be enabled and edited from ZMK Studio.

After Studio has stored runtime keymap changes, later edits to `corne.keymap` will not automatically replace them. Use **Restore Stock Settings** in ZMK Studio when you want the compiled keymap to become active again.

## Build

Clone this repository under the v0.3 workspace:

```bash
cd ~/zmk-dev/v0.3
mkdir -p projects
cd projects
git clone https://github.com/vwbugowner1976/zmk-config-corne-v2-bmp.git
cd zmk-config-corne-v2-bmp
chmod +x build-local.sh
./build-local.sh
```

The script builds left and right firmware with the existing ZMK v0.3 workspace and copies UF2 files to Windows using `~/bin/copy-uf2`.

## Build targets

```bash
./build-local.sh all
./build-local.sh left
./build-local.sh right
./build-local.sh reset
```

`left` includes ZMK Studio. `right` and `reset` do not.

## Notes

The Corne shield itself is not duplicated here. ZMK v0.3 already provides `corne_left` and `corne_right`. This repository only adds the BLE Micro Pro board definition and keyboard configuration.
