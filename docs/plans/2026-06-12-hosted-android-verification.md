# Hosted Android Verification

## Status: Completed

## Context

The workflow clears Android SDK variables and runs only source contracts. The
current PR head passes Android lint with zero findings, Gradle check, and debug
assembly locally with Android API 22, build-tools 24.0.3, and Java 8.

AGP 1.0 supports its legacy non-queued PNG cruncher, avoiding the concurrent
resource-processing race seen in this toolchain family on clean hosted runners.

## Goal

Run the complete Android gate in hosted CI with deterministic resource
processing while preserving BLE behavior and trust boundaries.

## Changes

- Install Android API 22 and build-tools 24.0.3 before selecting Java 8.
- Run canonical `make check` with a 15-minute timeout.
- Select the non-queued PNG cruncher without skipping aapt validation.
- Preserve immutable actions, read-only permissions, disabled checkout
  credentials, and the byte-exact workflow checker.
- Update README and CI plan evidence.

## Verification

- Passed SDK-backed `make check` from the repository with zero lint issues.
- Passed the complete gate from a fresh external clone.
- Confirmed nine hostile workflow, cruncher, checker, documentation, and
  plan-status mutations are rejected.
- Passed `git diff --check`.
- GitHub Actions pull-request run `27401864615` passed the complete gate in 51
  seconds for implementation commit
  `dbfd8b1a8c2bfd52444c3210f508823c2445453b`.

## Boundaries

- Do not change BLE scan, connection, callback, or packet behavior.
- Do not modernize Gradle, AGP, support libraries, or target SDK.
- Do not add permissions, credentials, signing material, or dependencies.
