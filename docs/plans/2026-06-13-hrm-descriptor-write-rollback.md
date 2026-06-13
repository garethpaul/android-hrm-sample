# HRM Descriptor Write Rollback

Status: Completed

## Context

The HRM service guards local notification registration, but the following
heart-rate descriptor phase ignores `BluetoothGattDescriptor.setValue()` and
`BluetoothGatt.writeDescriptor()` results. Missing or rejected descriptor work
can leave the local notification state changed while the peripheral state was
not updated.

## Requirements

- Roll back the local characteristic notification state when the heart-rate
  descriptor is missing.
- Check descriptor value assignment and roll back when it is rejected.
- Check descriptor write queueing and roll back when it is rejected.
- Restore the prior local state with `!enabled`, using a shared helper.
- Log generic failure categories without UUIDs, device addresses, descriptor
  values, platform codes, or exception details.
- Preserve successful enable/disable values, characteristic guards, UUID
  matching, active GATT ownership, and asynchronous descriptor callbacks.
- Add mutation-sensitive static coverage, documentation, and truthful
  verification evidence.

## Implementation Units

### U1: Roll Back Descriptor-Phase Failures

**File:** `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Add a local rollback helper and invoke it before returning from missing
descriptor, rejected value, and rejected write-queue branches.

### U2: Extend Portable Contracts

**File:** `scripts/check-baseline.sh`

Require both boolean results, all three failure branches, shared rollback use,
prior-state restoration, generic logs, ordering, and completed plan evidence.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document local/remote notification consistency. Run local and external
`make check`, hostile mutations, available Android verification, and final
diff, artifact, credential, and exact-head hosted checks.

## Scope Boundaries

- Do not add retries, descriptor callback state machines, connection teardown,
  or UI changes in this unit.
- Do not change BLE permissions, UUIDs, scan behavior, measurement parsing, or
  broadcast payloads.
- Do not claim emulator, physical BLE device, or forced descriptor failure
  behavior without those runtime facilities.

## Verification Plan

- Run `make check` locally and from an external working directory.
- Prove hostile mutations for missing result checks, inverted failures,
  missing rollback branches, wrong rollback state, late rollback, reflected
  diagnostics, documentation drift, and incomplete-plan status fail.
- Run Android lint, Gradle check, Java compilation, and debug assembly when the
  compatible SDK is available; otherwise record the local skip.
- Run `git diff --check`, generated-artifact inspection, and
  credential-shaped added-line scans.
- Record hosted evidence only after querying the exact pushed head.

## Sources

- Android `BluetoothGattDescriptor.setValue` API reference:
  https://developer.android.com/reference/android/bluetooth/BluetoothGattDescriptor#setValue(byte[])
- Android `BluetoothGatt.writeDescriptor` API reference:
  https://developer.android.com/reference/android/bluetooth/BluetoothGatt#writeDescriptor(android.bluetooth.BluetoothGattDescriptor)

## Verification

- Local and external-working-directory `make check` passed all SDK-free BLE
  result, rollback ordering, generic-log, documentation, and repository
  contracts.
- Nine focused hostile mutations were rejected across missing-descriptor
  rollback, ignored or inverted value/write results, wrong rollback state,
  unreachable rollback, reflected diagnostics, guidance, and completed-plan
  status.
- No Android SDK is configured locally, so Android lint, Gradle check, Java
  compilation, and debug assembly were truthfully skipped and remain required
  in hosted CI.
- Final diff, artifact, conflict-marker, credential-pattern, and whitespace
  inspection passed. Emulator, physical BLE device, and forced descriptor
  failure behavior were not exercised.
- Hosted exact-head evidence remains pending push.
