---
title: HRM GATT Property Checks
type: fix
status: completed
date: 2026-06-08
---

# HRM GATT Property Checks

## Summary

Fix the selected-characteristic read and notify checks so the app only performs
GATT operations supported by the characteristic, and guard the regression in the
existing SDK-free baseline check.

---

## Problem Frame

`DeviceControlActivity` checks characteristic capabilities with bitwise OR:
`(charaProp | PROPERTY_READ) > 0` and `(charaProp | PROPERTY_NOTIFY) > 0`.
Because the property constants are non-zero, those expressions can be true even
when the characteristic does not advertise the corresponding capability.

---

## Requirements

- R1. The read branch must test `PROPERTY_READ` with bitwise AND.
- R2. The notify branch must test `PROPERTY_NOTIFY` with bitwise AND.
- R3. No OR-based GATT property checks may remain.
- R4. The SDK-free baseline script must fail if the OR checks are reintroduced.
- R5. The existing build baseline must continue to assemble.

---

## Key Technical Decisions

- **Change only the operator:** Keep the selected-characteristic flow and branch
  bodies unchanged.
- **Reuse the existing source gate:** Extending `scripts/check-baseline.sh`
  avoids adding a test framework to this legacy Android sample.
- **Keep BLE behavior otherwise untouched:** Scanning, connection lifecycle,
  heart-rate parsing, and UI behavior remain outside this pass.

---

## Scope Boundaries

- This pass does not change Bluetooth permissions, scanning, GATT connection
  lifecycle, service discovery, or display formatting.
- This pass does not update dependencies or Android SDK levels.
- This pass does not add emulator, device, or BLE hardware tests.

---

## Implementation Units

### U1. Correct Property Operators

- **Goal:** Run read and notify branches only for characteristics that support those capabilities.
- **Files:** `Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java`
- **Patterns:** Preserve the existing `OnChildClickListener` structure.
- **Test Scenarios:**
  - Read check uses `charaProp & BluetoothGattCharacteristic.PROPERTY_READ`.
  - Notify check uses `charaProp & BluetoothGattCharacteristic.PROPERTY_NOTIFY`.
  - OR-based checks are absent.
- **Verification:** `scripts/check-baseline.sh`

### U2. Guard the Regression

- **Goal:** Make the bug easy to catch without BLE hardware.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** Fail fast with explicit messages.
- **Test Scenarios:**
  - Script fails if the read OR check returns.
  - Script fails if the notify OR check returns.
  - Script verifies both AND checks are present.
- **Verification:** `scripts/check-baseline.sh`, `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`

---

## Risks & Dependencies

- Full runtime validation still requires a BLE heart-rate peripheral or emulator/device setup capable of exercising GATT interactions.
- The project remains on its legacy Android Gradle Plugin and support library stack.

---

## Sources / Research

- `Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java`
  contains the selected-characteristic read and notify capability checks.
- `scripts/check-baseline.sh` is the existing SDK-free quality gate.
