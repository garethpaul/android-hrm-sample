# HRM Device Verification Checklist

Status: In Progress

## Problem

Portable contracts cover BLE scanning, GATT ownership, service selection,
notification registration, descriptor rollback, and packet guards, but no
checklist defines compatible heart-rate sensor evidence.

## Requirements

1. Add an exact-commit matrix for scan, connect, discovery, notifications,
   measurements, failures, replacement connections, and lifecycle behavior.
2. Require sanitized toolchain, phone/sensor, result, and log evidence.
3. Keep repository checks separate from unexecuted BLE hardware scenarios.
4. Add mutation-sensitive contracts for the checklist and completion evidence.

## Scope Boundaries

- Do not modernize Gradle, Android APIs, target SDK, or dependencies.
- Do not add BLE addresses, health readings, dumps, APKs, logs, or keys.
- Do not claim emulator or physical-sensor execution from portable checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Pending implementation and bounded repository validation.
