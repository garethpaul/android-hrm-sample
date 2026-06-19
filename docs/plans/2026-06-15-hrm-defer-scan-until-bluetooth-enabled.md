# Defer HRM Scan Until Bluetooth Is Enabled

Status: Completed

## Context

`DeviceScanActivity.onResume` launches Android's `ACTION_REQUEST_ENABLE` flow
when the adapter is disabled, but then continues initializing the list and
calling `scanLeDevice(true)` in the same lifecycle pass. The scan therefore
runs while Bluetooth is still disabled and can show the scan-start failure
message behind or alongside the system enable dialog.

Android's Bluetooth setup guidance requires requesting enablement through
`startActivityForResult` before using Bluetooth operations:
<https://developer.android.com/develop/connectivity/bluetooth/setup#enable>.
The BLE overview likewise describes determining Bluetooth availability before
scanning:
<https://developer.android.com/develop/connectivity/bluetooth/ble/ble-overview>.

## Priorities

1. Do not attempt a BLE scan while the enable-Bluetooth system flow is active.
2. Preserve automatic scanning when the adapter is already enabled and after a
   successful enable flow returns through the normal activity lifecycle.
3. Preserve cancellation handling, explicit scan controls, scan timeout
   ownership, and the existing scan-start failure path for genuine failures.

## Requirements

1. Launch `ACTION_REQUEST_ENABLE` once when the adapter is disabled and return
   from `onResume` before adapter-list initialization or scan startup.
2. Remove the redundant nested enabled-state check.
3. Preserve the canceled-result finish path and enabled-adapter scan behavior.
4. Add mutation-sensitive source ordering, guidance, and completed-plan
   contracts.

## Scope Boundaries

- Do not migrate the legacy scan API, change permissions, alter scan duration,
  change result handling, or add a second scan trigger in `onActivityResult`.
- Do not change BLE GATT connection, service discovery, notification, or
  descriptor behavior.
- Do not claim emulator, physical-device, or live BLE-peripheral verification.

## Implementation Units

### U1: Return after requesting Bluetooth enablement

**File:** `Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java`

Collapse the duplicate disabled-adapter condition, launch the existing system
intent, and return before list initialization and `scanLeDevice(true)`.

### U2: Protect the lifecycle boundary

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
`CHANGES.md`, and this plan.

Require the enable intent, immediate return, ordering before list setup and
scan startup, preserved canceled-result handling, maintained guidance, and
completed verification evidence.

## Verification

- Run POSIX shell syntax and the focused portable baseline.
- Run repository and external-directory `make check`, using the configured
  Java 8 and Android API 22 SDK when available.
- Reject isolated intent, return, ordering, duplicate-condition, cancellation,
  guidance, and plan-completion mutations.
- Audit exact intended paths, generated Gradle artifacts, conflict markers,
  dependency and workflow drift, whitespace, and credential-shaped additions.

## Risks

- Runtime confirmation still requires an emulator or device with Bluetooth
  initially disabled; `DEVICE_VERIFICATION.md` remains the authority for that
  manual scenario.
- The branch remains stacked on PR #16 and must retain base-first ordering.

## Verification Completed

- Collapsed the duplicate disabled-adapter branch and returned immediately
  after launching the existing `ACTION_REQUEST_ENABLE` system flow.
- Preserved automatic scanning for an enabled adapter, the canceled-result
  finish path, explicit scan controls, timeout ownership, and genuine scan
  startup failure handling.
- Amazon Corretto 8 and the configured Android API 22 SDK compiled debug and
  release Java sources, ran Gradle checks, completed Android lint, and assembled
  the debug APK successfully.
- Repository-root and external-directory SDK-backed `make check` gates passed;
  the portable POSIX baseline also passed independently.
- Nine isolated hostile mutations were rejected for the enable intent, early
  return, source ordering, duplicate condition, canceled-result finish and return,
  maintained guidance, plan status, and verification evidence.
- Exact-path diff, generated Gradle artifact, conflict-marker, dependency and
  workflow drift, whitespace, and credential-shaped-addition audits passed.
- No emulator, physical Android device, or live BLE peripheral was exercised;
  runtime verification remains explicit in `DEVICE_VERIFICATION.md`.
