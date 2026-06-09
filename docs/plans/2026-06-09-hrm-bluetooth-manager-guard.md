---
title: HRM Bluetooth Manager Guard
type: reliability
status: completed
date: 2026-06-09
---

# HRM Bluetooth Manager Guard

## Problem Frame

`DeviceScanActivity` reports unsupported BLE devices, but the activity
continued into Bluetooth adapter initialization after calling `finish()`.
It also dereferenced the `BluetoothManager` returned from `getSystemService()`
without checking whether the service was available.

## Scope Boundaries

- Preserve the existing BLE scan flow and UI strings.
- Do not change GATT connection, notification, or characteristic parsing
  behavior.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Exit Unsupported BLE Startup

Files:

- Modify `Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java`

Approach:

- Return immediately after showing the existing unsupported-BLE message and
  finishing the activity.
- Guard a missing `BluetoothManager` service with the existing unsupported
  Bluetooth message, `finish()`, and `return`.

### U2: Cover The Startup Guard

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Add an SDK-free source contract for the `BluetoothManager` null check.
- Keep the guard with the existing BLE scan startup contracts.

### U3: Document The Behavior

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record that BLE scan startup exits before adapter use when platform Bluetooth
  services are unavailable.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
