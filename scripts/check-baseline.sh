#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_FILE="$ROOT_DIR/Application/build.gradle"
CONTROL_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java"
SCAN_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java"
BLE_SERVICE="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java"
MANIFEST="$ROOT_DIR/Application/src/main/AndroidManifest.xml"
README="$ROOT_DIR/README.md"
SECURITY="$ROOT_DIR/SECURITY.md"
RES_DIR="$ROOT_DIR/Application/src/main/res"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
DATA_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hrm-data-callback-ownership.md"
COMPONENT_EXPORT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-component-export-boundary.md"
GATT_SELECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-gatt-selection-guards.md"
NOTIFICATION_REGISTRATION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-notification-registration-guard.md"
DESCRIPTOR_ROLLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-descriptor-write-rollback.md"
DESCRIPTOR_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-descriptor-callback-rollback.md"
REPLACEMENT_GATT_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-replacement-gatt-cleanup.md"
SERVICE_AVAILABILITY_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-service-availability.md"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
HOSTED_ANDROID_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hosted-android-verification.md"
WRAPPER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-gradle-wrapper-verification.md"
GRADLEW="$ROOT_DIR/gradlew"
GRADLEW_BAT="$ROOT_DIR/gradlew.bat"
WRAPPER_JAR="$ROOT_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPERTIES="$ROOT_DIR/gradle/wrapper/gradle-wrapper.properties"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf '%s\n' "A SHA-256 utility is required for wrapper verification." >&2
    exit 1
  fi
}

expected_wrapper_properties() {
  cat <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab
distributionUrl=https\://services.gradle.org/distributions/gradle-2.2.1-all.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
}

expected_ci_workflow() {
  cat <<'EOF'
name: Check

on:
  push:
    branches:
      - master
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false

      - name: Install Android SDK packages
        run: '"${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-22" "build-tools;24.0.3"'

      - name: Set up Java 8
        uses: actions/setup-java@be666c2fcd27ec809703dec50e508c2fdc7f6654 # v5.2.0
        with:
          distribution: corretto
          java-version: "8"

      - name: Run full verification
        run: make check
EOF
}

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
require_contains "aaptOptions {" \
  "HRM module must configure deterministic legacy PNG processing."
require_contains "useNewCruncher false" \
  "HRM module must avoid the nondeterministic queued PNG cruncher."
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

NOTIFICATION_METHOD=$(sed -n \
  '/public void setCharacteristicNotification/,/^    }/p' \
  "$BLE_SERVICE")
NOTIFICATION_COMPACT=$(printf '%s\n' "$NOTIFICATION_METHOD" | tr -d '[:space:]')
NOTIFICATION_BEFORE_REGISTRATION=${NOTIFICATION_COMPACT%%booleannotificationSet=*}
NOTIFICATION_BEFORE_DESCRIPTOR=${NOTIFICATION_COMPACT%%BluetoothGattDescriptordescriptor=*}
NOTIFICATION_BEFORE_VALUE=${NOTIFICATION_COMPACT%%byte[]descriptorValue=*}

for notification_registration_contract in \
  'booleannotificationSet=mBluetoothGatt.setCharacteristicNotification(characteristic,enabled);' \
  'if(!notificationSet){Log.w(TAG,"UnabletosetlocalGATTnotificationstate.");return;}'; do
  if ! printf '%s\n' "$NOTIFICATION_BEFORE_DESCRIPTOR" | \
      grep -Fq "$notification_registration_contract"; then
    printf '%s\n' "GATT notification registration must keep pre-descriptor contract: $notification_registration_contract" >&2
    exit 1
  fi
done

if ! printf '%s\n' "$NOTIFICATION_BEFORE_REGISTRATION" | grep -Fq \
    'booleanheartRateMeasurement=UUID_HEART_RATE_MEASUREMENT.equals(characteristic.getUuid());if(heartRateMeasurement&&mPendingDescriptorWrite!=null){Log.w(TAG,"Heartratenotificationdescriptorwriteisalreadypending.");return;}'; then
  printf '%s\n' "GATT pending descriptor guard must precede local notification mutation." >&2
  exit 1
