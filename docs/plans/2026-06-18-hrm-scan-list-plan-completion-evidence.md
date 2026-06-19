---
title: HRM Scan List Plan Completion Evidence
type: fix
date: 2026-06-18
status: completed
---

# HRM Scan List Plan Completion Evidence

## Summary

Reconcile the shipped scan-list selection plan with the implementation and
verification that already completed, and make that completion record a durable
baseline contract.

## Problem Frame

The scan-list selection guards are implemented, locally validated, pushed, and
terminal-green on PR #18, but their authoritative plan still reads as planned
work. It lacks completed frontmatter and factual verification evidence, while
the baseline checker only requires planning metadata and pre-implementation
scope. That mismatch can leave future maintainers unable to distinguish a
shipped boundary from an abandoned proposal.

## Requirements

- R1. The shipped scan-list plan must declare `status: completed`.
- R2. The shipped plan must record the actual repository, external-directory,
  mutation, diff, artifact, secret, and hosted verification boundaries without
  claiming emulator, physical-device, or live BLE coverage.
- R3. The portable baseline checker must reject removal of the completed status
  or completed-verification evidence.
- R4. Android runtime code, dependencies, manifests, workflows, and existing
  scan-list behavior must remain unchanged.

## Implementation Units

### U1. Reconcile The Shipped Plan

- Add completed status and factual completion evidence to
  `docs/plans/2026-06-17-hrm-scan-list-selection-guards.md`.
- Preserve the plan's requirements, decisions, scope, and native verification
  boundary.

### U2. Make Completion Evidence Durable

- Extend the existing scan-list plan block in `scripts/check-baseline.sh` to
  require completed status and the completed-verification record.
- Prove focused mutations of each new contract are rejected in disposable
  copies while the live worktree remains unchanged.

### U3. Validate And Ship

- Run shell syntax, the portable baseline, configured Android gates from the
  repository and an external directory, focused mutations, and final
  diff/artifact/secret audits.
- Push the narrow stack, update PR #18 without changing its required section
  contract, and capture one bounded exact-head hosted snapshot.

## Acceptance Examples

- AE1. Removing `status: completed` from the shipped plan causes the baseline
  checker to fail with the scan-list completion-evidence contract.
- AE2. Removing completed verification evidence causes the same focused
  contract to fail.
- AE3. The unchanged Android source still passes the complete Java 8/API 22
  gate from both supported invocation locations.

## Risks And Mitigations

- Static text checks can become brittle, so require a small set of stable,
  factual completion markers rather than entire paragraphs or line numbers.
- Historical evidence can be overstated, so distinguish prior exact-head hosted
  success from the new documentation-only head and take a fresh bounded hosted
  snapshot after pushing.

## Scope Boundaries

Do not change application behavior, Android configuration, dependencies,
workflow pins, device verification claims, or any plan other than the shipped
scan-list plan and this remediation record.

## Work Completed

- Reconciled the shipped scan-list plan to completed status with factual local,
  mutation, audit, hosted, and native-device boundary evidence.
- Extended the existing scan-list plan checker block to require completed
  status and stable completion-verification markers.
- Left application source, Android configuration, dependencies, manifests, and
  workflows unchanged.

## Completed Verification

- `sh -n scripts/check-baseline.sh` and the focused portable baseline passed.
- Initialized, committed temporary repositories proved that removing either
  `status: completed` or `## Completed Verification` is rejected with the
  expected scan-list completion-evidence error.
- Repository and external-directory `make check` passed under Corretto Java 8
  with Android API 22 and build-tools 24.0.3, including zero-issue
  debug/release lint, Gradle checks, compilation, and debug APK assembly.
- No emulator, physical device, or live BLE peripheral was exercised.
