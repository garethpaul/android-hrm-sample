# HRM Replacement GATT Cleanup

Status: Completed

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

- The portable checker and bounded Java 8/API 18 Android `make check` passed,
  including zero-issue lint, debug/release compilation and checks, and debug
  APK assembly.
- Six hostile mutations were rejected: missing prior capture, close before
  replacement creation, missing pending clear, missing close, publication
  before close, and stale plan evidence.
- Exact-diff, generated-artifact, whitespace, conflict-marker, and added-line
  credential audits complete the final gate.
- Physical BLE replacement behavior was not exercised.

## Scope Boundaries

- Do not add retries, connection queues, timeouts, or UI state.
- Do not claim physical BLE replacement behavior without compatible hardware.
- Do not merge or close any pull request without explicit authorization.
