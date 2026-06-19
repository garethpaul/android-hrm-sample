# Repository Guidance

## Purpose

This repository is a legacy Android Bluetooth LE heart-rate sample. Preserve
the scan, connect, service-discovery, notification, and display flow while
making asynchronous ownership and failure paths explicit.

## Commands

- Run the portable source contracts with `make lint`.
- Run the maintained Android gate with `make check` and a configured Java 8,
  Android SDK, and API 22 platform.
- Run the same gate from an external directory when changing Make or scripts.

## Engineering Boundaries

- Keep BLE identifiers and heart-rate values out of routine logs.
- Keep only the launcher activity exported; the control activity and BLE
  service remain app-internal.
- Reject stale GATT callbacks before mutating current connection state.
- BLE scan-list selections reject unavailable adapters and out-of-range positions before device lookup.
- Keep generated Gradle, build, APK, IDE, and local SDK files out of commits.
- Do not claim emulator, physical-device, or live BLE verification unless it
  was actually executed and recorded in `DEVICE_VERIFICATION.md`.

## Change Discipline

- Add or update `docs/plans/` for behavioral changes.
- Extend `scripts/check-baseline.sh` with mutation-sensitive contracts.
- Preserve the legacy dependency and API baseline unless a dedicated,
  behavior-tested modernization plan explicitly changes it.
