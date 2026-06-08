---
title: HRM Lint Resource Baseline
type: chore
status: completed
date: 2026-06-08
---

# HRM Lint Resource Baseline

## Summary

Clean the remaining Android lint findings in the legacy Bluetooth LE heart-rate
sample while preserving the existing SDK and support library baseline.

## Requirements

- R1. Preserve the Gradle 2.2.1, Android Gradle Plugin 1.0.0, compile/target
  SDK 22, build-tools 24.0.3, and support library 21.0.2 baseline.
- R2. Keep the GATT property checks using bitwise AND.
- R3. Fix app-level lint findings for backup behavior, row inflation, menu
  titles, hardcoded layout text, and text-size units.
- R4. Remove unused sample-template strings and dimensions.
- R5. Keep the single tile 9-patch in `drawable-nodpi` and document the narrow
  lint suppressions used by the obsolete toolchain.

## Verification

- `scripts/check-baseline.sh`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew lint --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew check --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`
