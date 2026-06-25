#!/usr/bin/env python3
from pathlib import Path


root = Path(__file__).resolve().parents[1]
service = (root / "Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java").read_text()
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
assert '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>' in manifest

print("BLE source contracts passed.")
