#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GRADLEW="$ROOT_DIR/gradlew"

unset ANDROID_SDK GRADLE GNUMAKEFLAGS MAKEFLAGS MAKEFILES MFLAGS

if [ -z "${ANDROID_HOME:-}" ] || [ ! -d "$ANDROID_HOME" ]; then
  printf '%s\n' "ANDROID_HOME must name the installed Android SDK." >&2
  exit 1
fi

SDK_ROOT=$(CDPATH= cd -- "$ANDROID_HOME" && pwd)
if [ -n "${ANDROID_SDK_ROOT:-}" ] && \
   [ "$(CDPATH= cd -- "$ANDROID_SDK_ROOT" && pwd)" != "$SDK_ROOT" ]; then
  printf '%s\n' "ANDROID_HOME and ANDROID_SDK_ROOT must identify the same SDK." >&2
  exit 1
fi

if [ ! -f "$SDK_ROOT/platforms/android-22/android.jar" ] || \
   [ ! -x "$SDK_ROOT/build-tools/24.0.3/aapt" ]; then
  printf '%s\n' "Android API 22 and build-tools 24.0.3 must be installed." >&2
  exit 1
fi

if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  printf '%s\n' "JAVA_HOME must identify the configured Java 8 runtime." >&2
  exit 1
fi

if ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -Eq 'version "1\.8\.'; then
  printf '%s\n' "The Android verification gate requires Java 8." >&2
  exit 1
fi

PATH="$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH
ANDROID_HOME="$SDK_ROOT"
ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME ANDROID_SDK_ROOT

"$ROOT_DIR/scripts/check-baseline.sh"

TEMP_ROOT=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/android-hrm-verification.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
BUILD_LOG="$TEMP_ROOT/gradle.log"
GRADLE_USER_HOME="$TEMP_ROOT/gradle-user-home"
export GRADLE_USER_HOME

if ! (
  cd "$ROOT_DIR"
  "$GRADLEW" --no-daemon --console plain clean lint check assembleDebug
) >"$BUILD_LOG" 2>&1; then
  cat "$BUILD_LOG" >&2
  exit 1
fi

cat "$BUILD_LOG"

for task in \
  compileDebugJava \
  compileReleaseJava \
  lint \
  check \
  assembleDebug; do
  if ! grep -Eq "^:Application:${task}$" "$BUILD_LOG"; then
    printf '%s\n' "Gradle did not execute :Application:${task} from a clean build." >&2
    exit 1
  fi
done

if ! grep -Fq "BUILD SUCCESSFUL" "$BUILD_LOG"; then
  printf '%s\n' "Gradle did not report a successful build." >&2
  exit 1
fi

if [ ! -s "$ROOT_DIR/Application/build/outputs/lint-results.xml" ] || \
   [ ! -s "$ROOT_DIR/Application/build/outputs/apk/Application-debug.apk" ]; then
  printf '%s\n' "Expected lint and debug APK artifacts were not produced." >&2
  exit 1
fi

if ! find "$ROOT_DIR/Application/build/intermediates/classes/debug" -type f -name '*.class' -print -quit | grep -q . || \
   ! find "$ROOT_DIR/Application/build/intermediates/classes/release" -type f -name '*.class' -print -quit | grep -q .; then
  printf '%s\n' "Expected debug and release Java class artifacts were not produced." >&2
  exit 1
fi

printf '%s\n' "Authenticated Gradle lint, check, debug/release compilation, and debug assembly passed."
