# HRM ActionBar Guard

## Status: Completed

## Context

`DeviceScanActivity` and `DeviceControlActivity` called `getActionBar().set...`
directly during startup. Theme changes or embedded launch contexts that return
a null ActionBar could therefore crash before BLE scanning or GATT connection
setup had a chance to run.

## Objectives

- Preserve the existing title-hiding and up-navigation behavior when an
  ActionBar exists.
- Avoid startup crashes when `getActionBar()` returns null.
- Keep the behavior covered by the SDK-free baseline checker.

## Work Completed

- Added `configureActionBar()` helpers to scan and control activities.
- Guarded nullable `getActionBar()` results before applying presentation
  settings.
- Extended `scripts/check-baseline.sh` to reject direct `getActionBar().set...`
  calls and require both guard helpers.
- Updated README, VISION, and CHANGES notes for the startup guard.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

Gradle lint, check, and debug assembly run when `ANDROID_HOME` points to a
compatible Android SDK.
