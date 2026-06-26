#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_FILE="$ROOT_DIR/Application/build.gradle"
CONTROL_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceControlActivity.java"
SCAN_ACTIVITY="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/DeviceScanActivity.java"
BLE_SERVICE="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/BluetoothLeService.java"
HEART_RATE_MEASUREMENT="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurement.java"
HEART_RATE_PARSER="$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java"
HEART_RATE_PARSER_TEST="$ROOT_DIR/scripts/tests/HeartRateMeasurementParserTest.java"
HEART_RATE_PARSER_RUNNER="$ROOT_DIR/scripts/test-heart-rate-parser.sh"
MANIFEST="$ROOT_DIR/Application/src/main/AndroidManifest.xml"
README="$ROOT_DIR/README.md"
SECURITY="$ROOT_DIR/SECURITY.md"
RES_DIR="$ROOT_DIR/Application/src/main/res"
STRINGS="$RES_DIR/values/strings.xml"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
DATA_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hrm-data-callback-ownership.md"
COMPONENT_EXPORT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-component-export-boundary.md"
GATT_SELECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-gatt-selection-guards.md"
NOTIFICATION_REGISTRATION_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-notification-registration-guard.md"
DESCRIPTOR_ROLLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-descriptor-write-rollback.md"
DESCRIPTOR_CALLBACK_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-descriptor-callback-rollback.md"
REPLACEMENT_GATT_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-replacement-gatt-cleanup.md"
DEVICE_VERIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-device-verification-checklist.md"
LOCAL_BROADCAST_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-local-broadcast-boundary.md"
INITIALIZE_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-14-hrm-initialize-failure-return.md"
DISCOVERY_START_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-15-hrm-service-discovery-start-failure.md"
DISCOVERY_CALLBACK_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-15-hrm-service-discovery-callback-failure.md"
SCAN_START_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-15-hrm-scan-start-failure.md"
DEFER_SCAN_ENABLE_PLAN="$ROOT_DIR/docs/plans/2026-06-15-hrm-defer-scan-until-bluetooth-enabled.md"
SCAN_LIST_SELECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-17-hrm-scan-list-selection-guards.md"
SERVICE_AVAILABILITY_PLAN="$ROOT_DIR/docs/plans/2026-06-13-hrm-service-availability.md"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
HOSTED_ANDROID_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hosted-android-verification.md"
WRAPPER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-gradle-wrapper-verification.md"
HEART_RATE_PARSER_PLAN="$ROOT_DIR/docs/plans/2026-06-26-explicit-heart-rate-parser.md"
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

for required_path in \
  "$ROOT_DIR/DEVICE_VERIFICATION.md" \
  "$HEART_RATE_MEASUREMENT" \
  "$HEART_RATE_PARSER" \
  "$HEART_RATE_PARSER_TEST" \
  "$HEART_RATE_PARSER_RUNNER" \
  "$HEART_RATE_PARSER_PLAN" \
  "$DEVICE_VERIFICATION_PLAN" \
  "$LOCAL_BROADCAST_PLAN" \
  "$INITIALIZE_FAILURE_PLAN" \
  "$DISCOVERY_START_FAILURE_PLAN" \
  "$DISCOVERY_CALLBACK_FAILURE_PLAN" \
  "$SCAN_START_FAILURE_PLAN" \
  "$DEFER_SCAN_ENABLE_PLAN"; do
  if [ ! -f "$required_path" ]; then
    printf '%s\n' "Required file is missing: ${required_path#"$ROOT_DIR/"}" >&2
    exit 1
  fi
done

for deferred_scan_contract in \
  'bluetoothEnabled = mBluetoothAdapter.isEnabled();' \
  'if (!bluetoothEnabled) {' \
  'Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);' \
  'startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);'; do
  if ! grep -Fq "$deferred_scan_contract" "$SCAN_ACTIVITY"; then
    printf '%s\n' "BLE enable flow must keep contract: $deferred_scan_contract" >&2
    exit 1
  fi
done

