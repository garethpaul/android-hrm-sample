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

if ! grep -Fq "BluetoothAdapter.checkBluetoothAddress(address)" "$BLE_SERVICE"; then
  printf '%s\n' "BLE connection must validate device addresses before getRemoteDevice." >&2
  exit 1
fi

if ! grep -Fq "if (bluetoothManager == null)" "$SCAN_ACTIVITY"; then
  printf '%s\n' "Device scan startup must guard missing BluetoothManager service." >&2
  exit 1
fi

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

if grep -Fq "descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);" "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate notification disable path must not write the enable descriptor value." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
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

printf '%s\n' "HRM sample baseline checks passed."
