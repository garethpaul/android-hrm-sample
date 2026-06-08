---
title: HRM BLE Address Validation
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# HRM BLE Address Validation

## Goal

Reject malformed BLE device addresses before the service calls Android's
`BluetoothAdapter.getRemoteDevice` API.

## Red

- Extended `scripts/check-baseline.sh` to require a
  `BluetoothAdapter.checkBluetoothAddress(address)` guard in
  `BluetoothLeService.connect`.
- Confirmed the baseline failed with
  `BLE connection must validate device addresses before getRemoteDevice.`

## Green

- Updated `BluetoothLeService.connect` to validate the address before reusing an
  existing connection or asking the adapter for a remote device.
- Restored generated README verification details required by the existing
  baseline.

## Verification

- `scripts/check-baseline.sh`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew lint --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew check --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`
