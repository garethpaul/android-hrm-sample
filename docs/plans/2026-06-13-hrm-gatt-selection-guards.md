# HRM GATT Selection Guards

Status: Completed

## Priority

The GATT child-click callback indexes the mutable service and characteristic
lists directly and then calls the bound BLE service. A stale callback position,
missing group, missing characteristic, or disconnected service can therefore
crash the activity instead of leaving the selection unhandled.

## Requirements

- **R1:** Reject missing BLE service state before characteristic operations.
- **R2:** Reject negative or out-of-range group and child positions before list
  access.
- **R3:** Reject missing characteristic groups or entries.
- **R4:** Preserve valid read/notify bitmask behavior, notification replacement,
  and all existing BLE, lifecycle, manifest, build, and privacy behavior.
- **R5:** Add fail-closed SDK-free contracts, documentation, hostile mutations,
  and truthful local and hosted verification evidence.

## Implementation Units

### U1: Validate GATT Selection State

**File:** `Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java`

Validate service availability, group position, child position, group contents,
and the selected characteristic before reading properties or issuing BLE calls.

### U2: Protect The Callback Contract

**File:** `scripts/check-baseline.sh`

Bind each guard to the child-click callback and preserve the existing property
bitmask and notification behavior.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
`docs/plans/2026-06-13-hrm-gatt-selection-guards.md`

Document the stale-selection boundary and record exact verification.

## Test Scenarios

- Valid readable and notifiable characteristics retain existing behavior.
- Missing service state returns `false` without dereferencing the service.
- Negative or out-of-range group and child positions return `false` before
  list access.
- Missing groups or characteristic entries return `false`.
- Removing a guard, restoring direct nested indexing, changing bitmask tests,
  removing guidance, or reverting plan completion fails verification.

## Scope Boundaries

- Do not change scanning, connection ownership, broadcast actions, GATT packet
  parsing, permissions, exports, dependencies, or SDK versions.
- Do not claim BLE peripheral, emulator, or physical-device behavior without a
  compatible runtime.

## Verification

- An isolated SDK-backed `make check` passed the SDK-free baseline, zero-issue
  debug/release Android lint, debug/release Java compilation and checks, and
  debug APK assembly. Existing deprecation and unchecked compiler notes remain.
- Eight hostile mutations were rejected across service, group, child,
  characteristic, and completed-plan guards.
- Canonical and external-directory SDK-backed `make check` both passed against
  the exact completed implementation with the same static, lint, compilation,
  check, and APK assembly coverage.

## Sources

- Android `ExpandableListView.OnChildClickListener` API:
  https://developer.android.com/reference/android/widget/ExpandableListView.OnChildClickListener
- Android `BluetoothGattCharacteristic` API:
  https://developer.android.com/reference/android/bluetooth/BluetoothGattCharacteristic