fi
if [ "$NOTIFICATION_BEFORE_VALUE" = "$NOTIFICATION_COMPACT" ]; then
  printf '%s\n' "GATT pending descriptor guard must precede descriptor value assignment." >&2
  exit 1
fi

if [ "$NOTIFICATION_BEFORE_DESCRIPTOR" = "$NOTIFICATION_COMPACT" ]; then
  printf '%s\n' "GATT notification registration guard must precede descriptor lookup." >&2
  exit 1
fi

ROLLBACK_METHOD=$(sed -n \
  '/private void rollbackCharacteristicNotification/,/^    }/p' \
  "$BLE_SERVICE")
ROLLBACK_COMPACT=$(printf '%s\n' "$ROLLBACK_METHOD" | tr -d '[:space:]')
DESCRIPTOR_CALLBACK=$(sed -n \
  '/public void onDescriptorWrite/,/^        }/p' \
  "$BLE_SERVICE")
DESCRIPTOR_CALLBACK_COMPACT=$(printf '%s\n' "$DESCRIPTOR_CALLBACK" | tr -d '[:space:]')
CLEAR_DESCRIPTOR_METHOD=$(sed -n \
  '/private void clearPendingDescriptorWrite/,/^    }/p' \
  "$BLE_SERVICE")
CLEAR_DESCRIPTOR_COMPACT=$(printf '%s\n' "$CLEAR_DESCRIPTOR_METHOD" | tr -d '[:space:]')
for descriptor_rollback_contract in \
  'if(descriptor==null){Log.w(TAG,"Heartratenotificationdescriptorismissing.");rollbackCharacteristicNotification(characteristic,enabled);return;}' \
  'booleandescriptorValueSet=descriptor.setValue(descriptorValue);if(!descriptorValueSet){Log.w(TAG,"Unabletosetheartratenotificationdescriptorvalue.");rollbackCharacteristicNotification(characteristic,enabled);return;}' \
  'booleandescriptorWriteQueued=mBluetoothGatt.writeDescriptor(descriptor);if(!descriptorWriteQueued){Log.w(TAG,"Unabletoqueueheartratenotificationdescriptorwrite.");clearPendingDescriptorWrite();rollbackCharacteristicNotification(characteristic,enabled);}' ; do
  if ! printf '%s\n' "$NOTIFICATION_COMPACT" | grep -Fq "$descriptor_rollback_contract"; then
    printf '%s\n' "GATT descriptor failure must keep rollback contract: $descriptor_rollback_contract" >&2
    exit 1
  fi
done

for pending_descriptor_contract in \
  'privateBluetoothGattDescriptormPendingDescriptorWrite;' \
  'privateBluetoothGattCharacteristicmPendingNotificationCharacteristic;' \
  'privatebooleanmPendingNotificationEnabled;' \
  'if(heartRateMeasurement&&mPendingDescriptorWrite!=null){Log.w(TAG,"Heartratenotificationdescriptorwriteisalreadypending.");return;}' \
  'mPendingDescriptorWrite=descriptor;mPendingNotificationCharacteristic=characteristic;mPendingNotificationEnabled=enabled;booleandescriptorWriteQueued=mBluetoothGatt.writeDescriptor(descriptor);'; do
  if ! printf '%s\n' "$(tr -d '[:space:]' < "$BLE_SERVICE")" | grep -Fq "$pending_descriptor_contract"; then
    printf '%s\n' "GATT descriptor queue must keep pending-operation contract: $pending_descriptor_contract" >&2
    exit 1
  fi
done

