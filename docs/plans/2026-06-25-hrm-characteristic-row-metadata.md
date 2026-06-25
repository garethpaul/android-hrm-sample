# GATT Characteristic Row Metadata

Status: Completed

## Problem

`DeviceControlActivity.displayGattServices()` resolved every characteristic name and UUID but populated the row map only for the heart-rate measurement UUID. Other discovered characteristics were therefore added to the expandable list as blank rows even though their metadata was available.

## Change

Populate `LIST_NAME` and `LIST_UUID` for every characteristic before the heart-rate-specific notification branch. Keep automatic notification registration restricted to the standard heart-rate measurement UUID.

## Verification Completed

- Added an ordered source contract requiring generic row metadata before HRM-specific behavior.
- Added a hostile mutation that removes characteristic row names and must be rejected.
- Passed `scripts/test-ble-source-contracts.py`, `scripts/test-ble-session-guards.sh`, `scripts/test-ble-mutations.sh`, `scripts/check-baseline.sh`, and `scripts/test-publication-gate.sh`.
- No Android SDK build, emulator, phone, BLE sensor, or live GATT scenario was executed locally; hosted Android verification remains required before merge.