disabled_check_count=$(awk '
  /protected void onResume\(\)/ { in_resume = 1 }
  in_resume && /protected void onActivityResult/ { in_resume = 0 }
  in_resume && /if \(!bluetoothEnabled\)/ { count++ }
  END { print count + 0 }
' "$SCAN_ACTIVITY")
if [ "$disabled_check_count" -ne 1 ]; then
  printf '%s\n' "BLE enable flow must use one disabled-adapter condition." >&2
  exit 1
fi

if ! awk '
  /protected void onResume\(\)/ { in_resume = 1 }
  in_resume && /if \(!bluetoothEnabled\)/ { disabled = NR }
  in_resume && /startActivityForResult\(enableBtIntent, REQUEST_ENABLE_BT\);/ { request = NR }
  in_resume && request && /return;/ && !early_return { early_return = NR }
  in_resume && /mLeDeviceListAdapter = new LeDeviceListAdapter\(\);/ { adapter = NR }
  in_resume && /scanLeDevice\(true\);/ {
    scan = NR
    checked = 1
    exit !(disabled && request && early_return && adapter &&
      disabled < request && request < early_return && early_return < adapter && adapter < scan)
  }
  in_resume && /protected void onActivityResult/ { exit 1 }
  END { if (!checked) exit 1 }
' "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scanning must wait until the enable-Bluetooth flow has returned." >&2
  exit 1
fi

if ! awk '
  /protected void onActivityResult/ { in_result = 1 }
  in_result && /requestCode == REQUEST_ENABLE_BT/ { request = NR }
  in_result && /resultCode == Activity\.RESULT_CANCELED/ { canceled = NR }
  in_result && /finish\(\);/ { finish = NR }
  in_result && /return;/ {
    checked = 1
    exit !(request && canceled && finish && request <= canceled && canceled < finish && finish < NR)
  }
  in_result && /protected void onPause/ { exit 1 }
  END { if (!checked) exit 1 }
' "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE enable cancellation must still finish the activity." >&2
  exit 1
fi

deferred_scan_guidance='BLE scanning must wait until the enable-Bluetooth system flow returns with an enabled adapter.'
for deferred_scan_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "$deferred_scan_guidance" "$deferred_scan_document"; then
    printf '%s\n' "$deferred_scan_document must document deferred BLE scan startup." >&2
    exit 1
  fi
done

for deferred_scan_plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No emulator, physical Android device, or live BLE peripheral was exercised'; do
  if ! grep -Fqi "$deferred_scan_plan_contract" "$DEFER_SCAN_ENABLE_PLAN"; then
    printf '%s\n' "Deferred BLE scan plan must preserve completion evidence: $deferred_scan_plan_contract" >&2
    exit 1
  fi
done

for scan_start_contract in \
  "scanStarted = mBluetoothAdapter.startLeScan(scanCallback);" \
  "if (scanStarted) {" \
  "Toast.makeText(this, com.garethpaul.app.hrm.R.string.scan_start_failed"; do
  if ! grep -Fq "$scan_start_contract" "$SCAN_ACTIVITY"; then
    printf '%s\n' "BLE scan startup must keep result handling: $scan_start_contract" >&2
    exit 1
  fi
done

if ! awk '
  /private void scanLeDevice\(final boolean enable\)/ { in_scan = 1 }
  in_scan && /scanStarted = mBluetoothAdapter\.startLeScan/ { start_call = NR }
  in_scan && /if \(scanStarted\)/ { success_branch = NR }
  in_scan && /mScanning = true;/ { scanning = NR }
  in_scan && /mHandler\.postDelayed\(mStopScanRunnable, SCAN_PERIOD\);/ { timeout = NR }
  in_scan && /} else {/ && success_branch && !failure_branch { failure_branch = NR }
  in_scan && failure_branch && /mScanning = false;/ && !idle { idle = NR }
  in_scan && failure_branch && /R\.string\.scan_start_failed/ { failure_message = NR }
  in_scan && /invalidateOptionsMenu\(\);/ {
    exit !(start_call && success_branch && scanning && timeout && failure_branch &&
      idle && failure_message && start_call < success_branch &&
      success_branch < scanning && scanning < timeout && timeout < failure_branch &&
      failure_branch < idle && idle < failure_message)
  }
' "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scan state and timeout must follow the platform start result." >&2
  exit 1
fi

if ! grep -Fq '<string name="scan_start_failed">Unable to start Bluetooth scan.</string>' "$STRINGS"; then
  printf '%s\n' "BLE scan startup failure string is missing." >&2
  exit 1
fi

scan_start_guidance='BLE scans must enter the scanning state and schedule timeout cleanup only after Android reports that scan startup succeeded.'
for scan_start_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "$scan_start_guidance" "$scan_start_document"; then
    printf '%s\n' "$scan_start_document must document BLE scan start result handling." >&2
    exit 1
  fi
done

for scan_start_plan_contract in \
  "Status: Completed" \
  "make check" \
  "hostile mutations" \
  "No physical BLE peripheral or forced platform scan-start failure was exercised"; do
  if ! grep -Fqi "$scan_start_plan_contract" "$SCAN_START_FAILURE_PLAN"; then
    printf '%s\n' "HRM scan start failure plan must preserve completion evidence: $scan_start_plan_contract" >&2
    exit 1
  fi
done

if ! awk '
  /public void onServiceConnected\(ComponentName componentName, IBinder service\)/ { in_callback = 1 }
  in_callback && /if \(!mBluetoothLeService\.initialize\(\)\)/ { failure = NR }
  in_callback && /finish\(\);/ { finish = NR }
  in_callback && finish && /return;/ { failure_return = NR }
  in_callback && /mBluetoothLeService\.connect\(mDeviceAddress\);/ {
    connect = NR
    done = 1
    exit !(failure && finish && failure_return &&
      failure < finish && finish < failure_return && failure_return < connect)
  }
  END {
    if (!done) exit 1
  }
' "$CONTROL_ACTIVITY"; then
  printf '%s\n' "Failed Bluetooth initialization must return before GATT connection." >&2
  exit 1
fi

for initialize_failure_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "failed Bluetooth initialization" "$initialize_failure_document"; then
    printf '%s\n' "$initialize_failure_document must document failed initialization termination." >&2
    exit 1
  fi
done

for initialize_failure_plan_contract in "Status: Completed" "make check" "mutations"; do
  if ! grep -Fqi "$initialize_failure_plan_contract" "$INITIALIZE_FAILURE_PLAN"; then
    printf '%s\n' "HRM initialization failure plan must preserve completion evidence: $initialize_failure_plan_contract" >&2
    exit 1
  fi
done

for device_contract in \
  'commit SHA and pull request' \
  'Scan timeout' \
  'Replacement sensor' \
  'Local registration failure' \
  'Descriptor callback failure' \
  'Rapid disconnect/reconnect' \
  'Do not convert `not run` into passing evidence.' \
  'Bluetooth addresses, names, advertising' \
  'every BLE device and heart-rate row as' \
  'unexecuted'; do
  if ! grep -Fq "$device_contract" "$ROOT_DIR/DEVICE_VERIFICATION.md"; then
    printf '%s\n' "HRM device checklist must keep contract: $device_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'DEVICE_VERIFICATION.md' "$README" || \
   ! grep -Fq 'explicit unexecuted rows' "$README" || \
   ! grep -Fqi 'HRM device verification matrix' "$ROOT_DIR/VISION.md" || \
   ! grep -Fq 'every runtime row explicitly unexecuted' "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' 'Repository guidance must document the unexecuted HRM device matrix.' >&2
  exit 1
fi

for plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No Android SDK, emulator, phone, BLE sensor, or live GATT scenario was executed'; do
  if ! grep -Fq "$plan_contract" "$DEVICE_VERIFICATION_PLAN"; then
    printf '%s\n' "HRM device plan must keep completion evidence: $plan_contract" >&2
    exit 1
  fi
done

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

      - name: Run BLE session guard tests
        run: ./scripts/test-ble-session-guards.sh

      - name: Run BLE hostile mutation tests
        run: ./scripts/test-ble-mutations.sh

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

scan_selection_guidance="BLE scan-list selections reject unavailable adapters and out-of-range positions before device lookup."
for scan_selection_doc in \
  "$ROOT_DIR/AGENTS.md" \
  "$README" \
  "$SECURITY" \
  "$ROOT_DIR/VISION.md" \
  "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "$scan_selection_guidance" "$scan_selection_doc"; then
    printf '%s\n' "$scan_selection_doc must document BLE scan list selection guards." >&2
    exit 1
  fi
done

if [ ! -f "$SCAN_LIST_SELECTION_PLAN" ] || \
   ! grep -Fq "title: HRM Scan List Selection Guards" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "type: fix" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "date: 2026-06-17" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "R1. A list-selection callback must return" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "Repository and external-directory Android gates" "$SCAN_LIST_SELECTION_PLAN"; then
  printf '%s\n' "HRM scan list selection plan must keep metadata, requirements, and verification scope." >&2
  exit 1
fi

if ! grep -Fxq "status: completed" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "## Completed Verification" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq 'Repository and external-directory `make check` passed' "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "Focused hostile mutations rejected" "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq 'PR #18 was open, clean, mergeable, and terminal-green' "$SCAN_LIST_SELECTION_PLAN" || \
   ! grep -Fq "ea86bcbf2a55848b6e8f9f984a4a22a37089624d" "$SCAN_LIST_SELECTION_PLAN"; then
  printf '%s\n' "HRM scan list selection plan must record completed status and verification." >&2
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

python3 "$ROOT_DIR/scripts/test-ble-source-contracts.py"
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
  "if (!mGattOwner.isCurrent(gatt))" \
  "if (status != BluetoothGatt.GATT_SUCCESS)" \
  "gattToClose = mGattOwner.releaseIfCurrent(gatt);" \
  "gattToClose.close();" \
  "gatt.discoverServices()" \
  "BluetoothGatt bluetoothGatt = device.connectGatt(this, false, mGattCallback);" \
  "if (bluetoothGatt == null)"; do
  if ! grep -Fq "$gatt_connection_contract" "$BLE_SERVICE"; then
    printf '%s\n' "GATT connection ownership must keep contract: $gatt_connection_contract" >&2
    exit 1
  fi
done

if grep -Fq "mBluetoothGatt" "$BLE_SERVICE"; then
  printf '%s\n' "GATT ownership must not bypass the exact-owner guard." >&2
  exit 1
fi

for discovery_failure_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$discovery_failure_document" | tr -s '[:space:]' ' ' | \
      grep -Fiq "GATT service discovery start"; then
    printf '%s\n' "$discovery_failure_document must document rejected GATT discovery startup." >&2
    exit 1
  fi
done

for discovery_failure_plan_contract in \
  "Status: Completed" \
  "make check" \
  "hostile mutations" \
  "No physical BLE peripheral"; do
  if ! grep -Fqi "$discovery_failure_plan_contract" "$DISCOVERY_START_FAILURE_PLAN"; then
    printf '%s\n' "Discovery-start failure plan must record completion evidence: $discovery_failure_plan_contract" >&2
    exit 1
  fi
done

for discovery_callback_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$discovery_callback_document" | tr -s '[:space:]' ' ' | \
      grep -Fiq "failed GATT service discovery callback"; then
    printf '%s\n' "$discovery_callback_document must document failed GATT discovery callbacks." >&2
    exit 1
  fi
done

for discovery_callback_plan_contract in \
  "Status: Completed" \
  "make check" \
  "Eleven hostile mutations" \
  "No physical BLE peripheral"; do
  if ! grep -Fqi "$discovery_callback_plan_contract" "$DISCOVERY_CALLBACK_FAILURE_PLAN"; then
    printf '%s\n' "Discovery-callback failure plan must record completion evidence: $discovery_callback_plan_contract" >&2
    exit 1
  fi
done

for callback_log in \
  "Ignoring stale GATT services callback." \
  "Ignoring stale GATT read callback." \
  "Ignoring stale GATT notification callback." \
  "Ignoring stale GATT descriptor callback."; do
  if ! grep -Fq "$callback_log" "$BLE_SERVICE"; then
    printf '%s\n' "GATT callback ownership log is missing: $callback_log" >&2
    exit 1
  fi
done

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
  "if (mBluetoothAdapter == null || mHandler == null)" \
  "if (mLeDeviceListAdapter != null)" \
  "mScanGeneration.isCurrent(generation)" \
  "mLeDeviceListAdapter == null || device == null" \
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

SCAN_LIST_CLICK=$(sed -n \
  '/protected void onListItemClick/,/private void scanLeDevice/p' \
  "$SCAN_ACTIVITY")
for scan_selection_contract in \
  "if (mLeDeviceListAdapter == null)" \
  "mLeDeviceListAdapter.getDevice(position)" \
  "if (device == null || !(v.getTag() instanceof ViewHolder)) return;" \
  "deviceAddress.equals(viewHolder.boundDeviceAddress)"; do
  if ! printf '%s\n' "$SCAN_LIST_CLICK" | grep -Fq "$scan_selection_contract"; then
    printf '%s\n' "BLE scan list selection must keep callback guard: $scan_selection_contract" >&2
    exit 1
  fi
done

SCAN_DEVICE_LOOKUP=$(sed -n \
  '/public BluetoothDevice getDevice(int position)/,/^        }/p' \
  "$SCAN_ACTIVITY")
for scan_lookup_contract in \
  "position < 0" \
  "position >= mLeDevices.size()" \
  "return null;" \
  "return mLeDevices.get(position);"; do
  if ! printf '%s\n' "$SCAN_DEVICE_LOOKUP" | grep -Fq "$scan_lookup_contract"; then
    printf '%s\n' "BLE scan device lookup must keep bounds contract: $scan_lookup_contract" >&2
    exit 1
  fi
done

if ! awk '
  /protected void onListItemClick/ { in_click = 1 }
  in_click && /if \(mLeDeviceListAdapter == null\)/ { adapter_guard = NR }
  in_click && /mLeDeviceListAdapter\.getDevice\(position\)/ { lookup = NR; in_click = 0 }
  /public BluetoothDevice getDevice\(int position\)/ { in_lookup = 1 }
  in_lookup && /position < 0/ { lower_guard = NR }
  in_lookup && /position >= mLeDevices\.size\(\)/ { upper_guard = NR }
  in_lookup && /return mLeDevices\.get\(position\);/ { device_get = NR; in_lookup = 0 }
  END {
    exit !(adapter_guard && lookup && adapter_guard < lookup &&
      lower_guard && upper_guard && device_get &&
      lower_guard < device_get && upper_guard < device_get)
  }
' "$SCAN_ACTIVITY"; then
  printf '%s\n' "BLE scan list guards must run before adapter and device-list access." >&2
  exit 1
fi

for pattern in \
  "if (descriptor == null)" \
  "Heart rate notification descriptor is missing." \
  "byte[] descriptorValue = enabled" \
  "BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE" \
  "descriptor.setValue(descriptorValue);" \
  "currentGatt.writeDescriptor(descriptor);"; do
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
  "HeartRateMeasurementParser.parse(characteristic.getValue())" \
  "if (measurement == null)" \
  "Heart rate measurement packet is unavailable." \
  "String.valueOf(measurement.beatsPerMinute())"; do
  if ! grep -Fq "$heart_rate_contract" "$BLE_SERVICE"; then
    printf '%s\n' "Missing heart-rate packet guard: $heart_rate_contract" >&2
    exit 1
  fi
done

if grep -Fq "characteristic.getIntValue(" "$BLE_SERVICE"; then
  printf '%s\n' "Heart-rate parsing must use the dependency-free packet parser." >&2
  exit 1
fi

for parser_contract in \
  "private static final int RESERVED_FLAGS = 0xe0;" \
  "(flags & RESERVED_FLAGS) != 0" \
  "(flags & SENSOR_CONTACT_SUPPORTED) == 0" \
  "unsignedLittleEndian16(packet, offset)" \
  "(flags & ENERGY_EXPENDED_PRESENT) != 0" \
  "(flags & RR_INTERVAL_PRESENT) != 0" \
  "remainingBytes < 2 || remainingBytes % 2 != 0" \
  "if (offset != packet.length)"; do
  if ! grep -Fq "$parser_contract" "$HEART_RATE_PARSER"; then
    printf '%s\n' "Missing complete heart-rate parser contract: $parser_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc "rrIntervals.clone()" "$HEART_RATE_MEASUREMENT")" -ne 2 ]; then
  printf '%s\n' "Heart-rate RR intervals must remain immutable at both object boundaries." >&2
  exit 1
