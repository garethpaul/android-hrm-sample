# Explicit Heart Rate Parser Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

Status: Completed

**Goal:** Replace Android-dependent BPM extraction with a complete, deterministic Heart Rate Service packet parser while preserving the existing BPM-only UI.

**Architecture:** Add package-private Java 7 parser and immutable measurement classes with no Android imports. `BluetoothLeService` passes the characteristic bytes to the parser, rejects malformed packets, and publishes only the parsed BPM as before.

**Tech Stack:** Java 7, Android Bluetooth GATT, POSIX shell, Python source contracts, legacy Gradle verification

---

### Task 1: Establish parser behavior

**Files:**
- Create: `scripts/tests/HeartRateMeasurementParserTest.java`
- Create: `scripts/test-heart-rate-parser.sh`

**Step 1: Write the failing test**

Add executable cases for valid UINT8/UINT16 BPM, contact state, energy, multiple
RR intervals, and combined packets. Add rejection cases for null, short,
reserved, inconsistent contact, truncated, missing/odd RR, and trailing bytes.

**Step 2: Run test to verify it fails**

Run: `./scripts/test-heart-rate-parser.sh`

Expected: FAIL because `HeartRateMeasurement.java` and
`HeartRateMeasurementParser.java` do not exist.

### Task 2: Implement the pure parser

**Files:**
- Create: `Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurement.java`
- Create: `Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java`

**Step 1: Write minimal implementation**

Decode all UINT16 values little-endian, validate flags and packet boundaries,
clone RR arrays at the value-object boundary, and return `null` for malformed
packets.

**Step 2: Run test to verify it passes**

Run: `./scripts/test-heart-rate-parser.sh`

Expected: PASS with all parser cases executed on Java 7 source compatibility.

### Task 3: Integrate the service

**Files:**
- Modify: `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

**Step 1: Replace Android-dependent parsing**

Read the characteristic byte array once, parse it through
`HeartRateMeasurementParser`, emit the existing generic warning on failure, and
publish only `beatsPerMinute()` through `EXTRA_DATA`.

**Step 2: Run focused tests**

Run: `./scripts/test-heart-rate-parser.sh`

Expected: PASS.

### Task 4: Bind repository contracts

**Files:**
- Modify: `scripts/check-baseline.sh`
- Modify: `scripts/run-android-verification.sh`
- Modify: `scripts/test-ble-mutations.sh`
- Modify: `VISION.md`
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `DEVICE_VERIFICATION.md`
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-explicit-heart-rate-parser.md`

**Step 1: Add fail-closed contracts**

Require the parser files, service delegation, test runner, full-field parsing,
generic logs, completed roadmap/plan state, and unexecuted hardware evidence.

**Step 2: Run portable verification**

Run the parser harness, source contracts, hostile mutations, session tests,
shell syntax checks, and `git diff --check`.

Expected: all portable checks pass; Android SDK and device-only work remains
truthfully separated.

### Task 5: Publish exact-head evidence

**Files:**
- Modify: `docs/plans/2026-06-26-explicit-heart-rate-parser.md`

**Step 1: Record completed evidence**

Document RED/GREEN commands, mutation count, local Android/toolchain boundary,
and exact-head hosted results.

**Step 2: Commit**

Run: `git commit -m "fix: parse complete heart rate measurements"`

Expected: one focused commit ready for PR review.

## Work Completed

- Added immutable `HeartRateMeasurement` and dependency-free
  `HeartRateMeasurementParser` Java 7 classes.
- Parsed UINT8/UINT16 BPM, sensor contact, energy expended, and one or more RR
  intervals in Bluetooth SIG little-endian order.
- Rejected reserved flags, unsupported contact status, incomplete mandatory or
  optional fields, missing or odd RR data, and unexplained trailing bytes.
- Kept `BluetoothLeService` presentation compatibility by broadcasting only
  the parsed BPM string and retaining generic failure diagnostics.
- Added 32 focused assertions, source authority contracts, eight parser-specific
  hostile mutations, exact-head runner integration, and updated public/device
  guidance.

## Verification Completed

- RED: `./scripts/test-heart-rate-parser.sh` failed because the parser classes
  did not exist.
- GREEN: the Java 7 parser harness passed all 32 assertions.
- Nineteen total BLE hostile mutations passed, including parser delegation,
  RFU flags, little-endian order, contact support, energy offsets, empty RR,
  trailing bytes, and RR array ownership.
- Source contracts, BLE session tests, shell syntax checks, archive baseline,
  publication-gate tests, and `git diff --check` passed locally.
- No Android emulator, phone, BLE sensor, or live GATT notification was used;
  every applicable row in `DEVICE_VERIFICATION.md` remains `not run`.
- Exact-head Android SDK/Gradle and CodeQL results are recorded in the pull
  request before merge.
