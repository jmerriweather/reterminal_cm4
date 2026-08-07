# Changelog

This project does NOT follow semantic versioning. The version increases as
follows:

1. Major version updates are breaking updates to the build infrastructure.
   These should be very rare.
2. Minor version updates are made for every major Buildroot release. This
   may also include Erlang/OTP and Linux kernel updates. These are made four
   times a year shortly after the Buildroot releases.
3. Patch version updates are made for Buildroot minor releases, Erlang/OTP
   releases, and Linux kernel updates. They're also made to fix bugs and add
   features to the build infrastructure.

## v1.2.5

Fixes the web process crash around cross-site navigations:

    wl_display#1: error 0: invalid object 12
    (WPEWebProcess:497): WPE-FDO-ERROR **: Failed to bind wl_compositor

WPEBackend-fdo offers `zwp_linux_dmabuf_v1` at version 4 but implements
`get_surface_feedback` as an empty stub, so no server-side resource exists for
the id the client allocated. Mesa 25.2 and newer use per-surface feedback and
destroy that object when a surface goes away, which makes libwayland-server post
`wl_display.error(invalid object)` — fatal for the whole connection, not just the
object. The next view target on that connection binds no `wl_compositor` and
aborts the web process.

* Changes
  * `patches/wpebackend-fdo/0001-linux-dmabuf-implement-per-surface-feedback.patch`:
    answer per-surface feedback with the default feedback's tranches. The
    protocol allows it — per-surface feedback is an optimisation hint.
  * `nerves_defconfig`: `BR2_GLOBAL_PATCH_DIR` gained
    `$(NERVES_DEFCONFIG_DIR)/patches` so this system can carry patches of its own.
  * `mix.exs`: added `patches` to `package_files/0`, so patch-only changes
    invalidate the artifact checksum. Note that `package` and `external.mk` are
    still missing there — out-of-tree kernel module changes do not bump the
    checksum today.

See `docs/wpe-fdo-surface-feedback-crash.md` in the monorepo for the protocol
trace. The bug is still present upstream on WPEBackend-fdo `main`.

## v1.2.4

Makes the browser fast by default — the same three changes as reterminal_dm_cm4
v1.2.5, ported over. Profiled on the reTerminal DM (same SoC): image-heavy
pages ran at ~30 fps with the CPU rasterizing and the GPU idle; with these
defaults the same pages hold ~60 fps (p50 frame time 17 ms) and touch flicks
feel fluid.

* Changes
  * `rootfs_overlay/etc/erlinit.config`: set `WEBKIT_SKIA_GPU_PAINTING_THREADS=4`
    system-wide. Without it, WPE WebKit 2.50's Skia paints on the CPU with
    `nCores/2` worker threads while the v3d GPU idles. Every app that launches
    Cog inherits the variable through the BEAM's environment and can still
    override it per launch. Note for apps that set their own
    `config :nerves, :erlinit` overrides: Nerves merges against the system
    *source* in `deps/`, so those apps pick this default up once they depend on
    this release.
  * `linux-6.18.defconfig`: default the cpufreq governor to `performance`
    (`CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE`). `schedutil` idles at 600 MHz
    and oscillates between 1.3 and 2.0 GHz under scroll load; measured p50
    frame time was 27 ms vs 17 ms with `performance`. Kiosks on mains power
    have no reason to save that energy; `schedutil` remains available at
    runtime via sysfs.
  * `linux-6.18.defconfig`: enable `CONFIG_TRANSPARENT_HUGEPAGE`, which the v3d
    driver uses for Super Pages (fewer GPU-MMU TLB misses on large textures).
    The boot log's "Transparent Hugepage support is recommended" warning turns
    into "Using Transparent Hugepages".
  * `README.md`: new "Rendering Performance" section documenting the three
    defaults and a known WPE 2.50 limitation (`box-shadow` on scrolling content
    stalls the rendering pipeline regardless of settings — analysis in the
    chromasurf monorepo under `docs/wpe-box-shadow-raf-stall.md`).
    `examples/kiosk_drm.ex` notes that GPU painting needs no per-app env entry.

## v1.2.3

Makes a firmware that fails to boot say so, plus the Cog-on-DRM kiosk example
that had been sitting unreleased since v1.2.2.

