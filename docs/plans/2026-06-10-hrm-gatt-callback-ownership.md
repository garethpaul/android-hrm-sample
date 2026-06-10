# HRM GATT Callback Ownership

Status: Completed

## Context

`onConnectionStateChange` mutated shared connection state for every callback
and started service discovery through `mBluetoothGatt` instead of the callback's
`gatt` instance. A late callback from a superseded connection could therefore
disconnect or drive discovery on the current device. The connect path also
reported success when `connectGatt` returned `null`.

## Changes

- Ignore null and stale GATT connection callbacks.
- Treat non-success GATT status as a disconnected failure, then close and clear
  the active connection.
- Start service discovery through the callback instance after ownership and
  status validation.
- Return failure when Android cannot create a GATT connection object.
- Extend the SDK-free baseline with callback-ownership contracts.

## Verification

- `make check`
- Static mutations for removed stale-callback checks and global discovery use
- `git diff --check`

The Android SDK and BLE hardware are unavailable on this host, so device-level
connection race behavior still requires verification with a compatible Android
toolchain.
