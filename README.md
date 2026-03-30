# Chromasurf — reTerminal CM4

Custom Nerves system for the [Seeed Studio reTerminal](https://wiki.seeedstudio.com/reTerminal/) (CM4, aarch64).

Built on `nerves_system_br` (Buildroot) with WPE WebKit/Cog browser, GPU acceleration (Mesa V3D), and hardware drivers for all reTerminal peripherals.

## Hardware

- 720x1280 DSI display (ILI9881c) with 270° rotation
- Capacitive touchscreen via STM32 MCU bridge
- 3-axis accelerometer (LIS3DHTR)
- Ambient light sensor (LTR-303ALS)
- RTC (PCF8563W)
- Crypto co-processor (ATECC608A)
- TPM 2.0 (Infineon SLB9670)
- Battery charger (BQ24179)
- 4 user buttons, 3 user LEDs, buzzer (via PCA9554 GPIO expander)
- Camera CSI connector
- Gigabit Ethernet, WiFi/BT (disabled by default)

## Usage

```bash
# In your Nerves app's mix.exs:
{:chromasurf_reterminal_cm4, github: "chromasurf/reterminal-cm4", runtime: false, targets: :reterminal_cm4}

# Build firmware
MIX_TARGET=reterminal_cm4 MIX_ENV=prod mix deps.get
MIX_TARGET=reterminal_cm4 MIX_ENV=prod mix firmware
```

## Building the system

Prebuilt artifacts are published as GitHub releases. To build from source:

```bash
mix deps.get
mix compile
mix nerves.artifact
```

WebKit compilation is slow and memory-hungry — retry on OOM.

## Camera

Supports official Raspberry Pi camera modules via `libcamera`. Example:

```elixir
cmd("libcamera-jpeg -n -v -o /data/test.jpeg")
```

## Audio

HDMI and stereo jack output via ALSA. Force HDMI output:

```elixir
cmd("amixer cset numid=3 2")
```

## Provisioning

Key-value store outside any filesystem for device identity:

```elixir
# Set serial number
cmd("fw_setenv nerves_serial_number 12345678")
```

## License

Apache-2.0
