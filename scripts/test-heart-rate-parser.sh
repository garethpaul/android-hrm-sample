#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=${TMPDIR:-/tmp}/android-hrm-heart-rate-parser-tests.$$
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
mkdir -p "$TEST_ROOT/classes"

javac -source 7 -target 7 -d "$TEST_ROOT/classes" \
  "$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurement.java" \
  "$ROOT_DIR/Application/src/main/java/com/garethpaul/app/hrm/HeartRateMeasurementParser.java" \
  "$ROOT_DIR/scripts/tests/HeartRateMeasurementParserTest.java"

java -cp "$TEST_ROOT/classes" com.garethpaul.app.hrm.HeartRateMeasurementParserTest