fi

if ! grep -Fq 'javac -source 7 -target 7' "$HEART_RATE_PARSER_RUNNER" || \
   ! grep -Fq 'HeartRateMeasurementParser tests passed:' "$HEART_RATE_PARSER_TEST"; then
  printf '%s\n' "The Java 7 heart-rate parser suite must remain executable." >&2
  exit 1
fi

for parser_document in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$parser_document" | tr -s '[:space:]' ' ' | \
      grep -Fiq "dependency-free"; then
    printf '%s\n' "$parser_document must document the dependency-free heart-rate parser." >&2
    exit 1
  fi
done

if grep -Fq "Add explicit heart-rate-service parsing" "$ROOT_DIR/VISION.md" || \
   ! grep -Fq "Add tests around activity/service interaction" "$ROOT_DIR/VISION.md"; then
  printf '%s\n' "VISION must retire complete packet parsing and retain interaction testing." >&2
  exit 1
fi

for parser_plan_contract in \
  "Status: Completed" \
  "32 assertions" \
  "Nineteen total BLE hostile mutations" \
  "every applicable row in \`DEVICE_VERIFICATION.md\` remains \`not run\`"; do
  if ! grep -Fq "$parser_plan_contract" "$HEART_RATE_PARSER_PLAN"; then
    printf '%s\n' "Heart-rate parser plan must preserve completion evidence: $parser_plan_contract" >&2
    exit 1
  fi
