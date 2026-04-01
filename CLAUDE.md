# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Custom Nerves system for the Seeed Studio reTerminal (CM4, aarch64). Built on `nerves_system_br` (Buildroot), it produces a complete Linux firmware image with WPE WebKit/Cog browser, GPU acceleration (Mesa V3D), and custom kernel drivers for the reTerminal hardware (DSI display, touchscreen, accelerometer, light sensor, battery charger).

App name: `:chromasurf_reterminal_cm4`, published under the `chromasurf` GitHub org.

## Build Commands

```bash
mix deps.get
mix compile                    # full Buildroot build (very slow — kernel, WebKit, etc.)
mix nerves.artifact            # package as distributable artifact
mix generate_fwup_conf         # regenerate fwup.conf from fwup.conf.eex
mix nerves_system_linter       # lint system configuration
```

Building requires the Nerves toolchain. WebKit compilation is particularly slow and memory-hungry — retry on OOM.

Prebuilt artifacts are published as GitHub releases and used by downstream projects automatically.

## Architecture

### Custom Kernel Modules (`package/`)

Out-of-tree kernel modules for Seeed hardware, each with standard Buildroot `Config.in` + `.mk` packaging:

| Package | Purpose |
|---------|---------|
| `rethings` | Shared reThings device tree overlays |
| `mipi-dsi` | DSI display driver |
| `ltr30x` | Light sensor (LTR-303ALS) |
| `lis3lv02d` | Accelerometer (LIS3DHTR) |
| `bq24179_charger` | Battery charger |
| `rtc-pcf8563w` | RTC (PCF8563W) |

These are wired into Buildroot via `Config.in` and `external.mk`.

### Firmware Layout (fwup)

A/B partition scheme managed by `fwup`:
- `fwup.conf` — main firmware image creation (generated from `fwup.conf.eex` via `mix generate_fwup_conf`)
- `fwup-ops.conf` — runtime operations (factory-reset, revert, validate)
- `fwup_include/fwup-common.conf` — shared partition definitions and metadata
- Rootfs is SquashFS, app data partition is F2FS

### Key Configuration Files

- `nerves_defconfig` — Buildroot defconfig (package selection, kernel, toolchain)
- `linux-6.12.defconfig` — Linux kernel config
- `config.txt` / `cmdline-{a,b}.txt` — RPi boot config (device-specific overlays, display rotation, GPIO)
- `rootfs_overlay/` — files overlaid onto the root filesystem
- `post-build.sh` / `post-createfs.sh` — Buildroot post-build hooks
