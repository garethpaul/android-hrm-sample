#!/usr/bin/env sh
set -eu

SOURCE_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

unset ANDROID_SDK CLASSPATH GRADLE GRADLE_OPTS GNUMAKEFLAGS JAVA_OPTS JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS MAKEFLAGS MAKEFILES MFLAGS _JAVA_OPTIONS
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_COMMON_DIR GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM GIT_CONFIG_SYSTEM GIT_DIR GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_WORK_TREE

if [ -z "${EXPECTED_COMMIT:-}" ]; then
  printf '%s\n' "Authenticated verification must name the reviewed commit." >&2
  exit 1
fi

REPOSITORY_ROOT=$(/usr/bin/git -C "$SOURCE_ROOT" rev-parse --show-toplevel)
REPOSITORY_ROOT=$(CDPATH= cd -- "$REPOSITORY_ROOT" && pwd -P)
GIT_DIRECTORY=$(/usr/bin/git -C "$SOURCE_ROOT" rev-parse --absolute-git-dir)
GIT_DIRECTORY=$(CDPATH= cd -- "$GIT_DIRECTORY" && pwd -P)
COMMON_DIRECTORY=$(/usr/bin/git -C "$SOURCE_ROOT" rev-parse --git-common-dir)
case "$COMMON_DIRECTORY" in
  /*) ;;
  *) COMMON_DIRECTORY="$SOURCE_ROOT/$COMMON_DIRECTORY" ;;
esac
COMMON_DIRECTORY=$(CDPATH= cd -- "$COMMON_DIRECTORY" && pwd -P)

if [ "$REPOSITORY_ROOT" != "$SOURCE_ROOT" ] || \
   [ "$GIT_DIRECTORY" != "$SOURCE_ROOT/.git" ] || \
   [ "$COMMON_DIRECTORY" != "$SOURCE_ROOT/.git" ]; then
  printf '%s\n' "Authenticated verification requires the reviewed repository and common Git directory." >&2
  exit 1
fi

ACTUAL_COMMIT=$(/usr/bin/git -C "$SOURCE_ROOT" rev-parse HEAD)
if [ "$ACTUAL_COMMIT" != "$EXPECTED_COMMIT" ]; then
  printf '%s\n' "Hosted verification checked out $ACTUAL_COMMIT instead of $EXPECTED_COMMIT." >&2
  exit 1
fi

INDEX_TREE=$(/usr/bin/git -C "$SOURCE_ROOT" write-tree)
EXPECTED_TREE=$(/usr/bin/git -C "$SOURCE_ROOT" rev-parse "$EXPECTED_COMMIT^{tree}")
if [ "$INDEX_TREE" != "$EXPECTED_TREE" ] || \
   ! /usr/bin/git -C "$SOURCE_ROOT" diff --quiet --no-ext-diff || \
   ! /usr/bin/git -C "$SOURCE_ROOT" diff --cached --quiet --no-ext-diff || \
   [ -n "$(/usr/bin/git -C "$SOURCE_ROOT" status --porcelain=v1 --untracked-files=all)" ]; then
  printf '%s\n' "Authenticated verification requires a clean tracked tree and index." >&2
  exit 1
fi

if [ "${GITHUB_ACTIONS:-}" != "true" ] || \
   [ "${RUNNER_OS:-}" != "Linux" ] || \
   [ "${ImageOS:-}" != "ubuntu24" ]; then
  printf '%s\n' "Authenticated verification is supported only by the pinned Ubuntu 24.04 GitHub Actions workflow." >&2
  exit 1
fi

if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  printf '%s\n' "The pinned setup-java step must provision Java 8." >&2
  exit 1
fi

if ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -Eq 'version "1\.8\.|openjdk version "1\.8\.'; then
  printf '%s\n' "The pinned setup-java step must provision Java 8." >&2
  exit 1
fi

if [ -z "${ANDROID_HOME:-}" ] || [ ! -d "$ANDROID_HOME" ]; then
  printf '%s\n' "ANDROID_HOME must name the installed Android SDK." >&2
  exit 1
fi

SDK_ROOT=$(CDPATH= cd -- "$ANDROID_HOME" && pwd -P)
if [ -n "${ANDROID_SDK_ROOT:-}" ] && \
   [ "$(CDPATH= cd -- "$ANDROID_SDK_ROOT" && pwd -P)" != "$SDK_ROOT" ]; then
  printf '%s\n' "ANDROID_HOME and ANDROID_SDK_ROOT must identify the same SDK." >&2
  exit 1
fi

if [ ! -f "$SDK_ROOT/platforms/android-22/android.jar" ] || \
   [ ! -x "$SDK_ROOT/build-tools/24.0.3/aapt" ]; then
  printf '%s\n' "Android API 22 and build-tools 24.0.3 must be installed." >&2
  exit 1
fi

ANDROID_HOME="$SDK_ROOT"
ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME ANDROID_SDK_ROOT

TEMP_ROOT=$(mktemp -d "${RUNNER_TEMP:-/tmp}/android-hrm-verification.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
SOURCE_ARCHIVE="$TEMP_ROOT/source.tar"
BUILD_ROOT="$TEMP_ROOT/source"
BUILD_LOG="$TEMP_ROOT/gradle.log"
ARCHIVE_VERIFIER="$TEMP_ROOT/verify-archive-tree.py"
GRADLE_USER_HOME="$TEMP_ROOT/gradle-user-home"
export GRADLE_USER_HOME

mkdir "$BUILD_ROOT"
/usr/bin/git -C "$SOURCE_ROOT" archive --format=tar --output="$SOURCE_ARCHIVE" "$EXPECTED_COMMIT"
/usr/bin/tar -xf "$SOURCE_ARCHIVE" -C "$BUILD_ROOT"
/usr/bin/git -C "$SOURCE_ROOT" show "$EXPECTED_COMMIT:scripts/verify-archive-tree.py" >"$ARCHIVE_VERIFIER"
/usr/bin/python3 "$ARCHIVE_VERIFIER" "$SOURCE_ROOT" "$EXPECTED_COMMIT" "$BUILD_ROOT"

"$BUILD_ROOT/scripts/check-baseline.sh"

if ! (
  cd "$BUILD_ROOT"
  "$BUILD_ROOT/gradlew" --no-daemon --no-color clean lint check assembleDebug
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
  if ! grep -Eq "^:Application:${task}(Note: .*)?$" "$BUILD_LOG"; then
    printf '%s\n' "Gradle did not execute :Application:${task} from a clean build." >&2
    exit 1
  fi
done

if ! grep -Fq "BUILD SUCCESSFUL" "$BUILD_LOG"; then
  printf '%s\n' "Gradle did not report a successful build." >&2
  exit 1
fi

if [ ! -s "$BUILD_ROOT/Application/build/outputs/lint-results.xml" ] || \
   [ ! -s "$BUILD_ROOT/Application/build/outputs/apk/Application-debug.apk" ]; then
  printf '%s\n' "Expected lint and debug APK artifacts were not produced." >&2
  exit 1
fi

if ! find "$BUILD_ROOT/Application/build/intermediates/classes/debug" -type f -name '*.class' -size +0c -print -quit | grep -q . || \
   ! find "$BUILD_ROOT/Application/build/intermediates/classes/release" -type f -name '*.class' -size +0c -print -quit | grep -q .; then
  printf '%s\n' "Expected debug and release Java class artifacts were not produced." >&2
  exit 1
fi

printf '%s\n' "Reviewed-head Gradle lint, check, debug/release compilation, and debug assembly passed."