done

for device_parser_row in \
  "Valid contact, energy, and RR fields" \
  "Reserved or inconsistent flags" \
  "Missing, odd, or trailing optional bytes"; do
  if ! grep -F "$device_parser_row" "$ROOT_DIR/DEVICE_VERIFICATION.md" | grep -Fq "not run"; then
    printf '%s\n' "Device matrix must keep parser hardware evidence unexecuted: $device_parser_row" >&2
    exit 1
  fi
done

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

for replacement_contract in \
  'previousGatt = mGattOwner.replace(bluetoothGatt);' \
  'if (previousGatt != null)' \
  'previousGatt.close();'; do
  if ! grep -Fq "$replacement_contract" "$BLE_SERVICE"; then
    printf '%s\n' "Replacement GATT ownership contract is missing: $replacement_contract" >&2
    exit 1
  fi
done
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

for local_broadcast_contract in \
  'import android.support.v4.content.LocalBroadcastManager;' \
  'private void sendGattBroadcast(final Intent intent)' \
  'LocalBroadcastManager.getInstance(this).sendBroadcast(intent);'; do
  if ! grep -Fq "$local_broadcast_contract" "$BLE_SERVICE"; then
    printf '%s\n' "BLE service must keep local broadcast contract: $local_broadcast_contract" >&2
    exit 1
  fi
