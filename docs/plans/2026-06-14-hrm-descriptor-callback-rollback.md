# HRM Descriptor Callback Rollback

Status: Completed

## Problem

Heart-rate notification setup now rolls back local registration when descriptor
lookup, value assignment, or write queueing fails synchronously. A descriptor
write can still queue successfully and later complete with a non-success GATT
status. The service has no `onDescriptorWrite` handling, so that asynchronous
failure leaves local notifications enabled even though the peripheral did not
accept the subscription.

## Requirements

1. Track the active heart-rate descriptor write, its characteristic, and the
   requested notification state before queueing the asynchronous operation.
2. Accept descriptor callbacks only from the current GATT and the exact
   pending descriptor; ignore stale or unrelated callbacks without mutating
   current state.
3. Clear pending state on both successful and failed completion.
4. Roll local notification state back to its prior value when the exact
   pending descriptor completes with a non-success status.
5. Clear pending descriptor state when the current GATT is closed or fails.
6. Preserve UUIDs, descriptor values, synchronous rollback behavior,
   connection ownership, broadcasts, permissions, dependencies, and UI.
7. Add dependency-free, mutation-sensitive contracts and truthful completed
   verification evidence.

## Implementation Units

### U1: Track And Complete Descriptor Writes

**File:** `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Retain the descriptor, characteristic, and requested state around a successfully
queued heart-rate write. Add an identity-checked descriptor callback that clears
the retained operation before rolling back a failed completion.

### U2: Clear Pending State With GATT Ownership

**File:** `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Centralize pending-write clearing and invoke it when the current GATT fails or
closes so callbacks from released connections cannot affect later work.

### U3: Protect The Contract

**File:** `scripts/check-baseline.sh`

Require exact callback ownership, clear-before-rollback ordering, success
clearing, queue bookkeeping, GATT cleanup, generic diagnostics, and completed
plan evidence.

### U4: Document The Boundary

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Record asynchronous descriptor failure consistency without claiming hardware
execution.

## Verification

- Run shell syntax and the dependency-free baseline checker.
- Run bounded local and external-working-directory `make check` using the
  compatible Android SDK when available.
- Reject focused mutations for missing ownership checks, wrong descriptor
  identity, missing success/failure clearing, rollback-before-clear, missing
  queue bookkeeping, lost GATT cleanup, reflected diagnostics, and stale plan
  status.
- Inspect the exact diff, ignored artifacts, conflict markers, whitespace, and
  credential-shaped added lines before committing.

## Scope Boundaries

- Do not add retries, timeouts, parallel descriptor queues, or UI state.
- Do not change characteristic discovery, packet parsing, broadcasts, scan
  behavior, permissions, dependencies, SDK, Gradle, or workflows.
- Do not claim emulator, physical BLE device, or forced asynchronous callback
  behavior without those runtime facilities.
- Do not merge or close stacked pull requests without explicit authorization.

## Sources

- Android `BluetoothGattCallback.onDescriptorWrite` API reference:
  https://developer.android.com/reference/android/bluetooth/BluetoothGattCallback#onDescriptorWrite(android.bluetooth.BluetoothGatt,android.bluetooth.BluetoothGattDescriptor,int)
- Android `BluetoothGatt.writeDescriptor` API reference:
  https://developer.android.com/reference/android/bluetooth/BluetoothGatt#writeDescriptor(android.bluetooth.BluetoothGattDescriptor)

## Work Completed

- Retained one active descriptor, characteristic, and requested notification
  state before queueing a heart-rate descriptor write.
- Rejected overlapping descriptor work before local notification mutation and
  ignored callbacks from stale GATT instances or descriptors other than the
  exact pending operation.
- Cleared pending state before asynchronous failure rollback and on successful
  completion, synchronous queue failure, disconnect, connection failure, and
  close.
- Added method-scoped source contracts and generic documentation without
  changing BLE identifiers, descriptor values, broadcasts, or UI behavior.

## Verification Results

- Shell syntax and the dependency-free baseline checker passed.
- Ten focused mutations were rejected: wrong GATT identity, wrong descriptor
  identity, missing callback clear, rollback-before-clear ordering, missing
  pending characteristic assignment, missing queue-failure clear, missing
  disconnect clear, overlapping-write guard after local mutation, reflected
  callback status, and stale plan status.
- Bounded local and external-working-directory `make check`, exact diff,
  generated-artifact, conflict-marker, whitespace, and credential-shaped
  added-line results are recorded from the final implementation audit.
- Emulator, physical BLE device, and forced asynchronous descriptor failure
  behavior were not exercised and remain explicit runtime boundaries.
