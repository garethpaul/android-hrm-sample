---
title: HRM Scan Timeout Contracts
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# HRM Scan Timeout Contracts

## Problem Frame

`DeviceScanActivity` posts an anonymous delayed stop callback every time scanning
starts. Pause and device-selection paths stop scanning, but they cannot cancel
that anonymous delayed callback. A stale callback can later run after scanning
has already stopped or after navigation to the device-control screen.

## Scope Boundaries

- Preserve the existing BLE scan duration and UI flow.
- Do not migrate BLE APIs, runtime permissions, Gradle, or support libraries.
- Keep verification SDK-free for this pass.

## Implementation Units

### U1: Cancellable Scan Timeout

Files:

- `Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java`

Approach:

- Promote the delayed scan-stop callback to a field.
- Remove pending stop callbacks before posting a new timeout.
- Remove pending stop callbacks whenever scanning stops.
- Route device-selection scan cleanup through `scanLeDevice(false)`.

### U2: Baseline Contracts And Docs

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `CHANGES.md`

Approach:

- Require the cancellable scan-stop callback.
- Require callback removal when scanning stops.
- Document the scan lifecycle baseline.

## Verification

- `scripts/check-baseline.sh`
- `git diff --check`