done
for local_receiver_contract in \
  'import android.support.v4.content.LocalBroadcastManager;' \
  'LocalBroadcastManager.getInstance(this).registerReceiver(' \
  'LocalBroadcastManager.getInstance(this).unregisterReceiver(mGattUpdateReceiver);'; do
  if ! grep -Fq "$local_receiver_contract" "$CONTROL_ACTIVITY"; then
    printf '%s\n' "Control activity must keep local receiver contract: $local_receiver_contract" >&2
    exit 1
  fi
done
if grep -Fq '        sendBroadcast(intent);' "$BLE_SERVICE" || \
   grep -Fq '        registerReceiver(mGattUpdateReceiver' "$CONTROL_ACTIVITY" || \
   grep -Fq '        unregisterReceiver(mGattUpdateReceiver);' "$CONTROL_ACTIVITY"; then
  printf '%s\n' "GATT events must not use framework broadcast publication or subscription." >&2
  exit 1
fi
if [ "$(grep -Fc 'sendGattBroadcast(intent);' "$BLE_SERVICE")" -ne 4 ]; then
  printf '%s\n' "Every GATT event publication path must use the local broadcast helper." >&2
  exit 1
fi
for local_broadcast_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$local_broadcast_doc" | tr -s '[:space:]' ' ' | \
      grep -Fqi 'in-process local broadcast'; then
    printf '%s\n' "$local_broadcast_doc must document the in-process local broadcast boundary." >&2
    exit 1
  fi
