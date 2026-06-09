---
title: HRM Broadcast Privacy
type: security
status: completed
date: 2026-06-09
---

# HRM Broadcast Privacy

## Problem Frame

The BLE service delivered GATT state and data updates as implicit broadcasts.
Those broadcasts can include heart-rate measurements through `EXTRA_DATA`.
The same path also wrote exact heart-rate values to debug logs.

## Scope Boundaries

- Preserve the existing dynamic receiver flow in `DeviceControlActivity`.
- Keep current GATT action strings and intent extras stable.
- Do not redesign BLE parsing or modernize Android permissions in this pass.
- Keep verification available without BLE hardware.

## Implementation Units

### U1: Scope GATT Broadcasts

Files:

- Modify `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Approach:

- Centralize GATT update intent creation in the service.
- Set the intent package to the app package before sending broadcasts.
- Reuse the helper for connection, disconnection, service discovery, and data
  broadcasts.

### U2: Sanitize Heart-Rate Logging

Files:

- Modify `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Approach:

- Keep a diagnostic that a heart-rate measurement arrived.
- Stop writing the exact heart-rate value to debug logs.
- Preserve the existing in-app `EXTRA_DATA` delivery for the UI.

### U3: Cover And Document The Contract

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Add SDK-free checks for package-scoped broadcast intents and sanitized logging.
- Document the GATT broadcast privacy boundary in project notes.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
