# Guard HRM Service Availability

Status: Planned

## Context

`DeviceControlActivity` ignores the result of `bindService()`, always calls
`unbindService()` during destruction, and dereferences the service from menu
and service-discovery paths before proving that binding completed. A failed or
delayed binding can therefore cause lifecycle or user-action crashes.

## Requirements

- Record whether the activity owns a successful service binding.
- Finish with a generic log when the initial bind request is rejected.
- Unbind only while the activity owns the binding, then clear ownership.
- Ignore connect, disconnect, and discovered-services actions while the service
  reference is unavailable.
- Preserve valid binding, initialization, reconnect, GATT, scan, notification,
  parsing, and broadcast behavior.
- Add mutation-sensitive static contracts, documentation, and truthful
  verification evidence.

## Scope Boundaries

- Do not change BLE permissions, UUIDs, scan timing, GATT state, descriptors,
  measurement parsing, or service implementation.
- Do not add retries, background work, new UI strings, or SDK modernization.
- Do not claim emulator, physical BLE device, or forced bind-failure behavior
  without those runtime facilities.

## Verification Plan

- `make check`
- External-working-directory `make check`
- Hostile mutations for ignored bind results, inverted failure handling,
  unconditional unbind, missing ownership reset, unguarded menu and discovery
  paths, reflected diagnostics, docs, and incomplete plan status.
- `git diff --check`, artifact, conflict-marker, and credential-shaped
  added-line inspection.
- Exact-head hosted Android validation after push.
