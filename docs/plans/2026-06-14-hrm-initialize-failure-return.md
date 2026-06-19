# Stop HRM Connection After Initialization Failure

Status: Completed

## Context

`DeviceControlActivity.onServiceConnected()` finishes the activity when
Bluetooth service initialization fails, but then falls through and still calls
`connect()`. Failed initialization must terminate the binding callback before
any GATT connection attempt.

## Scope

- Return immediately after the initialization failure and `finish()` call.
- Preserve successful initialization, automatic connection, binding cleanup,
  local broadcasts, and existing GATT callback ownership guards.
- Add mutation-sensitive portable contracts and maintenance documentation.

## Verification

- Run SDK-backed repository `make check` and the external-directory portable
  gate with SDK variables unset.
- Reject mutations that remove or move the early return, weaken success-path
  connection ordering, remove documentation, or reopen this plan.
- Audit the exact diff, generated artifacts, changed-line secret patterns, and
  whitespace before commit.

## Risks

- No physical BLE peripheral or disabled-adapter device flow is exercised.
- Existing stacked pull requests remain open and require explicit owner
  authorization before merge or closure.

## Verification Results

Completed on 2026-06-14:

- SDK-backed `make check` passed source contracts, debug and release Java
  compilation, Android lint with zero issues, Gradle check, and debug APK
  assembly under Amazon Corretto 8 and Android API 22.
- External-working-directory `make check` passed with Android SDK variables
  intentionally unset.
- Eight hostile mutations covering the missing or misplaced return,
  pre-return connection, maintained documentation, and completed-plan status
  were rejected.
- Exact diff, generated-artifact, changed-line secret-pattern, and whitespace
  audits passed before commit.
- No physical BLE peripheral or disabled-adapter runtime was exercised.