for descriptor_callback_contract in \
  'if(gatt==null||gatt!=mBluetoothGatt){Log.w(TAG,"IgnoringstaleGATTdescriptorcallback.");return;}' \
  'if(descriptor==null||descriptor!=mPendingDescriptorWrite){Log.w(TAG,"IgnoringunrelatedGATTdescriptorcallback.");return;}' \
  'BluetoothGattCharacteristiccharacteristic=mPendingNotificationCharacteristic;booleanenabled=mPendingNotificationEnabled;clearPendingDescriptorWrite();if(status!=BluetoothGatt.GATT_SUCCESS&&characteristic!=null){Log.w(TAG,"Heartratenotificationdescriptorwritefailed.");rollbackCharacteristicNotification(characteristic,enabled);}' ; do
  if ! printf '%s\n' "$DESCRIPTOR_CALLBACK_COMPACT" | grep -Fq "$descriptor_callback_contract"; then
    printf '%s\n' "GATT descriptor callback must keep ownership and rollback contract: $descriptor_callback_contract" >&2
    exit 1
  fi
done

for clear_descriptor_contract in \
  'privatevoidclearPendingDescriptorWrite()' \
  'mPendingDescriptorWrite=null;' \
  'mPendingNotificationCharacteristic=null;' \
  'mPendingNotificationEnabled=false;'; do
  if ! printf '%s\n' "$CLEAR_DESCRIPTOR_COMPACT" | grep -Fq "$clear_descriptor_contract"; then
    printf '%s\n' "GATT descriptor pending-state cleanup must keep contract: $clear_descriptor_contract" >&2
    exit 1
  fi
done
if [ "$(grep -Fc 'clearPendingDescriptorWrite();' "$BLE_SERVICE")" -ne 6 ]; then
  printf '%s\n' "GATT descriptor pending state must clear on completion, queue failure, disconnect, replacement, and close." >&2
  exit 1
fi
for rollback_helper_contract in \
  'privatevoidrollbackCharacteristicNotification(BluetoothGattCharacteristiccharacteristic,booleanenabled)' \
  'booleanrollbackSet=mBluetoothGatt.setCharacteristicNotification(characteristic,!enabled);' \
  'if(!rollbackSet){Log.w(TAG,"UnabletorollbacklocalGATTnotificationstate.");}'; do
  if ! printf '%s\n' "$ROLLBACK_COMPACT" | grep -Fq "$rollback_helper_contract"; then
    printf '%s\n' "GATT descriptor rollback helper must keep contract: $rollback_helper_contract" >&2
    exit 1
  fi
done
for reflected_descriptor_log in \
  '"Unable to set heart rate notification descriptor value." +' \
  '"Unable to queue heart rate notification descriptor write." +' \
  '"Heart rate notification descriptor write failed." +' \
  '"Unable to roll back local GATT notification state." +'; do
  if grep -Fq "$reflected_descriptor_log" "$BLE_SERVICE"; then
    printf '%s\n' "GATT descriptor rollback logs must remain generic." >&2
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

SERVICES_CALLBACK=$(sed -n \
  '/public void onServicesDiscovered/,/public void onCharacteristicRead/p' \
  "$BLE_SERVICE")
READ_CALLBACK=$(sed -n \
  '/public void onCharacteristicRead/,/public void onCharacteristicChanged/p' \
  "$BLE_SERVICE")
NOTIFICATION_CALLBACK=$(sed -n \
  '/public void onCharacteristicChanged/,/    };/p' \
  "$BLE_SERVICE")

check_callback_ownership() {
  callback_body=$1
  callback_log=$2
  callback_name=$3

  if ! printf '%s\n' "$callback_body" | grep -Fq "if (gatt == null || gatt != mBluetoothGatt)" || \
     ! printf '%s\n' "$callback_body" | grep -Fq "$callback_log"; then
    printf '%s\n' "GATT data callback ownership is incomplete for $callback_name." >&2
    exit 1
  fi
}

check_callback_ownership \
  "$SERVICES_CALLBACK" \
  "Ignoring stale GATT services callback." \
  "services"
