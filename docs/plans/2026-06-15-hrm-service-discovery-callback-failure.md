# Handle HRM Service Discovery Callback Failure

Status: Completed

## Context

Android can accept `discoverServices()` and later report a non-success status to
`onServicesDiscovered()`. The service currently logs that callback and remains
connected even though the activity cannot receive a usable service list or
enable heart-rate notifications.

## Scope

- Treat a failed service-discovery callback from the currently owned GATT as a
  terminal connection failure.
- Clear pending descriptor state, publish the existing disconnected event,
  close the owned GATT, and release its field reference.
- Preserve stale-callback rejection and the successful services-discovered
  broadcast path.
- Add fail-closed ordering contracts and maintenance documentation.

## Verification

- Run SDK-backed repository `make check` and the external-directory portable
  gate with SDK variables unset.
- Reject hostile mutations that remove status branching, state cleanup,
  disconnection delivery, close/release, ownership guards, success delivery,
  documentation, or completed-plan evidence.
- Audit the exact diff, generated artifacts, changed-line credential patterns,
  and whitespace before commit.

## Risks

- No physical BLE peripheral or forced asynchronous discovery failure is
  exercised; the checked-in device matrix remains the runtime boundary.
- Existing stacked pull requests remain open and require explicit owner
  authorization before merge or closure.

## Verification Completed

- Direct SDK-backed Gradle lint, check, and debug assembly passed under Amazon
  Corretto 8 and Android API 22, with zero lint issues and debug/release Java
  compilation.
- Eleven hostile mutations were rejected for callback ownership, status
  branching, success delivery, failure cleanup, documentation, and completion
  evidence.
- Canonical repository and external-directory `make check` runs use the same
  pinned Java 8 and Android SDK boundary recorded above.
- No physical BLE peripheral or forced asynchronous discovery failure was
  exercised; runtime verification remains explicit in `DEVICE_VERIFICATION.md`.
