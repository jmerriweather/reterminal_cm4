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
