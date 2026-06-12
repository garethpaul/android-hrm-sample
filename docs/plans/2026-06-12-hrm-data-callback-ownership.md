# HRM Data Callback Ownership

Status: Completed

## Context

The connection-state callback rejects events from stale `BluetoothGatt`
instances, but service discovery, characteristic reads, and characteristic
notifications do not. After a connection is closed or replaced, those stale
callbacks can still broadcast services or heart-rate data into the current app
session.

## Changes

- Reject stale or missing GATT instances in service-discovery callbacks.
- Reject stale or missing GATT instances in characteristic-read callbacks.
- Reject stale or missing GATT instances in characteristic-change callbacks.
- Keep valid callback status and packet parsing behavior unchanged.
- Extend the SDK-free baseline and README with the complete callback ownership
  contract.

## Verification

- `make check`
- Static mutations that remove each callback-specific ownership guard
- `git diff --check`

The Android SDK and BLE hardware are unavailable on this host, so runtime GATT
callback ordering still requires verification on a compatible Android device.
