# Android HRM Make Root Override Protection

Status: Completed

## Problem

The Makefile derives its repository root from its own location, but GNU Make
command-line variables override an ordinary assignment. A hostile `ROOT` value
can redirect the baseline checker and all conditional Gradle gates away from
the reviewed checkout.

## Requirements

1. Protect the Makefile-derived root with GNU Make's `override` directive.
2. Preserve configurable Android SDK variables, the configurable Gradle
   command, every target, every SDK skip condition, and all existing commands.
3. Require exact protected-root, override-semantics, rooted baseline, and
   rooted lint/check/build contracts in the dependency-free checker.
4. Pass local, external-directory, and hostile-root `make check` gates.
5. Reject focused root, tool, path, target, and completed-plan mutations.

## Verification

- Run shell syntax and the dependency-free baseline checker first.
- Run bounded local, external-directory, and hostile command-line `ROOT`
  `make check` gates, recording whether the configured Android SDK executes or
  truthfully skips the legacy Gradle tasks.
- Run focused mutations plus workflow YAML, Android XML, SVG XML, artifact,
  conflict-marker, whitespace, and changed-line credential audits.

## Scope Boundaries

- Do not change HRM runtime behavior, BLE ownership, permissions,
  dependencies, workflows, Android sources, resources, or deployment.
- Do not weaken wrapper hashes or create local SDK placeholders.
- Do not claim emulator, physical BLE device, or production verification.
- Do not merge or close any pull request without explicit owner authorization.

## Work Completed

- Protected the Makefile-derived root while preserving Android SDK and Gradle
  configurability, every target, every skip condition, and all task commands.
- Added dependency-free contracts for exact override semantics, rooted
  baseline and Gradle execution, individual tasks, and this completed plan.

## Verification Results

- The focused baseline checker and shell syntax checks passed.
- Local, external-directory, and hostile command-line `ROOT` `make check`
  gates each passed the baseline checker while remaining anchored to this
  checkout.
- No Android SDK was configured, so lint, Gradle check, and assembly truthfully
  reported their designed skips in all three contexts; no SDK-backed compile,
  emulator, physical BLE device, or production result is claimed.
- All eleven focused mutations were rejected: missing `override`, `CURDIR`,
  recursive root assignment, `firstword`, eager SDK assignment, eager Gradle
  assignment, unrooted baseline, one unrooted Gradle gate, missing SDK-root
  propagation, replaced check task, and reopened plan status.
- Workflow YAML, Android XML, SVG XML, shell syntax, conflict-marker,
  whitespace, ignored-artifact, exact-diff, and changed-line credential audits
  passed; only the three intended files changed and no generated artifacts
  remained.
