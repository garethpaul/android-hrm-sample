# Handle HRM Scan Start Failure

Status: Planned

## Context

`DeviceScanActivity` marks the UI as scanning and schedules its ten-second stop
callback before calling `BluetoothAdapter.startLeScan(...)`. Android documents
that this legacy API returns `true` only when the scan starts successfully:
<https://developer.android.com/reference/android/bluetooth/BluetoothAdapter#startLeScan(android.bluetooth.BluetoothAdapter.LeScanCallback)>.
When it returns `false`, the current activity still shows the stop action and
waits on a timeout for a scan that never began.

## Priorities

1. Keep scan state and timeout ownership aligned with Android's start result.
2. Preserve successful scan startup, timeout cleanup, explicit stop behavior,
   device-list updates, and existing adapter/handler guards.
3. Keep migration to `BluetoothLeScanner`, modern runtime permissions, and
   physical-device behavior outside this legacy API 22 change.

## Requirements

1. Capture the boolean returned by `startLeScan` before marking the activity as
   scanning or scheduling the stop callback.
2. On success, retain the existing scanning state and ten-second timeout.
3. On failure, keep the activity idle, remove any stale stop callback, expose
   the scan action rather than the stop action, and show a stable local error.
4. Add mutation-sensitive source ordering, resource, guidance, and completed
   plan contracts.

## Implementation Units

### U1: Reconcile scan state with startup

**File:** `Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java`

Call `startLeScan` first, branch on its result, and schedule the timeout only
for a successfully started scan.

### U2: Add the user-visible failure contract

**File:** `Application/src/main/res/values/strings.xml`

Add a concise scan-start failure message used only by the false-return path.

### U3: Protect the boundary and guidance

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
`CHANGES.md`, and this plan.

Require result capture, success/failure branching, timeout ordering, stable
resource use, maintained guidance, and completed verification evidence.

## Verification

- Run POSIX shell syntax and the focused portable baseline before and after the
  implementation.
- Run repository and external-directory `make check`, using the configured
  Java 8 and Android API 22 SDK when available.
- Reject isolated return-value, state, timeout, failure-message, documentation,
  and plan-completion mutations.
- Audit exact intended paths, generated Gradle artifacts, conflict markers,
  dependency/workflow drift, whitespace, and credential-shaped additions.

## Risks

- No physical BLE peripheral or forced platform scan-start failure is exercised;
  `DEVICE_VERIFICATION.md` remains the runtime authority.
- The branch remains stacked on PR #15 and must retain base-first ordering.
