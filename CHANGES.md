# Changes

## 2026-06-09

- Guarded GATT characteristic read, notification, and data-broadcast paths when
  callers or callbacks provide missing characteristics.
- Guarded GATT data-field updates when stale control layouts omit the data
  value view.
- Added SDK-free baseline coverage for GATT data-field null guards.
- Guarded BLE scan lifecycle paths against missing Bluetooth adapters, handlers,
  stopped list adapters, and null scan callback devices.
- Scoped GATT update broadcasts to the app package and stopped logging exact
  heart-rate measurement values in debug output.
- Guarded BLE scan startup when the device lacks BLE support or Android cannot
  provide a `BluetoothManager` service.
- Guarded the heart-rate client-config descriptor before notification writes
  and made disable requests write the BLE disable descriptor value.
- Guarded nullable ActionBar access in the scan and GATT control activities so
  theme changes do not crash startup.

## 2026-06-08

- Added `make check` as the root wrapper for HRM source, lint, Gradle check,
  and debug build verification.
- Added a BLE address validation contract so connection attempts reject invalid
  device addresses before calling Android's `getRemoteDevice` API.
- Made the BLE scan timeout callback cancellable so pause and navigation stop
  paths do not leave stale scan-stop work queued.
- Added a repository changelog and expanded the documented Android verification
  gate to include lint, Gradle check, and debug assembly.
- Cleaned Android lint findings by making backup behavior explicit, fixing
  device-row inflation, moving visible UI text into string resources, and using
  `sp` for text sizes.
- Removed unused template strings and dimensions, moved the single 9-patch tile
  asset to `drawable-nodpi`, and documented the narrow legacy lint baseline.
- Matched the heart-rate measurement characteristic by standard UUID instead
  of Java string identity on the display label.
