---
title: HRM Heart Rate Characteristic Match
type: correctness
status: completed
date: 2026-06-09
---

# HRM Heart Rate Characteristic Match

## Problem Frame

`DeviceControlActivity` identifies the heart-rate measurement characteristic by
comparing the looked-up display label with `==`. Java string identity is not a
safe value comparison, so notification setup can depend on whether the label is
the same object rather than the same value.

## Scope Boundaries

- Preserve the existing service-discovery flow and notification behavior.
- Do not add heart-rate parsing, permission changes, BLE lifecycle changes, or
  dependency updates in this pass.
- Keep verification available without BLE hardware.

## Implementation Units

### U1: Match The Standard UUID

Files:

- Modify `Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java`

Approach:

- Compare the characteristic UUID against `SampleGattAttributes.HEART_RATE_MEASUREMENT`.
- Reuse the already looked-up display name when populating the characteristic
  row data.
- Remove the `== "Heart Rate Measurement"` identity comparison.

### U2: Extend SDK-Free Baseline Checks

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert that heart-rate measurement matching uses the standard UUID constant.
- Assert that Java string identity comparison is absent for the heart-rate
  label.

### U3: Document The Contract

Files:

- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- Record that the baseline protects heart-rate characteristic matching.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

BLE runtime verification still requires suitable hardware.
