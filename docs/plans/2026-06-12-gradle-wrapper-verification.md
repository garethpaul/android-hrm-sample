---
title: Gradle Wrapper Verification
date: 2026-06-12
status: completed
execution: code
---

# Gradle Wrapper Verification

## Summary

Add a checksum-capable generated Gradle Wrapper bootstrap while preserving the
heart-rate sample's Gradle 2.2.1, Java 8, API 22, and BLE behavior. Establish
the repository's first exact wrapper provenance contract and require the
existing Android gate to remain green.

## Problem Frame

The repository's complete source, lint, Gradle check, and debug-build gate is
characterized, but its legacy wrapper downloads Gradle 2.2.1 without archive
verification and the SDK-free checker does not authenticate the checked-in
wrapper JAR or launchers. A runtime upgrade would unnecessarily combine this
supply-chain change with Android and BLE compatibility work.

## Requirements

- **R1:** Continue executing `gradle-2.2.1-all.zip` under Java 8 without
  changing Android Gradle Plugin 1.0.0, compile/target SDK 22, build-tools
  24.0.3, support libraries, source layout, or BLE behavior.
- **R2:** Pin Gradle's official Gradle 2.2.1 all-distribution SHA-256,
  `1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab`.
- **R3:** Regenerate `gradlew`, `gradlew.bat`, and `gradle-wrapper.jar` with
  official Gradle 8.14.5 tooling and verify its published wrapper JAR SHA-256,
  `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`.
- **R4:** Extend the dependency-free baseline to reject wrapper URL,
  checksum, JAR, launcher, documentation, and completion-evidence drift.
- **R5:** Pass the complete Java 8/API 22 `make check` gate locally and on the
  final pull-request head before tracker reconciliation.

## Key Technical Decisions

- **Separate bootstrap from runtime:** use Gradle 8.14.5 only to generate the
  wrapper while retaining the legacy Gradle runtime required by the app.
- **Authenticate both trust boundaries:** verify the downloaded distribution
  at runtime and exact checked-in wrapper artifacts in the static checker.
- **Keep availability claims narrow:** checksum verification authenticates
  expected bytes but does not make an uncached build offline-reproducible.
- **Preserve the all distribution:** avoid changing IDE/source archive
  availability in this security-only unit.

## Scope Boundaries

In scope: the four wrapper files, `scripts/check-baseline.sh`, repository
guidance, and local/hosted evidence. Deferred: Android/Gradle runtime upgrades,
support libraries, permissions, BLE logic, UI, and hardware behavior.

## Implementation Units

### U1. Verified Wrapper Bootstrap

Generate the wrapper with official Gradle 8.14.5 tooling, retain Gradle 2.2.1,
and prove a fresh Java 8 bootstrap accepts the official archive and rejects an
incorrect checksum.

### U2. Static Contract And Documentation

Add exact wrapper properties, JAR, launcher, documentation, and completed-plan
contracts to the existing SDK-free checker. Document the online availability
boundary without claiming Android modernization.

### U3. Compatibility And Hosted Evidence

Run `make check` from the repository and an external working directory,
exercise focused hostile mutations, and require final exact-head pull-request
and CodeQL success.

## Risks And Mitigations

- Use a fresh temporary Gradle user home so cached archives cannot hide
  checksum behavior.
- Verify `./gradlew --version` under Java 8 before invoking project tasks.
- Reject changes to application/build metadata so bootstrap hardening remains
  isolated from BLE compatibility risk.

## Sources

- [Gradle Wrapper documentation](https://docs.gradle.org/current/userguide/gradle_wrapper.html)
- [Gradle security best practices](https://docs.gradle.org/current/userguide/best_practices_security.html)
- [Gradle 2.2.1 all-distribution checksum](https://services.gradle.org/distributions/gradle-2.2.1-all.zip.sha256)
- [Gradle 8.14.5 wrapper JAR checksum](https://services.gradle.org/distributions/gradle-8.14.5-wrapper.jar.sha256)

## Work Completed

- Regenerated all four wrapper files with official Gradle 8.14.5 tooling while
  retaining the Gradle 2.2.1 all distribution and existing Android runtime.
- Added the official distribution checksum and exact wrapper JAR, launcher,
  properties, documentation, and plan contracts.
- Documented the authenticated-download boundary without changing build files,
  application code, or BLE behavior.

## Verification Completed

- A fresh temporary Gradle user home downloaded the official distribution and
  reported Gradle 2.2.1 on Corretto Java 8 (`1.8.0_482`).
- A disposable wrapper with an incorrect checksum was rejected before Gradle
  execution and reported the official archive checksum.
- SDK-backed `make check` passed with zero lint findings, Gradle check, and
  debug assembly under Java 8/API 22 from the repository and an external
  working directory.
- Focused hostile mutations rejected wrapper properties, JAR, launcher,
  documentation, and incomplete plan evidence.
- `sh -n scripts/check-baseline.sh` and `git diff --check` passed.

## Hosted Verification

Hosted pull-request and CodeQL evidence will be recorded after the exact
implementation head completes both canonical checks.
