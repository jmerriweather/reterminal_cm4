# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Custom Nerves system (`frio_rpi4`) for Raspberry Pi 4 / CM4-based Seeed Studio devices (reTerminal, reTerminal DM, reComputer R100x). Built on `nerves_system_br` (Buildroot), it produces a complete Linux firmware image with WPE WebKit/Cog browser, GPU acceleration (Mesa V3D), and custom kernel drivers for device-specific hardware.

The app name is `:frio_rpi4`, published under the `formrausch` GitHub org.

## Build Commands

```bash
# Fetch deps
mix deps.get

# Build the system (long — compiles Buildroot, Linux kernel, WebKit, etc.)
mix compile

# Regenerate fwup.conf from template
mix generate_fwup_conf

# Lint the system configuration
mix nerves_system_linter
```

Building requires the Nerves toolchain and can take a very long time (WebKit compilation is particularly slow and memory-hungry — retry on OOM).

Prebuilt artifacts are published as GitHub releases and used by downstream projects automatically.

## Architecture

### Multi-Device Support

The system supports three hardware variants via a single image. Device selection happens at firmware-build time through `config.txt` and `cmdline.txt` — downstream projects override these boot partition files per-device:

- **reTerminal** — 720x1280 DSI display, `dtoverlay=reTerminal`
- **reTerminal DM** — 800x1280 DSI display, `dtoverlay=reTerminal-DM` (default in `config.txt`)
- **reComputer R100x** — headless gateway, `dtoverlay=reComputer-R100x`

The `RETHING` env var in `fwup.conf` selects which device's config to pull from the consuming app's `config/nerves/${RETHING}/` directory.

### Custom Kernel Modules (`package/`)

Out-of-tree kernel modules for Seeed hardware, each with standard Buildroot `Config.in` + `.mk` packaging:

| Package | Purpose |
|---------|---------|
| `rethings` | Shared reThings device tree overlays |
| `mipi-dsi` | DSI display driver (reTerminal) |
| `ch34x` | USB-serial adapter (reTerminal DM) |
| `ltr30x` | Light sensor |
| `lis3lv02d` | Accelerometer |
| `bq24179_charger` | Battery charger (reTerminal) |
| `rtc-pcf8563w` | RTC (reTerminal DM, reComputer) |

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
- `config.txt` / `cmdline.txt` — RPi boot config (device-specific overlays, display rotation, GPIO)
- `rootfs_overlay/etc/erlinit.config` — Erlang VM init (console, mounts, hostname)
- `rootfs_overlay/etc/modprobe.d/blacklist.conf` — blacklisted kernel modules (`cdc_acm`)

### CI

CircleCI (`.circleci/config.yml`) using `nerves-project/build-tools` orb. Deploys to GitHub releases on version tags (`v*`).
