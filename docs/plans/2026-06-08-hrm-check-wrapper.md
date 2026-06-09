---
title: HRM Check Wrapper
type: chore
status: completed
date: 2026-06-08
---

# HRM Check Wrapper

## Summary

Expose the HRM sample's SDK-free source check and SDK-backed Gradle gates
through the shared root `make check` command.

## Requirements

- R1. Preserve `scripts/check-baseline.sh` as the first verification step.
- R2. Run Gradle lint, `check`, and debug assembly when `ANDROID_HOME` points
  to an installed Android SDK.
- R3. Export `ANDROID_SDK_ROOT` alongside `ANDROID_HOME` for the legacy Gradle
  toolchain.
- R4. Document the wrapper in README and CHANGES.

## Verification

- `make check`
- `git diff --check`
