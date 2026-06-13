# HRM Component Export Boundary

Status: Completed

## Context

The HRM manifest relies on Android's implicit export rules. The launcher
activity must remain public, but the device-control activity and bound BLE
service are internal implementation details and should not depend on defaults.

## Requirements

- Keep the launcher activity exported for normal app launch.
- Explicitly keep the device-control activity and BLE service non-exported.
- Preserve component names, launcher intent filter, service enablement, BLE
  behavior, target SDK, and build compatibility.
- Add SDK-free contracts against missing, flipped, duplicate, or additive
  component export declarations.
- Update security guidance and completed verification evidence.

## Implementation

- Add explicit `android:exported` attributes to all three components.
- Require exact declaration counts, values, and component pairing in
  `scripts/check-baseline.sh`.
- Update README, SECURITY, CHANGES, and this plan.

## Verification

- `scripts/check-baseline.sh` passed with exact normalized component/value
  pairings and declaration counts.
- `ruby /tmp/engineering-bar/test-android-hrm-component-export-mutations.rb`
  rejected nine hostile mutations covering missing, flipped, swapped, and
  additive export declarations plus documentation and plan drift.
- `make check` passed with Java 8 and the configured Android SDK, including
  zero-finding lint, Gradle check, and debug assembly.
