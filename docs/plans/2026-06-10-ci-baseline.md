# CI Baseline

Status: Completed

## Context

The portfolio remediation plan calls for lightweight CI on high-priority repos
with passing local checks. The HRM sample already exposes a root `make check`
contract that runs the SDK-free source baseline and runs Gradle checks when an
Android SDK is configured.

## Completed Scope

- Added a GitHub Actions workflow for pushes, pull requests, and manual runs.
- Pinned setup actions to immutable revisions, limited permissions to
  repository reads, and bounded the job to 15 minutes.
- Install Android API 22 and build-tools 24.0.3, select Java 8, and run the
  complete `make check` gate including lint, Gradle check, and debug assembly.
- Use the legacy non-queued PNG cruncher for deterministic clean-runner
  resource processing while preserving aapt validation.
- Extended the SDK-free baseline and docs so the CI gate remains visible.
- Disabled persisted checkout credentials and replaced partial string matching
  with a canonical single-workflow contract.
- Added self-protecting CODEOWNERS coverage for the workflow, Makefile, and
  baseline checker; repository rules remain responsible for requiring owner
  approval.

Historical Gradle, Android plugin, support library, and API-level modernization
remains a separate compatibility-focused change.

## Verification

- `make check`
- `git diff --check`