* Changes
  * `rootfs_overlay/etc/erlinit.config`: send the IEx prompt to `ttyS0` instead
    of `tty1`. On a kiosk Cog owns the DRM device, so a prompt on `tty1` cannot
    be reached — and since everything the VM writes follows this setting, crash
    reports went there too. A firmware that died during boot was
    indistinguishable from one with a black screen. The headless sibling
    (`recomputer_r100x_cm4`) has always been on `ttyS0`; a display Cog has taken
    over is no more reachable than no display at all. `-s /usr/bin/nbtty` now
    also matches what its own comment says it is for. Downstream can put it back
    with `config :nerves, :erlinit, ctty: "tty1"`.
  * `cmdline-a.txt` / `cmdline-b.txt`: `loglevel=0` → `loglevel=7`. At 0 even a
    kernel failure during early boot is silent, before Erlang starts and
    `nerves_logging`'s kmsg tailer can pick anything up. The kernel console is on
    `tty3`, so this does not reach the panel and the kiosk stays clean.
  * `examples/kiosk_drm.ex`: the Cog-on-DRM kiosk pipeline, documented as an
    example — merged after v1.2.2 but never released.

Both console changes were found while bringing up `myelin_demo` on the DM
variant, where a broken release stayed invisible for a day because the console
pointed at a display the browser had taken over. The same fix ships there as
v1.2.4.

## v1.2.2

Build tooling — no functional changes to the image.

* Changes
  * macOS builds can now run in an Apple `container` Linux VM (no Docker or
    remote build server needed) via
    [nerves_container](https://github.com/chromasurf/nerves_container) — it is
    auto-selected on Apple Silicon and falls back to Docker otherwise. Upstream
    support is proposed in nerves-project/nerves#1190.

## v1.2.1

Documentation-only update — no functional changes to the image.

* Changes
  * README: add a device photo, correct the kernel documentation (Linux 6.18,
    `linux-6.18.defconfig`), document the OTP 29 / Elixir 1.20+ requirement,
    and clarify that an OOM-killed build resumes by re-running `mix compile`.

## v1.2.0

Minor update for a major Buildroot release: tracks `nerves_system_br` v1.34.0
and `kiosk_system_rpi4` v2.1.0, bringing a new Erlang/OTP, Linux kernel, and
toolchain.

**Breaking for downstream:** the image now ships Erlang/OTP 29, so consuming
projects must build with OTP 29 (Elixir 1.20+). Devices using a NervesKey /
ATECC608 must update `nerves_key_pkcs11` to `~> 1.3` to avoid a TLS segfault.

* Changes
  * Use Liberation fonts as the default sans-serif/serif/monospace families
    (fontconfig aliases, from `kiosk_system_rpi4` v2.1.0) — fixes rendering
    issues in WebKit.
  * Remove the `pigpio` package — dropped upstream in Buildroot 2026.05 (no
    longer maintained). Use `libgpiod` / `circuits_gpio` for GPIO.

* Updated dependencies
  * [nerves_system_br v1.34.0](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.34.0)
    (Erlang/OTP 29.0.2, Buildroot 2026.05, GCC 15.3.0)
  * Linux kernel 6.18 (Raspberry Pi `stable_20260527` tag), RPi firmware 1.20260521

## v1.1.4

Security/bug fix update that tracks `nerves_system_br` v1.33.9 (up from
v1.33.4) and pulls in the relevant `kiosk_system_rpi4` v2.0.x refinements.

* Changes
  * Switch the runtime cgroup hierarchy to cgroup v2 — kernel config (PSI,
    CFS bandwidth) plus an `erlinit` `cgroup2` mount — and re-enable the memory
    controller with `cgroup_enable=memory cgroup_memory=1` on the kernel command
    line.
  * Trim unused Weston shells (fullscreen, IVI, screenshare) and the GStreamer
    WPE plugin to shrink the image; only the kiosk shell is used.
  * Enable `shared-mime-info` for WebKit web inspector support.

* Updated dependencies
  * [nerves_system_br v1.33.9](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.33.9)
    (Erlang/OTP 28.5.0.1, Buildroot 2025.11.3, fwup 1.16.0, glibc 2.43
    compatibility fix, Raspberry Pi WiFi roaming patch)

## Earlier releases

Detailed notes for v1.1.3 and earlier live in the
[GitHub releases](https://github.com/chromasurf/reterminal-cm4/releases):
v1.1.3, v1.1.2, v1.1.1, v1.1.0, v1.0.1, v1.0.0.