done
for local_broadcast_plan_contract in 'Status: Completed' 'make check' 'mutations'; do
  if ! grep -Fqi "$local_broadcast_plan_contract" "$LOCAL_BROADCAST_PLAN"; then
    printf '%s\n' "HRM local broadcast plan must record completed evidence: $local_broadcast_plan_contract" >&2
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
   [ "$(sha256_file "$ANDROID_RUNNER")" != "67bc532c8c84eb71c936980a89cac582bf98e243254c1d54522381a385345d37" ]; then
  printf '%s\n' "Android verification must retain the reviewed exact wrapper and SDK runner." >&2
  exit 1
fi

if [ ! -x "$PUBLICATION_GATE_TESTS" ] || [ -L "$PUBLICATION_GATE_TESTS" ] || \
   [ "$(sha256_file "$PUBLICATION_GATE_TESTS")" != "8c699de5328b540a881cee54a52e2dc0cfe3e24caae4c4c8a189b7786a143f94" ]; then
  printf '%s\n' "Publication-gate mutation tests must retain the reviewed contract." >&2
  exit 1
fi

if [ ! -x "$ARCHIVE_VERIFIER" ] || [ -L "$ARCHIVE_VERIFIER" ] || \
   [ "$(sha256_file "$ARCHIVE_VERIFIER")" != "3c41d3863eb2100dd9ac6c0420c2c952a5fa3a845e94de631aaeb6e53d59ecd6" ]; then
  printf '%s\n' "Archive manifest verifier must be present and executable." >&2
  exit 1
fi

if ! grep -Fxq 'APPROVED_RUNNER_SHA256=67bc532c8c84eb71c936980a89cac582bf98e243254c1d54522381a385345d37' "$PUBLICATION_GATE_TESTS"; then
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
