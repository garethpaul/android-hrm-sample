# Handle HRM Service Discovery Start Failure

Status: Completed

## Context

After a successful GATT connection, `BluetoothGatt.discoverServices()` can
return `false` without scheduling `onServicesDiscovered()`. The service
currently remains connected and publishes a connected event even though the
activity can never receive services or enable heart-rate notifications.

## Scope

- Treat a rejected service-discovery start as a terminal connection failure.
- Clear pending descriptor state, publish the existing disconnected event,
  close the currently owned GATT, and release its field reference.
- Preserve successful connection, discovery callback ownership, local
  broadcasts, and replacement-GATT cleanup behavior.
- Add mutation-sensitive portable contracts and maintenance documentation.

## Verification

- Run SDK-backed repository `make check` and the external-directory portable
  gate with SDK variables unset.
- Reject mutations that ignore the boolean discovery result, omit state or
  descriptor cleanup, omit disconnection delivery, omit close/release, change
  successful discovery ordering, remove documentation, or reopen this plan.
- Audit the exact diff, generated artifacts, changed-line secret patterns, and
  whitespace before commit.

## Risks

- No physical BLE peripheral or forced Android discovery-queue failure is
  exercised; the checked-in device matrix remains the runtime boundary.
- Existing stacked pull requests remain open and require explicit owner
  authorization before merge or closure.

## Verification Results

Completed on 2026-06-15:

- Direct SDK-backed Gradle lint, check, and debug assembly passed under Amazon
  Corretto 8 and Android API 22, with zero lint issues.
- SDK-backed repository `make check` passed the portable contracts, debug and
  release Java compilation, Android lint with zero issues, Gradle check, and
  debug APK assembly.
- External-working-directory `make check` passed with Android SDK variables
  intentionally unset and SDK-dependent tasks truthfully skipped.
- Ten hostile mutations covering the discovery result, failure guard, state and
  descriptor cleanup, disconnection delivery, close/release ordering,
  successful ordering, documentation, and completed-plan status were rejected.
- Exact diff, generated-artifact, changed-line secret-pattern, and whitespace
  audits passed before commit.
- No physical BLE peripheral or forced Android discovery-queue failure was
  exercised.
