# HRM Local Broadcast Boundary

Status: Planned

## Problem

`BluetoothLeService` publishes connection state and heart-rate values through
framework broadcasts, and `DeviceControlActivity` registers a framework
receiver for predictable action strings. Setting the outbound intent package
limits recipients but does not authenticate inbound senders, so another app
can target this package and spoof connection or measurement events.

## Requirements

1. Deliver GATT connection, discovery, and data events only inside this app
   process using the already-pinned support-v4 dependency.
2. Use the same local broadcast manager instance for publication,
   registration, and unregistration.
3. Preserve action names, extras, heart-rate parsing, callback ownership,
   lifecycle timing, GATT behavior, dependencies, and UI behavior.
4. Prohibit framework `sendBroadcast`, `registerReceiver`, and
   `unregisterReceiver` for the GATT event channel.
5. Add mutation-sensitive portable contracts, maintenance guidance, and
   truthful verification evidence.

## Implementation Units

### 1. Localize event publication

Files:

- `Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java`

Create a small local publication helper backed by `LocalBroadcastManager` and
route every existing GATT event through it.

### 2. Localize activity subscription

Files:

- `Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java`

Register and unregister the existing receiver through `LocalBroadcastManager`
at the same resume/pause lifecycle boundaries.

### 3. Protect the boundary

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-14-hrm-local-broadcast-boundary.md`

Require local publication and subscription, reject framework broadcast APIs
for GATT events, and document the process-local trust boundary.

## Verification

To be recorded after implementation:

- POSIX shell syntax and portable source contracts.
- Java 8 / Android API 22 lint, checks, and debug assembly.
- Repository-root and external-directory `make check`.
- Isolated publication, registration, unregistration, framework-API,
  documentation, and completed-plan mutations.

## Scope Boundaries

- Do not change BLE permissions, service exports, action names, event payloads,
  GATT sequencing, or measurement rendering.
- Do not add a new dependency or claim physical BLE execution.
- Do not merge or close any pull request without explicit authorization.
