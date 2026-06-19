# Android HRM Device Verification

Run this matrix on the exact reviewed commit with a compatible Android SDK,
Java 8, legacy Gradle runtime, and an authorized BLE heart-rate sensor. Portable
contracts do not substitute for physical BLE timing and measurement evidence.

## Evidence Header

Record these values without BLE addresses, device names, heart-rate values,
GATT dumps, logs, APKs, keys, or account data:

- commit SHA and pull request
- tester and UTC timestamp
- Android Studio, SDK, build tools, Java, and Gradle versions
- phone model, Android version, and sanitized sensor type
- clean install or upgrade path
- Gradle lint, check, and assemble result

Mark every row `pass`, `fail`, `blocked`, or `not run`. Explain blocked and
unexecuted rows. Do not convert `not run` into passing evidence.

## Scan And Connection Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| BLE unavailable | Scan fails closed before adapter use. | not run | |
| Scan timeout | Scanning stops and progress state resets. | not run | |
| Select discovered sensor | One device-control flow receives a valid address. | not run | |
| Connect and discover | Current GATT publishes services only after success. | not run | |
| Service unavailable | UI actions remain guarded until binding succeeds. | not run | |
| Replacement sensor | Prior GATT closes exactly once and cannot release replacement ownership. | not run | |
| Revoked scan permission | Scan fails closed with a generic diagnostic and no crash. | not run | |

## Heart-Rate Notification Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Heart-rate service present | Standard measurement characteristic is selected. | not run | |
| Characteristic absent | Notification setup fails closed. | not run | |
| Local registration failure | Descriptor write is not attempted. | not run | |
| Descriptor missing or unwritable | Local notification state rolls back. | not run | |
| Descriptor callback failure | Matching pending registration rolls back once. | not run | |
| Stale descriptor callback | Old GATT or descriptor cannot affect current state. | not run | |
| Valid 8-bit and 16-bit packet | Measurement displays with correct format. | not run | |
| Truncated packet | Data is ignored without a crash or stale display update. | not run | |

## Lifecycle And Race Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Disconnect during discovery | Current connection clears without stale data. | not run | |
| Rapid disconnect/reconnect | Callbacks from replaced GATT are ignored. | not run | |
| Pause during scan | Scan callbacks stop after lifecycle cleanup. | not run | |
| Stop then immediately rescan | Queued callbacks from the prior generation are ignored. | not run | |
| Rotate while connected | Recreated activity uses only the current service/GATT state. | not run | |
| Sensor leaves range | UI reports disconnect without leaking identifiers. | not run | |

Sanitized evidence must not contain Bluetooth addresses, names, advertising
payloads, heart-rate measurements, service dumps, stack traces, or device IDs.

## Completion

Record unresolved failures and protected evidence links outside git. A runtime
claim requires all applicable rows to pass on the exact commit. This repository
currently records every BLE device and heart-rate row as unexecuted.
