# HRM Characteristic Null Guards

Date: 2026-06-09
Status: Completed

## Problem

`BluetoothLeService` already guarded adapters, GATT connections, and heart-rate
notification descriptors, but it still dereferenced selected or callback
`BluetoothGattCharacteristic` values directly. A stale UI selection or unusual
GATT callback could therefore crash before the service could safely ignore the
missing characteristic.

## Scope

- Preserve existing read, notify, and data broadcast behavior for valid
  characteristics.
- Avoid logging characteristic values or heart-rate data.
- Do not change scan, connection, descriptor, or BLE permission behavior.
- Keep verification available through the SDK-free baseline check.

## Work Completed

- Added a null-characteristic guard to GATT data broadcasts.
- Added null-characteristic guards to read and notification requests.
- Kept warnings generic so missing characteristic diagnostics do not include
  device or measurement values.
- Extended the SDK-free baseline and project documentation for the guard.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
