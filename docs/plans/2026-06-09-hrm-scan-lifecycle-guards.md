# HRM Scan Lifecycle Guards

## Status: Completed

## Context

`DeviceScanActivity` exits startup when BLE services are unavailable, but
Android lifecycle callbacks and delayed scan callbacks can still run around
finish, pause, or cleanup. Those paths previously assumed the Bluetooth
adapter, handler, list adapter, and callback device were always present.

## Objectives

- Preserve the existing scan menu and scan timeout behavior.
- Avoid stopping scans through a missing Bluetooth adapter.
- Avoid scanning when the adapter or handler is unavailable.
- Avoid clearing or updating a missing device list adapter.
- Ignore null BLE scan callback devices before adding them to the adapter.

## Work Completed

- Guarded the delayed stop runnable before calling `stopLeScan`.
- Added adapter and handler guards in `scanLeDevice`.
- Guarded menu and pause list-adapter cleanup.
- Guarded scan callback updates and adapter insertion for null devices.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add instrumentation coverage for startup failure, pause cleanup, and scan
  callback ordering when the Android stack is modernized.
- Replace the deprecated LE scan API in a dedicated Android version migration.
