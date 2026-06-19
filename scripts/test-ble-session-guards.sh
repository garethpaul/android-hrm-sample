#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=${TMPDIR:-/tmp}/android-hrm-ble-session-tests.$$
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
mkdir -p "$TEST_ROOT/classes"

javac -source 7 -target 7 -d "$TEST_ROOT/classes" \
  "$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/CallbackGeneration.java" \
  "$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/GattConnectionOwner.java" \
  "$ROOT_DIR/scripts/tests/BleSessionGuardsTest.java"

java -cp "$TEST_ROOT/classes" com.garethpaul.app.hrm.BleSessionGuardsTest
