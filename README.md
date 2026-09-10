# zmk-config-corne-v2-bmp

ZMK v0.3 configuration for Corne v2 with the original BLE Micro Pro (non-boost) and SK6812MINI RGB LEDs.

## Target

- Corne v2 (Pro Micro compatible)
- Original BLE Micro Pro / BL654 / nRF52840
- ZMK v0.3.x local build workspace: `~/zmk-dev/v0.3`
- Left half: ZMK central, USB HID to PC
- Right half: ZMK peripheral
- Both halves may be USB powered
- RGB: 27 LEDs per half

## Build

Clone this repository under the v0.3 workspace, for example:

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

## Notes

The Corne shield itself is not duplicated here. ZMK v0.3 already provides `corne_left` and `corne_right`. This repository only adds the BLE Micro Pro board definition and keyboard configuration.
