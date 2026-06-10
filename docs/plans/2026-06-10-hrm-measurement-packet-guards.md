# HRM Measurement Packet Guards

Status: Completed

## Goal

Decode heart-rate width from the measurement payload and reject truncated GATT
packets without nullable-value crashes.

## Requirements

- Read the heart-rate flags as UINT8 at offset zero.
- Select UINT8 or UINT16 measurement format from flag bit zero.
- Guard missing flag and heart-rate values before unboxing or broadcasting.
- Keep warnings generic and avoid logging health measurements.
- The SDK-free baseline rejects property-based flags and nullable unboxing.
- Root Make targets work outside the checkout and accept either Android SDK
  environment variable.
- Hosted verification uses a fixed runner and cancels superseded runs.

## Implementation

- Replace `getProperties()` flag selection with `getIntValue(FORMAT_UINT8, 0)`.
- Keep parsed values as `Integer` until null checks complete.
- Broadcast the package-scoped update without data when a packet is truncated.
- Extend `scripts/check-baseline.sh` with parser, rooted `Makefile`, and CI
  contracts.
- Pin GitHub Actions to Ubuntu 24.04 and add workflow concurrency.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- packet-parser and automation mutation checks
- shell syntax checks
- `git diff --check`

The Android SDK and BLE hardware are unavailable on this host, so runtime packet
handling still requires verification with a compatible device/toolchain.
