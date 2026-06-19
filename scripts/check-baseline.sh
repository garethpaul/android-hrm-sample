#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_FILE="$ROOT_DIR/Application/build.gradle"
CONTROL_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java"
SCAN_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java"
BLE_SERVICE="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java"
README="$ROOT_DIR/README.md"
SECURITY="$ROOT_DIR/SECURITY.md"
RES_DIR="$ROOT_DIR/Application/src/main/res"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
DATA_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hrm-data-callback-ownership.md"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
HOSTED_ANDROID_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hosted-android-verification.md"
WRAPPER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-gradle-wrapper-verification.md"
GRADLEW="$ROOT_DIR/gradlew"
GRADLEW_BAT="$ROOT_DIR/gradlew.bat"
WRAPPER_JAR="$ROOT_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPERTIES="$ROOT_DIR/gradle/wrapper/gradle-wrapper.properties"
MAKEFILE="$ROOT_DIR/Makefile"
ANDROID_RUNNER="$ROOT_DIR/scripts/run-android-verification.sh"
PUBLICATION_GATE_TESTS="$ROOT_DIR/scripts/test-publication-gate.sh"
ARCHIVE_VERIFIER="$ROOT_DIR/scripts/verify-archive-tree.py"
ROOT_BUILD_FILE="$ROOT_DIR/build.gradle"
SETTINGS_FILE="$ROOT_DIR/settings.gradle"
LINT_CONFIG="$ROOT_DIR/Application/lint.xml"

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
          ref: ${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}

      - name: Install Android SDK packages
        run: '"${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-22" "build-tools;24.0.3"'

      - name: Set up Java 8
        uses: actions/setup-java@be666c2fcd27ec809703dec50e508c2fdc7f6654 # v5.2.0
        with:
          distribution: corretto
          java-version: "8"

      - name: Run authenticated Android verification
        env:
          EXPECTED_COMMIT: ${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}
        run: ./scripts/run-android-verification.sh

      - name: Test publication-gate integrity
        run: ./scripts/test-publication-gate.sh
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
  printf '%s\n' "GitHub Actions check workflow must match the reviewed hosted Android verification workflow." >&2
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
   ! grep -Fq "2026-06-12-hosted-android-verification.md" "$README" || \
   ! grep -Fq "The pinned GitHub Actions \`Check\` workflow is the only supported authenticated" "$README" || \
   ! grep -Fq "external CI trust assumptions" "$README" || \
   ! grep -Fq "does not independently authenticate JDK bytes" "$README" || \
   grep -Fq 'runs full `make check`' "$README"; then
  printf '%s\n' "README must document the hosted Android gate and plan." >&2
  exit 1
fi

if ! grep -Fq "The pinned GitHub Actions \`Check\` workflow is the only supported authenticated" "$SECURITY" || \
   ! grep -Fq "external CI trust assumptions" "$SECURITY" || \
   ! grep -Fq "does not independently authenticate JDK bytes" "$SECURITY" || \
   grep -Fq 'runs the root `make check` baseline' "$SECURITY"; then
  printf '%s\n' "Security guidance must bound authenticated evidence to the exact runner." >&2
  exit 1
fi

if [ ! -f "$CODEOWNERS" ] ||
  [ "$(wc -l < "$CODEOWNERS" | tr -d ' ')" -ne 11 ] ||
  ! grep -Fxq '/.github/CODEOWNERS @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/.github/workflows/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Makefile @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/build.gradle @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/settings.gradle @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Application/build.gradle @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Application/lint.xml @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/gradlew @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/gradlew.bat @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/gradle/wrapper/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/scripts/ @garethpaul' "$CODEOWNERS"; then
  printf '%s\n' "CODEOWNERS must cover every publication-gate trust root." >&2
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

if ! grep -Fq "service, read, and notification callbacks reject stale GATT instances" "$README"; then
  printf '%s\n' "README must document complete GATT data callback ownership guards." >&2
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

if [ ! -x "$GRADLEW" ] || [ ! -f "$GRADLEW_BAT" ] || \
   [ ! -f "$WRAPPER_JAR" ] || [ ! -f "$WRAPPER_PROPERTIES" ]; then
  printf '%s\n' "Generated Gradle wrapper files must be present and gradlew must be executable." >&2
  exit 1
fi

