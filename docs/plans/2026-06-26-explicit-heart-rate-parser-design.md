# Explicit Heart Rate Parser Design

## Evidence

- `BluetoothLeService` currently reads only the flags byte and BPM through
  Android's nullable `BluetoothGattCharacteristic.getIntValue` API.
- The adopted [Bluetooth SIG Heart Rate Service 1.0 specification](https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/HRS_v1.0/out/en/index-en.html)
  is little-endian and defines UINT8/UINT16 BPM, sensor-contact flags, optional
  UINT16 energy expended, one or more UINT16 RR intervals when flagged, and RFU
  bits that must be zero.
- The repository already executes dependency-free Java 7 tests for BLE session
  ownership, while the Android build remains pinned to a legacy toolchain.

## Considered Approaches

### Android characteristic tests

Keep parsing in `BluetoothLeService` and add instrumentation tests around
`BluetoothGattCharacteristic`. This tests the current call site but requires
the obsolete Android runtime and cannot run in the portable gate.

### BPM-only Java helper

Extract only flags and BPM into a pure Java helper. This is small, but it still
accepts malformed optional fields and does not complete the roadmap's explicit
Heart Rate Service parsing goal.

### Full pure Java packet parser

Parse the complete characteristic payload into an immutable value object, then
let `BluetoothLeService` continue publishing only the BPM string. This provides
deterministic Java 7 coverage, validates the whole provider packet before UI
publication, and avoids changing the sample's user-visible behavior.

## Decision

Use the full pure Java parser. Reject null, undersized, RFU-bearing,
inconsistent sensor-contact, truncated optional, odd RR, missing RR, and
unexpected trailing bytes. Keep optional energy, contact, and RR values in the
short-lived parsed object without logging or broadcasting them.

## Validation

- Run a standalone Java 7 parser harness before implementation and observe the
  missing-class compile failure.
- Cover valid UINT8, UINT16, contact, energy, RR, and combined packets.
- Cover every malformed boundary without Android SDK dependencies.
- Bind the harness and mutation-sensitive source contracts into the canonical
  hosted verification path.
- Preserve the physical-device matrix as unexecuted unless authorized BLE
  hardware testing is performed.
