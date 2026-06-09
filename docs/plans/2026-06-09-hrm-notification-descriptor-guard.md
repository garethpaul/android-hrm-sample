---
title: HRM Notification Descriptor Guard
type: reliability
status: completed
date: 2026-06-09
---

# HRM Notification Descriptor Guard

## Problem Frame

`BluetoothLeService.setCharacteristicNotification` enables local notifications,
then writes the heart-rate client characteristic configuration descriptor. The
old path assumed the descriptor always exists and wrote
`ENABLE_NOTIFICATION_VALUE` even when the caller requested notification
disablement.

## Scope Boundaries

- Preserve the existing BLE scan, connection, and characteristic selection flow.
- Do not modernize Android BLE APIs, runtime permissions, Gradle, or support
  libraries in this pass.
- Keep verification available through the SDK-free baseline script and Gradle
  checks when an Android SDK is configured.

## Implementation Units

### U1: Guard Descriptor Writes

Files:

- Modify `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Approach:

- Check whether the client characteristic configuration descriptor exists
  before writing it.
- Log a generic warning and return when the descriptor is unavailable.
- Choose `ENABLE_NOTIFICATION_VALUE` or `DISABLE_NOTIFICATION_VALUE` from the
  `enabled` argument before writing the descriptor.

### U2: Add SDK-Free Contract Coverage

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert that the null descriptor guard stays present.
- Assert that notification disablement can write the BLE disable value.
- Reject the old hardcoded enable-only descriptor write.

### U3: Document The BLE Guardrail

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record the descriptor contract beside the existing UUID matching and scan
  timeout guardrails.
- Keep hardware verification notes separate from this source-level safety pass.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
