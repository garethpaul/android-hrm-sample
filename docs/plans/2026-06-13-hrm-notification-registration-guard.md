# Gate Heart-Rate Descriptor Writes On Local Registration

Status: Planned

## Context

`BluetoothGatt.setCharacteristicNotification` reports whether the local
notification status was set successfully. The service currently ignores that
result and still mutates and writes the heart-rate client configuration
descriptor after a failed local registration request.

## Requirements

- R1. Capture the local notification registration result.
- R2. Log a generic warning and return when registration fails.
- R3. Descriptor lookup, null handling, enable/disable value selection, value
  assignment, and write initiation must occur only after local registration
  succeeds.
- R4. Characteristic null guards, GATT ownership, heart-rate UUID matching,
  privacy behavior, dependencies, permissions, and workflows must remain
  unchanged.
- R5. SDK-free contracts must isolate the notification method and reject a
  missing result guard, inverted condition, late guard, or removed return.

## Verification

- `make check`
- External-working-directory baseline execution.
- `sh -n scripts/check-baseline.sh` and `git diff --check`.
- Focused hostile mutations for result removal, inversion, late guarding,
  missing return, stale plan status, and missing verification evidence.
- Exact-base artifact and credential-shaped added-line inspection.
- Exact-head hosted Android validation after push.

## Source

- Android `BluetoothGatt.setCharacteristicNotification` API reference: the
  boolean result is true only when the requested notification status was set
  successfully.
