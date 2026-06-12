# CI Baseline

Status: Completed

## Context

The portfolio remediation plan calls for lightweight CI on high-priority repos
with passing local checks. The HRM sample already exposes a root `make check`
contract that runs the SDK-free source baseline and runs Gradle checks when an
Android SDK is configured.

## Completed Scope

- Added a GitHub Actions workflow for pushes, pull requests, and manual runs.
- Pinned checkout to an immutable revision, limited permissions to repository
  reads, and bounded the job to five minutes.
- Configured CI to run the root `make check` contract.
- Removed the maintainer-specific default SDK path and cleared ambient hosted
  SDK variables so CI cannot accidentally invoke the unsupported Gradle path.
- Extended the SDK-free baseline and docs so the CI gate remains visible.
- Disabled persisted checkout credentials and replaced partial string matching
  with a canonical single-workflow contract.
- Added self-protecting CODEOWNERS coverage for the workflow, Makefile, and
  baseline checker; repository rules remain responsible for requiring owner
  approval.

Android SDK-backed CI should follow migration of the historical Gradle,
Android plugin, repository, and API-level baseline.

## Verification

- `make check`
- `git diff --check`
