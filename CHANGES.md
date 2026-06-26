# Changes

## 2026-06-26T12:22:11Z — P2 correctness — cycle: complete Heart Rate Service parser

### Summary

Replaced Android-dependent BPM extraction with complete, dependency-free,
deterministic Heart Rate Service packet validation while preserving the
sample's BPM-only UI.

### Work completed

- Added Java 7 parsing for UINT8/UINT16 BPM, contact, energy-expended, and RR
  fields in Bluetooth SIG little-endian order.
- Rejected reserved, inconsistent, truncated, missing-RR, odd-RR, and trailing
  packet data before any measurement publication.
- Added 32 parser assertions, eight parser-specific hostile mutations, static
  contracts, exact-head runner integration, and updated public/device guidance.

### Threads

- None; work was completed directly after confirming no open PR, issue, or
  unpublished local branch owned the parser roadmap item.

### Files changed

- `HeartRateMeasurement*.java` — immutable parsed data and complete packet parser.
- `BluetoothLeService.java` — parser delegation and compatible BPM publication.
- `scripts/` — portable, hostile-mutation, and exact-head verification.
- `README.md`, `SECURITY.md`, `VISION.md`, `DEVICE_VERIFICATION.md`, and
  `docs/plans/` — behavior, privacy, design, evidence, and remaining hardware scope.

### Validation

- `./scripts/test-heart-rate-parser.sh` — 32 assertions passed after the
  intentional missing-class RED failure.
- `./scripts/test-ble-mutations.sh` — all 19 hostile mutations rejected.
- Portable source, session, archive, publication, shell, and diff gates passed.

### Bugs / findings

- The old service validated only the BPM prefix and could accept malformed
  optional Heart Rate Service fields that were never inspected.

### Blockers

- No local Android SDK, emulator, phone, BLE sensor, or live GATT flow was used;
  authenticated hosted Android verification and the explicit device matrix
  remain the authority for those scopes.

### Next action

- Execute the exact-head hosted Android and CodeQL gates, then merge only that
  reviewed SHA.

## 2026-06-26T01:10:00Z — P2 privacy — cycle: BLE data-event logging

- Threads: selected the next explicitly licensed stale repository, confirmed
  no open work, and reviewed BLE callbacks, logs, lifecycle ownership, portable
  contracts, and authenticated Android publication boundaries.
- Bug fixed: every `ACTION_DATA_AVAILABLE` broadcast wrote a verbose log entry;
  timestamps could reveal BLE measurement activity and the log added no useful
  diagnostic context.
- Fix: removed the routine data-event log while preserving in-process broadcast
  handling and UI display of available measurements.
- Contracts: portable verification now rejects the original log and a hostile
  mutation that restores it; privacy guidance covers event timing as well as
  identifiers and values.
- Validation: the pre-fix contract failed on the log. Source contracts, Java
  session guards, eleven hostile BLE mutations, the archive baseline,
  publication-gate mutation suite, and `git diff --check` passed after removal.
- Blockers: local Make is intentionally unsupported and no Android SDK, device,
  sensor, or live BLE flow is claimed; hosted authenticated verification is
  authoritative for the Android build.
- Hosted: implementation head `c6c4be5` passed the authenticated Java 8/API 22
  Android check and CodeQL for Actions, Java/Kotlin, and Python. Exact-head
  Codex review reported no actionable findings.
- Next: revalidate this documentation-only head, merge PR #21, and synchronize
  `master`.

## 2026-06-25T20:50:56Z — P1 privacy — cycle: GATT UUID logging

- Threads: inspected BLE scan, service, callback, characteristic discovery,
  logging, portable contracts, hostile mutations, and authenticated Android
  verification boundaries; no open pull requests or issues were present.
- Bug fixed: removed routine verbose logging of the discovered heart-rate GATT
  UUID while preserving standard-UUID matching and notification registration.
- Files: `DeviceControlActivity.java`, `scripts/test-ble-source-contracts.py`,
  `scripts/test-ble-mutations.sh`, and
  `docs/plans/2026-06-25-hrm-gatt-uuid-log-removal.md`.
- Validation: passed source contracts, Java session guards, hostile mutations,
  the portable baseline, and publication-gate integrity tests.
- Blockers: no Android SDK build, emulator, device, BLE sensor, or live GATT
  flow ran locally; authenticated hosted Android verification is required.
- Next: keep BLE names, addresses, UUIDs, advertising data, and measurements
  out of routine logs and committed evidence.

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
