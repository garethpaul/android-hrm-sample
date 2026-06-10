# android-hrm-sample

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/android-hrm-sample` is an Android application or sample. Android Heart Rate Monitor

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Java (4), shell (1).

## Repository Contents

- `README.md` - project overview and local usage notes
- `.github/workflows/check.yml` - CI baseline that runs the root Make gate
- `build.gradle` - Android or Gradle build configuration
- `.google` - source or example code
- `Application` - source or example code
- `docs` - source or example code
- `gradle` - source or example code
- `gradlew` - Android or Gradle build configuration
- `scripts` - source or example code
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: .google, Application, docs, gradle, scripts
- Dependency and build manifests: build.gradle, gradlew
- Entry points or build surfaces: Gradle build files
- Test-looking files: no obvious test files detected

## Getting Started

### Prerequisites

- Git
- Android Studio or a compatible Android SDK
- Gradle or the checked-in Gradle wrapper when present

### Setup

```bash
git clone https://github.com/garethpaul/android-hrm-sample.git
cd android-hrm-sample
scripts/check-baseline.sh
./gradlew lint --no-daemon
./gradlew check --no-daemon
./gradlew assembleDebug --no-daemon
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Use Android Studio to open the project or run `./gradlew assembleDebug` when the Android SDK is configured.

## Testing and Verification

- `make check` - runs the source baseline and Android SDK-backed Gradle checks
  when `ANDROID_HOME` or `ANDROID_SDK_ROOT` is configured
- `scripts/check-baseline.sh` - runs SDK-free HRM sample baseline checks.
- The SDK-free baseline protects GATT property checks, BLE address validation,
  scan timeout cleanup, heart-rate characteristic matching, and resource lint
  contracts.
- BLE scan startup exits before adapter use when the device lacks BLE support
  or the Bluetooth manager service is unavailable.
- `./gradlew lint --no-daemon`, `./gradlew check --no-daemon`, and `./gradlew assembleDebug --no-daemon` when the Android SDK is configured.
- GitHub Actions runs the root `make check` gate through
  `.github/workflows/check.yml` on pushes and pull requests using Ubuntu 24.04
  with superseded-run cancellation.
- Local Gradle checks accept `ANDROID_HOME` or `ANDROID_SDK_ROOT`; CI clears
  both variables to preserve the documented static-only boundary.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.
- This legacy Android baseline pins Android build-tools 24.0.3 and Android support libraries 21.0.2.
- Heart-rate notification descriptor writes are null-guarded and use the
  matching enable or disable descriptor value.
- GATT broadcasts are package-scoped before delivery, and exact heart-rate
  values are not written to debug logs.
- BLE scan startup guards unsupported devices and missing Bluetooth manager
  services before requesting a Bluetooth adapter.
- BLE scan lifecycle guards nullable Bluetooth adapters, handlers, stopped list
  adapters, and null scan callback devices.
- Scan and GATT control activities guard nullable ActionBar setup before
  applying title or up-navigation presentation.
- GATT data-field updates guard missing data views so stale control layouts do
  not crash disconnect or data-available paths.
- GATT characteristic operations guard missing characteristics before read,
  notification, or data-broadcast parsing work.
- GATT connection callbacks ignore stale instances, reject failed status
  transitions, and start discovery through the active callback object.
- Heart-rate parsing reads the format flag from measurement byte zero and
  rejects truncated flag or value fields without unboxing null values.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include Application/build.gradle, Application/src/main/AndroidManifest.xml, Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java, Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java, and 6 more.
- Review changes touching mobile permissions or privacy-sensitive device data; examples from the scan include .google/packaging.yaml, Application/src/main/AndroidManifest.xml, Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java, Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java, and 6 more.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include Application/lint.xml, Application/src/main/AndroidManifest.xml, Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java, Application/src/main/res/layout/gatt_services_characteristics.xml, and 6 more.
- Review changes touching database, model, or persistence code; examples from the scan include docs/plans/2026-06-08-hrm-build-baseline.md.

## Maintenance Notes

- This looks like a legacy Android project or sample. Expect Android SDK, Gradle, and support-library versions to matter.
- The current baseline keeps Gradle 2.2.1, Android Gradle Plugin 1.0.0, compile SDK 22, target SDK 22, and Android build-tools 24.0.3.
- The SDK-free baseline protects GATT property checks, BLE address validation, BLE scan timeout cleanup, and legacy resource lint contracts.
- Heart-rate measurement notification setup matches the standard GATT
  characteristic UUID, not a display label string identity check.
- `Application/lint.xml` documents the obsolete lint API database limitation and the intentional `drawable-nodpi` bitmap asset baseline.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-08-hrm-check-wrapper.md` for the root verification
  wrapper baseline.
- See `docs/plans/2026-06-09-hrm-heart-rate-characteristic-match.md` for the
  heart-rate characteristic matching contract.
- See `docs/plans/2026-06-09-hrm-notification-descriptor-guard.md` for the
  heart-rate notification descriptor contract.
- See `docs/plans/2026-06-09-hrm-actionbar-guard.md` for the nullable ActionBar
  startup guard.
- See `docs/plans/2026-06-09-hrm-bluetooth-manager-guard.md` for the BLE scan
  startup service guard.
- See `docs/plans/2026-06-09-hrm-scan-lifecycle-guards.md` for BLE scan
  lifecycle and callback null guards.
- See `docs/plans/2026-06-09-hrm-broadcast-privacy.md` for the package-scoped
  GATT broadcast and heart-rate logging contract.
- See `docs/plans/2026-06-09-hrm-data-field-guard.md` for GATT data-field
  null guards.
- See `docs/plans/2026-06-09-hrm-characteristic-null-guards.md` for GATT
  characteristic null guards.
- See `docs/plans/2026-06-10-ci-baseline.md` for the lightweight CI baseline.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
