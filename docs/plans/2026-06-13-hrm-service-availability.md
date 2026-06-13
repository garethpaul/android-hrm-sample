# Guard HRM Service Availability

Status: Completed

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

## Work Completed

- Recorded successful `bindService()` ownership separately from the nullable
  service reference.
- Finished with a generic diagnostic when Android rejects the bind request.
- Guarded destruction so only an owned binding is unbound and ownership is
  cleared before superclass teardown.
- Guarded discovered-services and connect/disconnect menu paths before service
  dereferences.
- Added method-bounded contracts and updated user, security, vision, and change
  guidance.

## Verification Completed

- `sh -n scripts/check-baseline.sh` passed.
- Local `make check` and external-working-directory `make -C` execution passed
  all SDK-free contracts. Android lint, Gradle check, and build truthfully
  skipped because no Android SDK is configured locally.
- Eleven focused hostile mutations were rejected: ignored and inverted bind
  results, missing bind-failure finish, unguarded unbind, missing ownership
  reset, unguarded discovery/connect/disconnect, reflected diagnostics, README
  guidance, and plan-status rollback.
