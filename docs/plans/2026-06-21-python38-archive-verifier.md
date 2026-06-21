# Python 3.8 Archive Verifier Compatibility

Status: Completed

## Problem

The authenticated runner invokes `scripts/verify-archive-tree.py` with
`/usr/bin/python3`. Its builtin generic annotations were evaluated at import
time and failed under Python 3.8 before archive provenance could be checked.
The repository also tracked generated CPython bytecode for verification
scripts.

## Change

- Postpone annotation evaluation so the verifier runs on Python 3.8 while
  retaining its existing types and behavior.
- Remove tracked `scripts/__pycache__` bytecode and ignore Python caches.
- Re-pin the verifier digest enforced by `scripts/check-baseline.sh`.

## Verification

- `scripts/check-baseline.sh` from the repository root and an external working
  directory.
- `scripts/test-ble-source-contracts.py`.
- `scripts/test-ble-session-guards.sh`.
- `scripts/test-ble-mutations.sh`.
- `scripts/test-publication-gate.sh`, including the fake hosted runner cases
  that execute the verifier with `/usr/bin/python3`.
