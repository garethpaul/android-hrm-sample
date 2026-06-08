## Android HRM Sample Vision

Android HRM Sample is a Bluetooth LE sample based on Android's Bluetooth GATT
example. It scans for nearby BLE devices, connects to GATT services, and
displays service and characteristic data.

The repository is useful as a foundation for heart-rate-monitor exploration and
for understanding early Android BLE patterns. Project background and sample
notes live in [`README.md`](README.md).

The goal is to preserve the educational BLE sample while making future heart
rate monitor behavior explicit, tested, and safe around device data.

The current focus is:

Priority:

- Keep the Bluetooth LE scan/connect/display flow intact
- Preserve the sample's source layout and Android support dependencies
- Make SDK and build-tool assumptions visible
- Avoid changing BLE behavior without device or emulator verification notes

Next priorities:

- Add explicit heart-rate-service parsing if this repo is used beyond the base
  GATT sample
- Modernize Gradle, SDK levels, Android support libraries, and permissions
- Add tests around characteristic parsing and activity/service interaction
- Document manual BLE device verification steps

Contribution rules:

- One PR = one focused BLE, build, or documentation change.
- Keep sample-origin behavior recognizable unless a migration note explains the
  change.
- Verify scan/connect behavior on appropriate hardware when changing BLE code.
- Preserve license and attribution files.

## Security And Privacy

Bluetooth device identifiers and health-related measurements can be sensitive.
Changes should avoid unnecessary logging, analytics, or network transmission of
device names, addresses, or heart-rate data.

Modern permission work should request only the Bluetooth and location access
needed for the Android versions being supported.

## What We Will Not Merge (For Now)

- Health-data collection beyond demonstrable sample behavior
- BLE rewrites without hardware verification notes
- Permission changes that broaden access without rationale
- Attribution or license removals

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
