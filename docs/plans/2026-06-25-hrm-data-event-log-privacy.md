# HRM Data-Event Log Privacy

Status: Completed

## Context

`DeviceControlActivity` writes a verbose `received/data` log entry for every
in-process `ACTION_DATA_AVAILABLE` broadcast. Although it omits the measurement
value, routine timestamps reveal when BLE data and heart-rate notifications are
arriving and provide no diagnostic value.

## Decision

Remove the per-event verbose log while preserving local-broadcast delivery and
UI rendering. Keep failure-category logs that do not contain BLE identifiers or
measurements.

## Verification Completed

- The pre-fix source contract failed while the routine data-event log remained.
- Portable source, Java session, baseline, publication-gate, and hostile
  mutation checks pass after removal.
- Hosted Android and CodeQL checks plus exact-head Codex review remain required
  before merge.
