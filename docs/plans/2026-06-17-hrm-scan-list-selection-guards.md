---
title: HRM Scan List Selection Guards
type: fix
date: 2026-06-17
status: completed
---

# HRM Scan List Selection Guards

## Summary

Make BLE device selection fail closed when the scan adapter is unavailable or
the callback position no longer identifies a current device. Preserve the
existing valid-selection intent and scan-stop behavior.

## Problem Frame

`DeviceScanActivity.onListItemClick` currently dereferences
`mLeDeviceListAdapter` and indexes its backing list before checking the returned
device. A stale or malformed callback can therefore raise a null-pointer or
index error before the existing null-device guard runs. The later GATT
characteristic selection path already rejects unavailable collections and
out-of-range positions, but the scan-list boundary has no equivalent guard.

## Requirements

**Selection safety**

- R1. A list-selection callback must return without side effects when the scan
  adapter is unavailable.
- R2. Device lookup must return no device for negative or out-of-range adapter
  positions instead of indexing the backing list.
- R3. A rejected callback must not stop scanning, create an intent, or start
  `DeviceControlActivity`.

**Compatibility**

- R4. A valid device selection must keep passing the same name and address
  extras, stop an active scan, and launch `DeviceControlActivity`.
- R5. BLE discovery, scan timeout, Bluetooth enablement, adapter population,
  and connection behavior must remain unchanged.

**Durable verification**

- R6. The baseline checker must require adapter availability, lower and upper
  position bounds, safe lookup ordering, and the existing null-device guard.
- R7. Maintained guidance and changelog text must describe the scan-list stale
  selection boundary.
- R8. Repository and external-directory Android gates must compile the guarded
  path under the maintained Java 8 and API 22 baseline.

## Key Technical Decisions

- KTD1. Guard adapter ownership in `onListItemClick`: the activity owns whether
  an adapter exists, so it must reject callbacks before any adapter method call.
- KTD2. Guard list bounds in `LeDeviceListAdapter.getDevice`: the adapter owns
  its backing collection, and a null-returning lookup keeps future callers from
  repeating unchecked indexing.
- KTD3. Reuse the existing null-device return: invalid positions converge on
  the same no-side-effect path as an unavailable device without adding UI
  errors for stale framework callbacks.
- KTD4. Use source contracts plus the complete Android build gate: this legacy
  sample has no activity-test seam for synthetic list callbacks, while the
  maintained checker and SDK-backed compile provide mutation-sensitive and
  type-correct coverage without introducing a new test framework.

## Implementation Units

### U1. Guard Scan List Device Lookup

- **Goal:** Prevent missing-adapter and invalid-position callbacks from
  reaching unchecked list access or launching the control activity.
- **Files:**
  - `Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java`
- **Changes:** Add the adapter guard before lookup and lower/upper bounds inside
  `LeDeviceListAdapter.getDevice`, retaining the existing null-device return.
- **Covered requirements:** R1, R2, R3, R4, R5.

### U2. Preserve Portable Contracts

- **Goal:** Make the boundary resistant to regression and visible to future
  maintainers.
- **Files:**
  - `scripts/check-baseline.sh`
  - `AGENTS.md`
  - `README.md`
  - `SECURITY.md`
  - `VISION.md`
  - `CHANGES.md`
- **Changes:** Require guard presence and ordering, reject direct unchecked
  indexing, document the stale scan-list selection contract, and require this
  plan artifact.
- **Covered requirements:** R6, R7.

### U3. Validate and Ship the Stack Tip

- **Goal:** Prove compatibility on the maintained legacy Android baseline and
  publish exact-head evidence.
- **Files:** No additional repository files expected.
- **Verification:** Run shell syntax, focused baseline checks, repository and
  external-directory `make check`, hostile guard mutations, exact diff and
  artifact/secret audits, then capture one bounded hosted snapshot.
- **Covered requirements:** R8.

## Acceptance Examples

- AE1. Given no scan adapter, when a list callback arrives, then the callback
  returns without lookup, scan mutation, or activity launch. Covers R1 and R3.
- AE2. Given a negative or stale upper-bound position, when device lookup runs,
  then it returns `null` and the callback follows the existing no-device return.
  Covers R2 and R3.
- AE3. Given a current device position, when the row is selected, then the same
  device extras are added, an active scan stops, and the control activity opens.
  Covers R4 and R5.
- AE4. Given either guard is removed or lookup is reordered ahead of validation,
  when the baseline checker runs, then it fails. Covers R6 and R8.

## Risks and Mitigations

- **Static contracts can overfit formatting:** anchor checks to the callback and
  adapter method blocks, and verify semantic ordering rather than whole-file
  line numbers.
- **A guard could suppress valid clicks:** retain the existing lookup and launch
  sequence after validation and compile the complete application.
- **Native timing remains unexercised:** keep emulator, physical-device, and
  live BLE selection in the existing device verification matrix rather than
  overstating local evidence.

## Scope Boundaries

- Do not change scan duration, callback registration, Bluetooth enablement,
  device deduplication, row rendering, intent extras, GATT connection logic,
  dependencies, manifests, or CI action pins.
- Do not add a new Android test framework or claim emulator, physical-device,
  or live BLE verification.

## Work Completed

- Guarded list callbacks before adapter access and guarded adapter lookup
  against negative and stale upper-bound positions.
- Preserved valid device extras, active-scan shutdown, and control-activity
  launch behavior after validation succeeds.
- Added portable source-ordering, guidance, and plan contracts for the
  scan-list selection boundary.

## Completed Verification

- Repository and external-directory `make check` passed under Corretto Java 8
  with Android API 22 and build-tools 24.0.3, covering source contracts,
  zero-issue debug/release lint, Gradle checks, Java compilation, and debug APK
  assembly.
- Focused hostile mutations rejected missing adapter and position guards,
  unsafe lookup ordering, direct unchecked indexing, guidance drift, and plan
  contract removal.
- Exact-path diff, whitespace, generated-artifact, ignored-output, and
  credential-shaped-addition audits passed without changing runtime,
  dependency, manifest, or workflow files.
- PR #18 was open, clean, mergeable, and terminal-green at implementation head
  `ea86bcbf2a55848b6e8f9f984a4a22a37089624d`; its canonical `check` job
  succeeded in run `27693203941`.
- Emulator, physical-device, and live BLE behavior were not exercised and
  remain governed by `DEVICE_VERIFICATION.md`.
