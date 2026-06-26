#!/usr/bin/env python3
from pathlib import Path


root = Path(__file__).resolve().parents[1]
service = (root / "Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java").read_text()
measurement = (root / "Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurement.java").read_text()
parser = (root / "Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java").read_text()
parser_test = (root / "scripts/tests/HeartRateMeasurementParserTest.java").read_text()
scan = (root / "Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java").read_text()
control = (root / "Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java").read_text()
manifest = (root / "Application/src/main/AndroidManifest.xml").read_text()

required_service = [
    "GattConnectionOwner<BluetoothGatt>",
    "synchronized (mGattOwner)",
    "releaseIfCurrent(gatt)",
    "releaseCurrent()",
    "gattToClose.close();",
    "previousGatt.close();",
    "currentGatt.setCharacteristicNotification(",
    "currentGatt.writeDescriptor(descriptor)",
    "rollbackCharacteristicNotification(gatt, characteristic, enabled)",
]
for contract in required_service:
    assert contract in service, "missing GATT ownership contract: %s" % contract
assert "private BluetoothGatt mBluetoothGatt;" not in service
assert service.count("releaseIfCurrent(gatt)") >= 3
assert "HeartRateMeasurementParser.parse(characteristic.getValue())" in service
assert "String.valueOf(measurement.beatsPerMinute())" in service
assert "characteristic.getIntValue(" not in service

required_parser = [
    "private static final int RESERVED_FLAGS = 0xe0;",
    "(flags & RESERVED_FLAGS) != 0",
    "(flags & SENSOR_CONTACT_SUPPORTED) == 0",
    "int heartRateBytes = (flags & HEART_RATE_UINT16) != 0 ? 2 : 1;",
    "unsignedLittleEndian16(packet, offset)",
    "(flags & ENERGY_EXPENDED_PRESENT) != 0",
    "(flags & RR_INTERVAL_PRESENT) != 0",
    "remainingBytes < 2 || remainingBytes % 2 != 0",
    "if (offset != packet.length)",
]
for contract in required_parser:
    assert contract in parser, "missing heart-rate parser contract: %s" % contract

assert measurement.count("rrIntervals.clone()") == 2
for case in [
    "parsesUnsignedEightBitHeartRate",
    "parsesUnsignedSixteenBitHeartRate",
    "parsesSensorContactStates",
    "parsesEnergyExpended",
    "parsesMultipleRrIntervals",
    "parsesCombinedOptionalFields",
    "protectsRrIntervalOwnership",
    "rejectsMalformedPackets",
]:
    assert case in parser_test, "missing heart-rate parser test case: %s" % case

required_scan = [
    "CallbackGeneration mScanGeneration",
    "createLeScanCallback(final long generation)",
    "mScanGeneration.isCurrent(generation)",
    "mScanGeneration.invalidate();",
    "boundDeviceAddress",
    "BluetoothAdapter.checkBluetoothAddress(deviceAddress)",
    "deviceAddress.equals(viewHolder.boundDeviceAddress)",
]
for contract in required_scan:
    assert contract in scan, "missing scan-generation contract: %s" % contract
assert scan.count("catch (SecurityException securityException)") >= 2

assert "clearGattSelectionState();" in control
assert 'Log.v("loop", uuid);' not in control, "GATT UUIDs must not be logged"
assert 'Log.v("received", "data");' not in control, "BLE data events must not be routinely logged"
assert '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>' in manifest

print("BLE source contracts passed.")