check_callback_ownership \
  "$READ_CALLBACK" \
  "Ignoring stale GATT read callback." \
  "read"
check_callback_ownership \
  "$NOTIFICATION_CALLBACK" \
  "Ignoring stale GATT notification callback." \
  "notification"

if [ ! -f "$DATA_CALLBACK_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$DATA_CALLBACK_PLAN" || \
   ! grep -Fq "make check" "$DATA_CALLBACK_PLAN"; then
  printf '%s\n' "HRM data callback ownership plan must record completed make check verification." >&2
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

if [ ! -f "$CI_WORKFLOW" ]; then
  printf '%s\n' "GitHub Actions check workflow is missing." >&2
  exit 1
fi

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
if [ "$workflow_paths" != "$CI_WORKFLOW" ]; then
  printf '%s\n' "check.yml must remain the only approved GitHub Actions workflow." >&2
  exit 1
fi

if [ "$(cat "$CI_WORKFLOW")" != "$(expected_ci_workflow)" ]; then
  printf '%s\n' "GitHub Actions check workflow must match the approved full Android security baseline." >&2
  exit 1
fi

if [ ! -f "$CI_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$CI_PLAN" || \
   ! grep -Fq "build-tools 24.0.3" "$CI_PLAN" || \
   ! grep -Fq 'complete `make check` gate' "$CI_PLAN"; then
  printf '%s\n' "HRM CI baseline plan must document the complete hosted Android gate." >&2
  exit 1
fi

if [ ! -f "$HOSTED_ANDROID_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "make check" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "zero lint issues" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq 'pull-request run `27401864615`' "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq '`dbfd8b1a8c2bfd52444c3210f508823c2445453b`' "$HOSTED_ANDROID_PLAN"; then
  printf '%s\n' "Hosted HRM verification plan must record completed local and exact-head hosted evidence." >&2
  exit 1
fi

if ! grep -Fq "canonical GitHub Actions workflow installs Android API 22" "$README" || \
   ! grep -Fq "2026-06-12-hosted-android-verification.md" "$README"; then
  printf '%s\n' "README must document the hosted Android gate and plan." >&2
  exit 1
fi

if [ ! -f "$CODEOWNERS" ] ||
  [ "$(wc -l < "$CODEOWNERS" | tr -d ' ')" -ne 4 ] ||
  ! grep -Fxq '/.github/CODEOWNERS @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/.github/workflows/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Makefile @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/scripts/check-baseline.sh @garethpaul' "$CODEOWNERS"; then
  printf '%s\n' "CODEOWNERS must protect itself, the workflow, Makefile, and baseline checker." >&2
  exit 1
fi

for make_contract in \
  'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_HOME ?=' \
  'ANDROID_SDK_ROOT ?=' \
  'GRADLE ?= $(ROOT)gradlew' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fxq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '$(ROOT)scripts/check-baseline.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "Makefile lint must run the baseline checker from the protected root." >&2
  exit 1
fi
for gradle_contract in \
  'cd $(ROOT) && ANDROID_HOME="$(ANDROID_SDK)" ANDROID_SDK_ROOT="$(ANDROID_SDK)" $(GRADLE) lint --no-daemon; \' \
  'cd $(ROOT) && ANDROID_HOME="$(ANDROID_SDK)" ANDROID_SDK_ROOT="$(ANDROID_SDK)" $(GRADLE) check --no-daemon; \' \
  'cd $(ROOT) && ANDROID_HOME="$(ANDROID_SDK)" ANDROID_SDK_ROOT="$(ANDROID_SDK)" $(GRADLE) assembleDebug --no-daemon; \' ; do
  if [ "$(grep -Fc "$gradle_contract" "$ROOT_DIR/Makefile")" -ne 1 ]; then
    printf '%s\n' "Makefile must keep one complete rooted Gradle contract: $gradle_contract" >&2
    exit 1
  fi
done

if ! grep -Fxq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-14-android-hrm-make-root-override-protection.md"; then
  printf '%s\n' "Android HRM Make root protection plan must record completed status." >&2
  exit 1
fi

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

if ! grep -Fq 'android:allowBackup="false"' "$MANIFEST"; then
  printf '%s\n' "Application backup behavior must be explicit." >&2
  exit 1
fi

if [ "$(grep -Fc 'android:exported=' "$MANIFEST" || true)" -ne 3 ]; then
  printf '%s\n' "HRM manifest must keep exactly three explicit component export boundaries." >&2
  exit 1
fi
manifest_compact=$(tr '\n' ' ' < "$MANIFEST" | tr -s '[:space:]' ' ')
for component_export_contract in \
  '<activity android:name="com.garethpaul.app.hrm.DeviceScanActivity" android:exported="true" android:label="@string/app_name">' \
  '<activity android:name="com.garethpaul.app.hrm.DeviceControlActivity" android:exported="false"/>' \
  '<service android:name="com.garethpaul.app.hrm.BluetoothLeService" android:enabled="true" android:exported="false"/>'; do
  if ! printf '%s\n' "$manifest_compact" | grep -Fq "$component_export_contract"; then
    printf '%s\n' "Missing HRM component export contract: $component_export_contract" >&2
    exit 1
  fi
done
if [ "$(grep -Fc 'android:exported="false"' "$MANIFEST" || true)" -ne 2 ]; then
  printf '%s\n' "Only the launcher activity may be exported." >&2
  exit 1
fi
if [ ! -f "$COMPONENT_EXPORT_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$COMPONENT_EXPORT_PLAN" || \
   ! grep -Fq "make check" "$COMPONENT_EXPORT_PLAN" || \
   ! grep -Fq "hostile mutations" "$COMPONENT_EXPORT_PLAN"; then
  printf '%s\n' "HRM component export plan must record completed verification." >&2
  exit 1
fi
for component_export_doc in "$README" "$SECURITY" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$component_export_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "explicit HRM component export boundary"; then
    printf '%s\n' "$component_export_doc must document the explicit HRM component export boundary." >&2
    exit 1
  fi
done

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

if ! grep -Fq "service, read, and notification callbacks reject stale GATT instances" "$README"; then
  printf '%s\n' "README must document complete GATT data callback ownership guards." >&2
  exit 1
fi

GATT_SELECTION_CALLBACK=$(sed -n \
  '/private final ExpandableListView.OnChildClickListener servicesListClickListner/,/private void clearUI()/p' \
  "$CONTROL_ACTIVITY")
for selection_contract in \
  "mBluetoothLeService == null" \
  "mGattCharacteristics == null" \
  "groupPosition < 0" \
  "groupPosition >= mGattCharacteristics.size()" \
  "ArrayList<BluetoothGattCharacteristic> characteristics" \
  "characteristics == null" \
  "childPosition < 0" \
  "childPosition >= characteristics.size()" \
  "characteristics.get(childPosition)" \
  "if (characteristic == null)"; do
  if ! printf '%s\n' "$GATT_SELECTION_CALLBACK" | grep -Fq "$selection_contract"; then
    printf '%s\n' "GATT child selection must keep guard: $selection_contract" >&2
    exit 1
  fi
done

if printf '%s\n' "$GATT_SELECTION_CALLBACK" | \
    grep -Fq "mGattCharacteristics.get(groupPosition).get(childPosition)"; then
  printf '%s\n' "GATT child selection must not use unchecked nested indexing." >&2
  exit 1
fi

if [ ! -f "$GATT_SELECTION_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$GATT_SELECTION_PLAN" || \
   ! grep -Fq "make check" "$GATT_SELECTION_PLAN" || \
   ! grep -Fq "hostile mutations" "$GATT_SELECTION_PLAN"; then
  printf '%s\n' "HRM GATT selection plan must record completed verification." >&2
  exit 1
fi

for selection_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$selection_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "stale GATT selection"; then
    printf '%s\n' "$selection_doc must document stale GATT selection guards." >&2
    exit 1
  fi
done

if [ ! -f "$NOTIFICATION_REGISTRATION_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$NOTIFICATION_REGISTRATION_PLAN" || \
   ! grep -Fq "## Verification Completed" "$NOTIFICATION_REGISTRATION_PLAN" || \
   ! grep -Fq "make check" "$NOTIFICATION_REGISTRATION_PLAN" || \
   ! grep -Fq "Six focused hostile mutations" "$NOTIFICATION_REGISTRATION_PLAN" || \
   ! grep -Fq "generated-artifact and credential-shaped" "$NOTIFICATION_REGISTRATION_PLAN"; then
  printf '%s\n' "HRM notification registration plan must record completed verification." >&2
  exit 1
fi

for notification_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  normalized_notification_doc=$(tr '\n' ' ' < "$notification_doc" | tr -s '[:space:]' ' ')
  if ! printf '%s\n' "$normalized_notification_doc" | grep -Fiq "notification registration" || \
     ! printf '%s\n' "$normalized_notification_doc" | grep -Fiq "descriptor"; then
    printf '%s\n' "$notification_doc must document notification registration descriptor gating." >&2
    exit 1
  fi
done

if [ ! -f "$DESCRIPTOR_ROLLBACK_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$DESCRIPTOR_ROLLBACK_PLAN" || \
   ! grep -Fq "make check" "$DESCRIPTOR_ROLLBACK_PLAN" || \
   ! grep -Fq "hostile mutations" "$DESCRIPTOR_ROLLBACK_PLAN"; then
  printf '%s\n' "HRM descriptor rollback plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$DESCRIPTOR_CALLBACK_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$DESCRIPTOR_CALLBACK_PLAN" || \
   ! grep -Fq "make check" "$DESCRIPTOR_CALLBACK_PLAN" || \
   ! grep -Fq "focused mutations" "$DESCRIPTOR_CALLBACK_PLAN"; then
  printf '%s\n' "HRM descriptor callback rollback plan must record completed verification." >&2
  exit 1
fi
for callback_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$callback_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "asynchronous descriptor write failures roll back local notification state"; then
    printf '%s\n' "$callback_doc must document asynchronous descriptor callback rollback." >&2
    exit 1
  fi
done
for rollback_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$rollback_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "descriptor-phase failures roll back local notification state"; then
    printf '%s\n' "$rollback_doc must document descriptor rollback consistency." >&2
    exit 1
  fi
done
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

for service_availability_contract in \
  "private boolean mServiceBound = false;" \
  "mServiceBound = bindService(" \
  'Log.e(TAG, "Unable to bind Bluetooth service.");' \
  "private boolean bluetoothServiceAvailable()" \
  'Log.w(TAG, "Bluetooth service is unavailable.");'; do
  if ! grep -Fq "$service_availability_contract" "$CONTROL_ACTIVITY"; then
    printf '%s\n' "HRM service availability must keep contract: $service_availability_contract" >&2
    exit 1
  fi
done

if ! awk '
  /mServiceBound = bindService\(/ { bind = NR; in_bind = 1 }
  in_bind && /if \(!mServiceBound\)/ { bind_guard = NR }
  in_bind && /finish\(\);/ { bind_finish = NR; in_bind = 0 }
  /protected void onDestroy\(\)/ { in_destroy = 1 }
  in_destroy && /if \(mServiceBound\)/ { unbind_guard = NR }
  in_destroy && /unbindService\(mServiceConnection\);/ { unbind = NR }
  in_destroy && /mServiceBound = false;/ { unbind_clear = NR }
  in_destroy && /super\.onDestroy\(\);/ { destroy_super = NR; in_destroy = 0 }
  END {
    exit !(bind && bind_guard && bind_finish && bind < bind_guard && bind_guard < bind_finish &&
      unbind_guard && unbind && unbind_clear && destroy_super &&
      unbind_guard < unbind && unbind < unbind_clear && unbind_clear < destroy_super)
  }
' "$CONTROL_ACTIVITY"; then
  printf '%s\n' "HRM activity must guard rejected binds and unbind only owned service connections." >&2
  exit 1
fi

service_guard_calls=$(grep -Fc "if (!bluetoothServiceAvailable())" "$CONTROL_ACTIVITY" || true)
if [ "$service_guard_calls" -ne 3 ]; then
  printf '%s\n' "HRM discovery, connect, and disconnect paths must all guard service availability." >&2
  exit 1
fi

if ! awk '
  /ACTION_GATT_SERVICES_DISCOVERED\.equals\(action\)/ { in_discovery = 1 }
  in_discovery && /if \(!bluetoothServiceAvailable\(\)\)/ { discovery_guard = NR }
  in_discovery && /displayGattServices\(mBluetoothLeService\.getSupportedGattServices\(\)\);/ {
    discovery_use = NR; in_discovery = 0
  }
  /case com\.garethpaul\.app\.hrm\.R\.id\.menu_connect:/ { in_connect = 1 }
  in_connect && /if \(!bluetoothServiceAvailable\(\)\)/ { connect_guard = NR }
  in_connect && /mBluetoothLeService\.connect\(mDeviceAddress\);/ { connect_use = NR; in_connect = 0 }
  /case com\.garethpaul\.app\.hrm\.R\.id\.menu_disconnect:/ { in_disconnect = 1 }
  in_disconnect && /if \(!bluetoothServiceAvailable\(\)\)/ { disconnect_guard = NR }
  in_disconnect && /mBluetoothLeService\.disconnect\(\);/ { disconnect_use = NR; in_disconnect = 0 }
  END {
    exit !(discovery_guard && discovery_use && discovery_guard < discovery_use &&
      connect_guard && connect_use && connect_guard < connect_use &&
      disconnect_guard && disconnect_use && disconnect_guard < disconnect_use)
  }
' "$CONTROL_ACTIVITY"; then
  printf '%s\n' "HRM service-dependent activity paths must guard before dereferencing the service." >&2
  exit 1
fi

if [ ! -f "$SERVICE_AVAILABILITY_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$SERVICE_AVAILABILITY_PLAN" || \
   ! grep -Fq "## Verification Completed" "$SERVICE_AVAILABILITY_PLAN" || \
   ! grep -Fq "make check" "$SERVICE_AVAILABILITY_PLAN" || \
   ! grep -Fq "hostile mutations" "$SERVICE_AVAILABILITY_PLAN"; then
  printf '%s\n' "HRM service availability plan must record completed verification." >&2
  exit 1
fi

if ! awk '
  /public boolean connect\(final String address\)/ { in_connect = 1 }
  in_connect && /BluetoothGatt previousGatt = mBluetoothGatt;/ { capture = NR }
  in_connect && /BluetoothGatt bluetoothGatt = device\.connectGatt/ { create = NR }
  in_connect && /if \(bluetoothGatt == null\)/ { create_guard = NR }
  in_connect && /clearPendingDescriptorWrite\(\);/ { clear_pending = NR }
  in_connect && /if \(previousGatt != null\)/ { previous_guard = NR }
  in_connect && /previousGatt\.close\(\);/ { previous_close = NR }
  in_connect && /mBluetoothGatt = bluetoothGatt;/ { publish = NR }
  in_connect && capture && /return true;/ {
    completed = 1
    exit !(capture && create && create_guard && clear_pending && previous_guard && previous_close && publish &&
      capture < create && create < create_guard && create_guard < clear_pending &&
      clear_pending < previous_guard && previous_guard < previous_close && previous_close < publish)
  }
  END { if (!completed) exit 1 }
' "$BLE_SERVICE"; then
  printf '%s\n' "Replacement GATT creation must preserve failures and close prior ownership before publication." >&2
  exit 1
fi
if [ "$(grep -Fc 'previousGatt.close();' "$BLE_SERVICE")" -ne 1 ]; then
  printf '%s\n' "Replacement GATT cleanup must close prior ownership exactly once." >&2
  exit 1
fi

if [ ! -f "$REPLACEMENT_GATT_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$REPLACEMENT_GATT_PLAN" || \
   ! grep -Fq "make check" "$REPLACEMENT_GATT_PLAN" || \
   ! grep -Fq "hostile mutations" "$REPLACEMENT_GATT_PLAN"; then
  printf '%s\n' "Replacement GATT cleanup plan must record completed verification." >&2
  exit 1
fi

for replacement_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Replacement GATT connections close the previously owned GATT" "$replacement_doc"; then
    printf '%s\n' "$replacement_doc must document replacement GATT ownership cleanup." >&2
    exit 1
  fi
done

for service_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$service_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "Bluetooth service binding ownership"; then
    printf '%s\n' "$service_doc must document Bluetooth service binding ownership." >&2
    exit 1
  fi
done

if [ ! -x "$GRADLEW" ] || [ ! -f "$GRADLEW_BAT" ] || \
   [ ! -f "$WRAPPER_JAR" ] || [ ! -f "$WRAPPER_PROPERTIES" ]; then
  printf '%s\n' "Generated Gradle wrapper files must be present and gradlew must be executable." >&2
  exit 1
fi

if [ "$(cat "$WRAPPER_PROPERTIES")" != "$(expected_wrapper_properties)" ]; then
  printf '%s\n' "Gradle wrapper properties must retain the reviewed Gradle 2.2.1 URL and checksum." >&2
  exit 1
fi

if [ "$(sha256_file "$WRAPPER_JAR")" != "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172" ]; then
  printf '%s\n' "Gradle wrapper JAR must match Gradle's published 8.14.5 wrapper checksum." >&2
  exit 1
fi

if [ "$(sha256_file "$GRADLEW")" != "b187b4c52e749f5760afdd6fadc31b2a98ad35fb249bf0dff03b72650f320409" ] || \
   [ "$(sha256_file "$GRADLEW_BAT")" != "94102713eb8fb22d032397924c0f38ab2da783ba60d07054339f1190a0c4e2cd" ]; then
  printf '%s\n' "Gradle wrapper launchers must match the reviewed generated scripts." >&2
  exit 1
fi

if ! grep -Fq "Gradle start up script for POSIX generated by Gradle." "$GRADLEW" || \
   ! grep -Fq "Gradle startup script for Windows" "$GRADLEW_BAT"; then
  printf '%s\n' "Gradle wrapper launchers must retain generated provenance markers." >&2
  exit 1
fi

if [ ! -f "$WRAPPER_PLAN" ] || \
   ! grep -Fq "status: completed" "$WRAPPER_PLAN" || \
   ! grep -Fq "fresh temporary Gradle user home" "$WRAPPER_PLAN" || \
   ! grep -Fq "incorrect checksum was rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'SDK-backed `make check` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "external working directory" "$WRAPPER_PLAN" || \
   ! grep -Fq "hostile mutations rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'pull-request `Check` run `27440071367` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq 'CodeQL run `27440069668` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "920a2b26b898e936c1de670b4aee49bb53fbf61c" "$WRAPPER_PLAN"; then
  printf '%s\n' "Gradle wrapper plan must record completed local verification evidence." >&2
  exit 1
fi

if ! grep -Fq "distributionSha256Sum" "$README" || \
   ! grep -Fq "uncached build offline-reproducible" "$README" || \
   ! grep -Fq "wrapper JAR and Gradle distribution checksums" "$SECURITY"; then
  printf '%s\n' "Repository docs must describe wrapper verification and its online boundary." >&2
  exit 1
fi

printf '%s\n' "HRM sample baseline checks passed."
