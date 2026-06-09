# HRM GATT Data Field Guard

Date: 2026-06-09
Status: Completed

## Problem

`DeviceControlActivity` assumed the GATT data value view was always present.
Stale control layouts could crash disconnect cleanup or data-available updates
before the sample could recover.

## Scope

- Guard `clearUI()` before writing the no-data message.
- Guard `displayData()` so it requires both data and a data field view.
- Preserve existing GATT broadcast, characteristic, and notification behavior.
- Extend SDK-free baseline coverage for the control layout guard.

## Verification

- Red: `make lint` failed on the missing GATT data-field guard.
- Green: `make lint` passes after adding null-safe data-field updates.
- Full gate: `make check`.
