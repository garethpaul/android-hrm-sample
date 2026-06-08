---
title: HRM Sample Build Baseline
type: chore
status: completed
date: 2026-06-08
---

# HRM Sample Build Baseline

## Summary

Make the legacy Bluetooth LE heart-rate sample build reproducibly on the local Android SDK by moving dependency resolution from JCenter to HTTPS Maven Central, pinning host-compatible build-tools, adding an SDK-free baseline check, and documenting the verification path.

---

## Problem Frame

The sample is an Android Gradle Plugin 1.0.0 project that still uses JCenter and build-tools 22.0.1. With the local SDK configured, Gradle task listing succeeds, but debug assembly fails because build-tools 22.0.1 invokes a 32-bit `aapt` binary that cannot load `libz.so.1` on this host.

---

## Requirements

- R1. Dependency repositories must use explicit HTTPS Maven Central URLs instead of JCenter.
- R2. The app must keep compile SDK 22, target SDK 22, and support library 21.0.2 dependencies unchanged.
- R3. The app must use build-tools 24.0.3 so debug assembly uses a host-compatible `aapt`.
- R4. The repository must include a source check that runs without Android SDK configuration and verifies the build baseline declarations.
- R5. README documentation must describe the legacy toolchain, Android SDK environment variables, and verification commands.
- R6. Larger migrations to modern Android Gradle Plugin, AndroidX, current BLE permission behavior, and device tests must remain explicit follow-up work.

---

## Key Technical Decisions

- **Change build-tools only:** Build-tools 24.0.3 fixes the local `aapt` loader failure while preserving Gradle 2.2.1, Android Gradle Plugin 1.0.0, compile SDK 22, and target SDK 22.
- **Use Maven Central directly:** The Android Gradle plugin and support dependencies resolve from Maven Central, so JCenter can be removed for this baseline.
- **Keep BLE behavior untouched:** No changes to GATT connection, heart-rate parsing, scanning, permissions, or UI behavior in this pass.
- **Add SDK-free checks:** A shell script can catch build metadata drift before a compatible Android SDK is configured.

---

## Scope Boundaries

- This pass does not migrate Gradle, Android Gradle Plugin, support libraries, or AndroidX.
- This pass does not change Bluetooth permissions or runtime scanning behavior.
- This pass does not add emulator, instrumentation, or BLE device tests.
- This pass does not change package names, sample assets, or app UI.

---

## Implementation Units

### U1. Stabilize Build Metadata

- **Goal:** Make dependency resolution deterministic and debug assembly runnable on the current host.
- **Files:** `Application/build.gradle`
- **Patterns:** Preserve the existing sample build structure and source set layout; change only repositories and build-tools.
- **Test Scenarios:**
  - `Application/build.gradle` uses `https://repo1.maven.org/maven2`.
  - `Application/build.gradle` no longer contains `jcenter()`.
  - `Application/build.gradle` pins `buildToolsVersion "24.0.3"`.
  - `Application/build.gradle` keeps `compileSdkVersion 22`, `targetSdkVersion 22`, and support dependency versions `21.0.2`.
- **Verification:** `scripts/check-baseline.sh`, `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`

### U2. Add SDK-Free Baseline Check

- **Goal:** Provide a repeatable local quality gate before Android SDK setup.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell, repo-root detection, fail-fast messages.
- **Test Scenarios:**
  - The script fails if JCenter is reintroduced.
  - The script fails if compile SDK, target SDK, support dependency versions, Maven Central URL, or build-tools declarations drift.
- **Verification:** `scripts/check-baseline.sh`

### U3. Document Restore and Verification

- **Goal:** Make the sample maintainable as a legacy Android project.
- **Files:** `README.md`
- **Patterns:** Preserve the original sample context while adding local toolchain and verification sections.
- **Test Scenarios:**
  - README lists Gradle 2.2.1, Android Gradle Plugin 1.0.0, compile SDK 22, target SDK 22, build-tools 24.0.3, and support libraries 21.0.2.
  - README lists `scripts/check-baseline.sh`.
  - README lists SDK-backed Gradle task and debug assembly commands.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Build-tools 24.0.3 is still legacy; a future migration should update Gradle, Android Gradle Plugin, SDK levels, and BLE runtime permissions together.
- Debug assembly proves buildability, not runtime behavior with a real BLE heart-rate device.
- The sample has no local unit-testable abstraction around heart-rate parsing or GATT state transitions.

---

## Sources / Research

- `Application/build.gradle` uses JCenter, Android Gradle Plugin 1.0.0, support libraries 21.0.2, compile SDK 22, target SDK 22, and build-tools 22.0.1.
- `gradle/wrapper/gradle-wrapper.properties` pins Gradle 2.2.1 over HTTPS.
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew tasks --no-daemon` succeeds.
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon` fails because build-tools 22.0.1 `aapt` cannot load `libz.so.1`.
