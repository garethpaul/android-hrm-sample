#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_FILE="$ROOT_DIR/Application/build.gradle"
CONTROL_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java"
SCAN_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java"
BLE_SERVICE="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java"
README="$ROOT_DIR/README.md"
RES_DIR="$ROOT_DIR/Application/src/main/res"

require_contains() {
  pattern=$1
  message=$2

  if ! grep -Fq "$pattern" "$BUILD_FILE"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_absent() {
  pattern=$1
  message=$2

  if grep -Fq "$pattern" "$BUILD_FILE"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_contains "url 'https://repo1.maven.org/maven2'" \
  "Build repositories must use HTTPS Maven Central."
require_absent "jcenter()" \
  "Build repositories must not use JCenter."
require_contains "compileSdkVersion 22" \
  "Compile SDK must stay pinned to 22."
require_contains "buildToolsVersion \"24.0.3\"" \
  "Android build-tools must stay pinned to 24.0.3."
require_contains "targetSdkVersion 22" \
  "Target SDK must stay pinned to 22."
require_contains "com.android.support:support-v4:21.0.2" \
  "support-v4 must stay pinned to 21.0.2."
require_contains "com.android.support:support-v13:21.0.2" \
  "support-v13 must stay pinned to 21.0.2."
require_contains "com.android.support:cardview-v7:21.0.2" \
  "cardview-v7 must stay pinned to 21.0.2."

if ! grep -Fq "Android build-tools 24.0.3" "$ROOT_DIR/README.md"; then
  printf '%s\n' "README must document the pinned Android build-tools version." >&2
  exit 1
fi

if grep -Fq "getActionBar().set" "$SCAN_ACTIVITY" || grep -Fq "getActionBar().set" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "HRM activities must guard nullable getActionBar() results." >&2
  exit 1
fi

for pattern in \
  "private void configureActionBar()" \
  "ActionBar actionBar = getActionBar();" \
  "if (actionBar == null)" \
  "actionBar.setDisplayShowTitleEnabled(false);"; do
  if ! grep -Fq "$pattern" "$SCAN_ACTIVITY"; then
    printf '%s\n' "Missing scan ActionBar guard: $pattern" >&2
    exit 1
  fi
done

for pattern in \
  "private void configureActionBar()" \
  "ActionBar actionBar = getActionBar();" \
  "if (actionBar == null)" \
  "actionBar.setDisplayShowTitleEnabled(false);" \
  "actionBar.setDisplayHomeAsUpEnabled(true);"; do
  if ! grep -Fq "$pattern" "$CONTROL_ACTIVITY"; then
    printf '%s\n' "Missing control ActionBar guard: $pattern" >&2
    exit 1
  fi
done

if grep -Fq "charaProp | BluetoothGattCharacteristic.PROPERTY_READ" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Read-property check must use bitwise AND, not OR." >&2
  exit 1
fi

if grep -Fq "charaProp | BluetoothGattCharacteristic.PROPERTY_NOTIFY" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Notify-property check must use bitwise AND, not OR." >&2
  exit 1
fi

if ! grep -Fq "charaProp & BluetoothGattCharacteristic.PROPERTY_READ" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Read-property check is missing." >&2
  exit 1
fi

if ! grep -Fq "charaProp & BluetoothGattCharacteristic.PROPERTY_NOTIFY" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Notify-property check is missing." >&2
  exit 1
fi

if grep -Fq 'gattInfo == "Heart Rate Measurement"' "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Heart-rate characteristic matching must not use Java string identity." >&2
  exit 1
fi

if ! grep -Fq "SampleGattAttributes.HEART_RATE_MEASUREMENT.equals(uuid)" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Heart-rate characteristic matching must use the standard UUID constant." >&2
  exit 1
fi

if ! grep -Fq "if (mDataField != null)" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "GATT data field updates must guard missing data views." >&2
  exit 1
fi

if ! grep -Fq "if (data != null && mDataField != null)" "$CONTROL_ACTIVITY"; then
  printf '%s\n' "GATT data display must require both data and data view." >&2
  exit 1
fi

if ! grep -Fq "BluetoothAdapter.checkBluetoothAddress(address)" "$BLE_SERVICE"; then
  printf '%s\n' "BLE connection must validate device addresses before getRemoteDevice." >&2
  exit 1
fi

for gatt_connection_contract in \
  "if (gatt == null || gatt != mBluetoothGatt)" \
  "if (status != BluetoothGatt.GATT_SUCCESS)" \
  "gatt.close();" \
  "mBluetoothGatt = null;" \
  "gatt.discoverServices()" \
  "BluetoothGatt bluetoothGatt = device.connectGatt(this, false, mGattCallback);" \
  "if (bluetoothGatt == null)"; do
  if ! grep -Fq "$gatt_connection_contract" "$BLE_SERVICE"; then
    printf '%s\n' "GATT connection ownership must keep contract: $gatt_connection_contract" >&2
    exit 1
  fi
done

if grep -Fq "mBluetoothGatt.discoverServices()" "$BLE_SERVICE"; then
  printf '%s\n' "GATT callbacks must discover services through their current callback instance." >&2
  exit 1
fi

if ! grep -Fq "if (bluetoothManager == null)" "$SCAN_ACTIVITY"; then
  printf '%s\n' "Device scan startup must guard missing BluetoothManager service." >&2
  exit 1
fi

for pattern in \
  "if (mBluetoothAdapter != null)" \
  "if (mBluetoothAdapter == null || mHandler == null)" \
  "if (mLeDeviceListAdapter != null)" \
  "if (mLeDeviceListAdapter == null || device == null)" \
  "public void addDevice(BluetoothDevice device)" \
  "if (device == null) {"; do
  if ! grep -Fq "$pattern" "$SCAN_ACTIVITY"; then
    printf '%s\n' "Missing HRM scan lifecycle guard: $pattern" >&2
    exit 1
  fi
done

if ! grep -Fq "finish();" "$SCAN_ACTIVITY" || ! grep -Fq "return;" "$SCAN_ACTIVITY"; then
  printf '%s\n' "Device scan startup failure paths must finish and return." >&2
  exit 1
fi

for pattern in \
  "if (descriptor == null)" \
  "Heart rate notification descriptor is missing." \
  "byte[] descriptorValue = enabled" \
  "BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE" \
  "descriptor.setValue(descriptorValue);" \
  "mBluetoothGatt.writeDescriptor(descriptor);"; do
  if ! grep -Fq "$pattern" "$BLE_SERVICE"; then
    printf '%s\n' "Missing heart-rate notification descriptor guard: $pattern" >&2
    exit 1
  fi
done

for pattern in \
  "private Intent gattUpdateIntent(final String action)" \
  "intent.setPackage(getPackageName());" \
  "final Intent intent = gattUpdateIntent(action);" \
  'Log.d(TAG, "Received heart rate measurement.");'; do
  if ! grep -Fq "$pattern" "$BLE_SERVICE"; then
    printf '%s\n' "Missing HRM broadcast privacy contract: $pattern" >&2
    exit 1
  fi
done

if grep -Fq 'String.format("Received heart rate: %d"' "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate values must not be written to debug logs." >&2
  exit 1
fi

for heart_rate_contract in \
  "Integer flag = characteristic.getIntValue(" \
  "BluetoothGattCharacteristic.FORMAT_UINT8," \
  "if (flag == null)" \
  "Heart rate measurement flags are unavailable." \
  "final Integer heartRate = characteristic.getIntValue(format, 1);" \
  "if (heartRate == null)" \
  "Heart rate measurement value is unavailable."; do
  if ! grep -Fq "$heart_rate_contract" "$BLE_SERVICE"; then
    printf '%s\n' "Missing heart-rate packet guard: $heart_rate_contract" >&2
    exit 1
  fi
done

if grep -Fq "int flag = characteristic.getProperties();" "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate format flags must come from measurement data, not properties." >&2
  exit 1
fi

if grep -Fq "final int heartRate = characteristic.getIntValue" "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate parsing must not unbox a nullable characteristic value." >&2
  exit 1
fi

if grep -Fq "descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);" "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate notification disable path must not write the enable descriptor value." >&2
  exit 1
fi

characteristic_guard_count=$(grep -Fc "characteristic == null" "$BLE_SERVICE")
if [ "$characteristic_guard_count" -lt 3 ]; then
  printf '%s\n' "GATT characteristic read, notify, and broadcast paths must guard null characteristics." >&2
  exit 1
fi

if ! grep -Fq "GATT characteristic is unavailable." "$BLE_SERVICE"; then
  printf '%s\n' "GATT data broadcast path must log a generic missing-characteristic warning." >&2
  exit 1
fi

if ! grep -Fq "BluetoothAdapter not initialized or characteristic unavailable." "$BLE_SERVICE"; then
  printf '%s\n' "GATT operations must log a generic missing-characteristic warning." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/.github/workflows/check.yml" ]; then
  printf '%s\n' "GitHub Actions check workflow is missing." >&2
  exit 1
fi

for workflow_contract in \
  "permissions:" \
  "contents: read" \
  "runs-on: ubuntu-24.04" \
  "cancel-in-progress: true" \
  "timeout-minutes: 5" \
  "workflow_dispatch:" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  'ANDROID_HOME: ""' \
  'ANDROID_SDK_ROOT: ""' \
  "make check"; do
  if ! grep -Fq "$workflow_contract" "$ROOT_DIR/.github/workflows/check.yml"; then
    printf '%s\n' "GitHub Actions workflow must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

for make_contract in \
  'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi

if grep -Fq "inflate(com.garethpaul.app.hrm.R.layout.listitem_device, null)" "$SCAN_ACTIVITY"; then
  printf '%s\n' "Device row inflation must use the parent ViewGroup." >&2
  exit 1
fi

if ! grep -Fq "private final Runnable mStopScanRunnable" "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scan timeout must be cancellable." >&2
  exit 1
fi

if ! grep -Fq "mHandler.removeCallbacks(mStopScanRunnable)" "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scan timeout callbacks must be removed when scanning stops." >&2
  exit 1
fi

if ! grep -Fq "scanLeDevice(false);" "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scan stop paths must use scanLeDevice(false)." >&2
  exit 1
fi

if ! grep -Fq 'android:allowBackup="false"' "$ROOT_DIR/Application/src/main/AndroidManifest.xml"; then
  printf '%s\n' "Application backup behavior must be explicit." >&2
  exit 1
fi

if [ ! -f "$RES_DIR/drawable-nodpi/tile.9.png" ]; then
  printf '%s\n' "Tile background must stay in drawable-nodpi." >&2
  exit 1
fi

if [ -f "$RES_DIR/drawable-hdpi/tile.9.png" ]; then
  printf '%s\n' "Single-density tile background must not be restored." >&2
  exit 1
fi

for file in "$RES_DIR/values/template-dimens.xml" "$RES_DIR/values-sw600dp/template-dimens.xml"; do
  if [ -f "$file" ]; then
    printf '%s\n' "Unused template dimen file must not be restored: $file" >&2
    exit 1
  fi
done

for pattern in "intro_message" "label_data" "label_device_address" "label_state" "title_devices"; do
  if grep -R -Fq "$pattern" "$RES_DIR/values"; then
    printf '%s\n' "Unused template string must not be restored: $pattern" >&2
    exit 1
  fi
done

if grep -R -Eq 'textSize="[0-9]+dp"' "$RES_DIR/layout"; then
  printf '%s\n' "Text sizes must use sp units." >&2
  exit 1
fi

if grep -R -Eq 'android:text="[^@]' "$RES_DIR/layout"; then
  printf '%s\n' "Layout text must use string resources." >&2
  exit 1
fi

for menu in main gatt_services; do
  if ! grep -Fq 'android:title="@string/menu_refresh"' "$RES_DIR/menu/$menu.xml"; then
    printf '%s\n' "Refresh menu item must have a title: $menu.xml" >&2
    exit 1
  fi
done

if ! grep -Fq "LintError" "$ROOT_DIR/Application/lint.xml"; then
  printf '%s\n' "lint.xml must document the obsolete lint API database limitation." >&2
  exit 1
fi

if ! grep -Fq "IconMissingDensityFolder" "$ROOT_DIR/Application/lint.xml"; then
  printf '%s\n' "lint.xml must document the nodpi bitmap asset baseline." >&2
  exit 1
fi

if ! grep -Fq "./gradlew lint --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle lint verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew check --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle check verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew assembleDebug --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle build verification." >&2
  exit 1
fi

if ! grep -Fq "GATT broadcasts are package-scoped" "$README"; then
  printf '%s\n' "README must document package-scoped GATT broadcasts." >&2
  exit 1
fi

if ! grep -Fq "BLE scan lifecycle guards nullable Bluetooth adapters" "$README"; then
  printf '%s\n' "README must document BLE scan lifecycle null guards." >&2
  exit 1
fi

if ! grep -Fq "GATT data-field updates guard missing data views" "$README"; then
  printf '%s\n' "README must document GATT data-field null guards." >&2
  exit 1
fi

if ! grep -Fq "GATT characteristic operations guard missing characteristics" "$README"; then
  printf '%s\n' "README must document GATT characteristic null guards." >&2
  exit 1
fi

if ! grep -Fq "GATT connection callbacks ignore stale instances" "$README"; then
  printf '%s\n' "README must document GATT callback ownership guards." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$README"; then
  printf '%s\n' "README must document the GitHub Actions baseline." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "VISION must document the GitHub Actions baseline." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "SECURITY must document the GitHub Actions baseline." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "CHANGES must record the GitHub Actions baseline." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-hrm-broadcast-privacy.md"; then
  printf '%s\n' "HRM broadcast privacy plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-hrm-scan-lifecycle-guards.md"; then
  printf '%s\n' "HRM scan lifecycle guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-hrm-data-field-guard.md"; then
  printf '%s\n' "HRM data-field guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-hrm-characteristic-null-guards.md"; then
  printf '%s\n' "HRM characteristic null guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-10-hrm-gatt-callback-ownership.md" || \
   ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-10-hrm-gatt-callback-ownership.md"; then
  printf '%s\n' "HRM GATT callback ownership plan must record completed status and make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"; then
  printf '%s\n' "HRM CI baseline plan must be completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"; then
  printf '%s\n' "HRM CI baseline plan must document make check verification." >&2
  exit 1
fi

printf '%s\n' "HRM sample baseline checks passed."
