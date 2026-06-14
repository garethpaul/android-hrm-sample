# HRM Replacement GATT Cleanup

Status: Planned

## Problem

`connect()` reuses the current GATT for the same device, but a request for a
different address creates a replacement and overwrites `mBluetoothGatt`
without closing the previous platform object. Ownership guards ignore its
later callbacks, yet the old connection resource remains open.

## Requirements

1. Preserve same-address reconnect behavior and all address/adapter/device
   validation.
2. Keep the current GATT when replacement creation fails.
3. After a replacement GATT is created, clear pending descriptor state and
   close the prior GATT before publishing the replacement as current.
4. Preserve callback ownership, connection state, broadcasts, identifiers,
   permissions, dependencies, and UI behavior.
5. Add mutation-sensitive portable contracts and truthful verification.

## Verification

- Run the portable checker and bounded Java 8/API 18 Android `make check`.
- Reject mutations for missing prior capture, early close, missing pending
  clear, missing close, assignment-before-close, and stale plan evidence.
- Audit the exact diff, generated artifacts, whitespace, and added credentials.

## Scope Boundaries

- Do not add retries, connection queues, timeouts, or UI state.
- Do not claim physical BLE replacement behavior without compatible hardware.
- Do not merge or close any pull request without explicit authorization.