if [ -n "$(find "$ROOT_DIR" -maxdepth 1 \( -name GNUmakefile -o -name makefile \) -print -quit)" ]; then
  printf '%s\n' "Alternate root makefiles must not shadow the reviewed Makefile." >&2
  exit 1
fi

if [ ! -f "$MAKEFILE" ] || [ -L "$MAKEFILE" ] || \
   [ "$(sha256_file "$MAKEFILE")" != "e5c1d9f6c72ea2fa6d38132c159a298173f9640b75744adc15b75a5913d2181b" ]; then
  printf '%s\n' "Makefile must retain the reviewed non-substitutable verification entry point." >&2
  exit 1
fi

if [ ! -f "$BUILD_FILE" ] || [ -L "$BUILD_FILE" ] || \
   [ "$(sha256_file "$BUILD_FILE")" != "5f87bcb825b5937e291428f4816f20d0f5b7b3db66e819e03a3d3c2a6f599cd8" ]; then
  printf '%s\n' "Application Gradle build definition must retain the reviewed Android plugin tasks." >&2
  exit 1
fi

if [ ! -f "$ROOT_BUILD_FILE" ] || [ -L "$ROOT_BUILD_FILE" ] || \
   [ "$(sha256_file "$ROOT_BUILD_FILE")" != "5c210454b1facc1e317a759f6059324f793841eb23d1f549179b64d1584c55f8" ]; then
  printf '%s\n' "Root Gradle build definition must retain the reviewed project contract." >&2
  exit 1
fi

if [ ! -f "$SETTINGS_FILE" ] || [ -L "$SETTINGS_FILE" ] || \
   [ "$(sha256_file "$SETTINGS_FILE")" != "85fa9044216c228a55fee5e669990ec71fa2e3a7c9b3944927698037ee304688" ]; then
  printf '%s\n' "Gradle settings must retain the reviewed Application project inclusion." >&2
  exit 1
fi

if [ ! -f "$LINT_CONFIG" ] || [ -L "$LINT_CONFIG" ] || \
   [ "$(sha256_file "$LINT_CONFIG")" != "5ad8971f6154196884e37ecde3183adce5c075a29f9fdfee300deefbe183661e" ]; then
  printf '%s\n' "Android lint configuration must retain the reviewed gate contract." >&2
  exit 1
fi

for unreviewed_gradle_entry in \
  "$ROOT_DIR/gradle.properties" \
  "$ROOT_DIR/local.properties" \
  "$ROOT_DIR/init.gradle" \
  "$ROOT_DIR/init.d" \
  "$ROOT_DIR/buildSrc"; do
  if [ -e "$unreviewed_gradle_entry" ]; then
    printf '%s\n' "Unreviewed Gradle configuration entry points are not allowed." >&2
    exit 1
  fi
done

if [ ! -x "$ANDROID_RUNNER" ] || [ -L "$ANDROID_RUNNER" ] || \
   [ "$(sha256_file "$ANDROID_RUNNER")" != "615d8eedd2de6aeabc852fa61d8235bb6bd09d74f7e71baa7e9025a1ebbd51fc" ]; then
  printf '%s\n' "Android verification must retain the reviewed exact wrapper and SDK runner." >&2
  exit 1
fi

if [ ! -x "$PUBLICATION_GATE_TESTS" ] || [ -L "$PUBLICATION_GATE_TESTS" ] || \
   [ "$(sha256_file "$PUBLICATION_GATE_TESTS")" != "1e45d20af8257b3db63d24d2cd171adf38ef6ba076f5342d335ef05455694730" ]; then
  printf '%s\n' "Publication-gate mutation tests must retain the reviewed contract." >&2
  exit 1
fi

if [ ! -x "$ARCHIVE_VERIFIER" ] || [ -L "$ARCHIVE_VERIFIER" ] || \
   [ "$(sha256_file "$ARCHIVE_VERIFIER")" != "ed6387131b2d82056f92539ed5481f177c0739f9aded434c9fa594198c739076" ]; then
  printf '%s\n' "Archive manifest verifier must be present and executable." >&2
  exit 1
fi

if ! grep -Fxq 'APPROVED_RUNNER_SHA256=615d8eedd2de6aeabc852fa61d8235bb6bd09d74f7e71baa7e9025a1ebbd51fc' "$PUBLICATION_GATE_TESTS"; then
  printf '%s\n' "Publication-gate tests must independently pin the reviewed Android runner." >&2
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
