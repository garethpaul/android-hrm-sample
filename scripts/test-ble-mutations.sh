#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=${TMPDIR:-/tmp}/android-hrm-ble-mutations.$$
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
mkdir -p "$TEST_ROOT"

copy_repository() {
  destination=$1
  mkdir -p "$destination"
  (cd "$ROOT_DIR" && tar --exclude=.git -cf - .) | (cd "$destination" && tar -xf -)
}

expect_rejected() {
  name=$1
  mutation=$2
  test_command=$3
  fixture="$TEST_ROOT/$name"
  copy_repository "$fixture"
  (cd "$fixture" && sh -c "$mutation")
  if (cd "$fixture" && sh -c "$test_command") >"$TEST_ROOT/$name.log" 2>&1; then
    printf '%s\n' "FAIL: mutation survived: $name" >&2
    exit 1
  fi
  printf '%s\n' "PASS: mutation rejected: $name"
}

expect_rejected stale-scan-callback \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java'; s=open(p).read(); s=s.replace('mScanGeneration.isCurrent(generation)', 'true', 1); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected scan-invalidation-removal \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java'; s=open(p).read().replace('mScanGeneration.invalidate();', 'mScanning = false;'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected recycled-row-identity \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java'; s=open(p).read().replace('deviceAddress.equals(viewHolder.boundDeviceAddress)', 'true'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected stale-gatt-release \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java'; s=open(p).read().replace('releaseIfCurrent(gatt)', 'releaseCurrent()'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected descriptor-rollback-owner \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java'; s=open(p).read().replace('rollbackCharacteristicNotification(gatt, characteristic, enabled)', 'rollbackCharacteristicNotification(characteristic, enabled)'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected location-permission-removal \
  "python3 -c \"p='Application/src/main/AndroidManifest.xml'; s=open(p).read().replace('    <uses-permission android:name=\\\"android.permission.ACCESS_COARSE_LOCATION\\\"/>\\n', ''); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected gatt-uuid-log-restoration \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java'; s=open(p).read().replace('                    mBluetoothLeService.setCharacteristicNotification(gattCharacteristic, true);', '                    Log.v(\\\"loop\\\", uuid);\\n                    mBluetoothLeService.setCharacteristicNotification(gattCharacteristic, true);', 1); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected data-event-log-restoration \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java'; s=open(p).read().replace('                displayData(intent.getStringExtra(BluetoothLeService.EXTRA_DATA));', '                Log.v(\\\"received\\\", \\\"data\\\");\\n                displayData(intent.getStringExtra(BluetoothLeService.EXTRA_DATA));', 1); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected permission-exception-guard-removal \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java'; s=open(p).read().replace('catch (SecurityException securityException)', 'catch (RuntimeException runtimeException)'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected generation-always-current \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/CallbackGeneration.java'; s=open(p).read().replace('return candidate == generation;', 'return true;'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-session-guards.sh"
expect_rejected release-unowned-gatt \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/GattConnectionOwner.java'; s=open(p).read().replace('if (!isCurrent(candidate)) {', 'if (candidate == null) {'); open(p,'w').write(s)\"" \
  "./scripts/test-ble-session-guards.sh"
expect_rejected heart-rate-parser-bypass \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java'; s=open(p).read().replace('HeartRateMeasurementParser.parse(characteristic.getValue())', 'null', 1); open(p,'w').write(s)\"" \
  "./scripts/test-ble-source-contracts.py"
expect_rejected heart-rate-reserved-flags \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('(flags & RESERVED_FLAGS) != 0', 'false', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-byte-order \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('unsignedByte(packet[offset]) | unsignedByte(packet[offset + 1]) << 8', 'unsignedByte(packet[offset]) << 8 | unsignedByte(packet[offset + 1])', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-contact-support \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('(flags & SENSOR_CONTACT_SUPPORTED) == 0', 'false', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-energy-offset \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('            offset += 2;', '            offset += 0;', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-empty-rr \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('remainingBytes < 2 ||', 'remainingBytes < 0 ||', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-trailing-bytes \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java'; s=open(p).read().replace('if (offset != packet.length)', 'if (false)', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"
expect_rejected heart-rate-rr-alias \
  "python3 -c \"p='Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurement.java'; s=open(p).read().replace('return rrIntervals.clone();', 'return rrIntervals;', 1); open(p,'w').write(s)\"" \
  "./scripts/test-heart-rate-parser.sh"

printf '%s\n' "BLE hostile mutations passed."
