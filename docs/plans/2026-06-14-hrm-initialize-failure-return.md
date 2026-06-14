# Stop HRM Connection After Initialization Failure

Status: Planned

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
