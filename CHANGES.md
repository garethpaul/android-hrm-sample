# Changes

## 2026-06-25T20:50:56Z — P2 correctness — cycle: GATT row metadata

- Threads: inspected the default branch, open work, Android verification
  boundary, BLE scan/session ownership, service binding, GATT callbacks,
  characteristic rendering, source contracts, and hostile mutation suite; no
  open pull requests or issues were present.
- Bug fixed: every discovered GATT characteristic now receives its resolved
  display name and UUID before heart-rate-specific notification handling, so
  non-heart-rate characteristics no longer appear as empty selectable rows.
- Files: `DeviceControlActivity.java`, `scripts/test-ble-source-contracts.py`,
  `scripts/test-ble-mutations.sh`, and
  `docs/plans/2026-06-25-hrm-characteristic-row-metadata.md`.
- Validation: reproduced the ordering-contract failure, passed the focused
  source contracts, session guards, hostile mutations, portable baseline, and
  publication-gate integrity tests.
- Blockers: no Android SDK build, emulator, physical device, BLE sensor, or
  live GATT flow was executed locally; the authenticated hosted Android gate
  remains required before merge.
- Next: add device evidence that mixed-service peripherals render named rows
  while automatic notification registration remains HRM-only.

## 2026-06-21

- Made the authenticated archive verifier compatible with the runner's
  `/usr/bin/python3` 3.8 boundary and removed generated Python bytecode from
  the reviewed source tree.

## 2026-06-19

- Added scan-session generations so callbacks queued by stopped or replaced
  scans cannot populate the current device list.
- Bound scan-row selection to the address rendered in the clicked row and
  rejected unavailable Bluetooth permissions without crashing scan lifecycle
  paths.
- Added Android 6-compatible coarse-location declaration for legacy BLE scans.
- Made GATT ownership atomic across replacement, callback failure, disconnect,
  descriptor rollback, and repeated close paths so stale callbacks cannot
  release or mutate a replacement connection.
- Added focused Java state-machine tests, source contracts, and nine hostile
  mutations without executing an unverified wrapper.

## 2026-06-17

- BLE scan-list selections reject unavailable adapters and out-of-range positions before device lookup.
- Added ordered source contracts for adapter availability, lower and upper
  position bounds, null-device handling, and valid selection compatibility.

## 2026-06-15

- BLE scanning must wait until the enable-Bluetooth system flow returns with an enabled adapter.
- BLE scans must enter the scanning state and schedule timeout cleanup only after Android reports that scan startup succeeded.
- Closed and released the current connection when Android rejects a GATT
  service discovery start instead of waiting for a callback that cannot arrive.
- Closed and released the current connection after a failed GATT service
  discovery callback instead of leaving an unusable connected state.

## 2026-06-14

- Stopped failed Bluetooth initialization before attempting a GATT connection.
- Moved GATT state and heart-rate events to an in-process local broadcast
  channel so external applications cannot spoof or observe those updates.
- Replacement GATT connections close the previously owned GATT exactly once
  after atomically replacing current ownership.
- Added an exact-commit HRM device verification matrix for scan, GATT ownership,
  notifications, descriptor rollback, measurements, lifecycle races, and
  privacy-safe evidence, with every runtime row explicitly unexecuted.

## 2026-06-14

- Tracked queued heart-rate descriptor writes and ignored stale or unrelated
  completion callbacks.
- Made asynchronous descriptor write failures roll back local notification
  state after clearing the completed pending operation.

## 2026-06-13

- Recorded Bluetooth service binding ownership, handled rejected binds, and
  guarded destruction against unowned unbinds.
- Guarded service discovery and connect/disconnect menu actions while the bound
  Bluetooth service is unavailable.
- Gated heart-rate client configuration descriptor writes on successful local
  notification registration.
- Made descriptor-phase failures roll back local notification state when the
  descriptor, value assignment, or write queue is unavailable.
- Guarded stale GATT selection callbacks against unavailable services, missing
  entries, and out-of-range group or child positions.
- Added an explicit HRM component export boundary: the launcher remains
  exported while the device-control activity and BLE service are app-internal.

## 2026-06-12

- Regenerated the Gradle wrapper bootstrap with official Gradle 8.14.5 tooling
  while retaining the Gradle 2.2.1 Android runtime.
- Pinned Gradle's official distribution checksum and added exact SDK-free
  contracts for the generated wrapper artifacts and documentation boundary.

## 2026-06-10

- Guarded GATT connection callbacks against stale instances and failed status
  transitions, and rejected null connection objects.
- Corrected heart-rate format selection to read the measurement flag byte and
  guarded truncated flag/value fields before broadcasting data.
- Made root checks location-independent, accepted `ANDROID_SDK_ROOT`, and
  pinned CI to Ubuntu 24.04 with superseded-run cancellation.
- Added pinned, read-only GitHub Actions CI that runs the root `make check`
  baseline with a bounded timeout and explicit SDK-free execution.
- Removed the maintainer-specific Android SDK path from the Makefile.
- Disabled persisted checkout credentials, added self-protecting CODEOWNERS,
  and replaced partial workflow checks with one canonical workflow contract.

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
