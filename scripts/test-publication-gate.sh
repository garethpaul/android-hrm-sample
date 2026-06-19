#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-hrm-publication-gate.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
FAILURES=0
APPROVED_RUNNER_SHA256=33a7262b70ae73e16733980c76c06c6c89666040147e2a4e5736352513fb080f

if [ "$(sha256sum "$ROOT_DIR/scripts/run-android-verification.sh" | cut -d ' ' -f 1)" != "$APPROVED_RUNNER_SHA256" ]; then
  printf '%s\n' "The Android runner does not match the independently reviewed digest." >&2
  exit 1
fi

copy_repository() {
  destination=$1
  mkdir -p "$destination"
  (
    cd "$ROOT_DIR"
    tar --exclude=.git -cf - .
  ) | (
    cd "$destination"
    tar -xf -
  )
}

initialize_git_fixture() {
  fixture=$1
  (
    cd "$fixture"
    git init -q
    git config user.name publication-gate-test
    git config user.email publication-gate-test@example.invalid
    git add .
    git commit -qm fixture
  )
}

expect_runner_rejected() {
  name=$1
  expected_message=$2
  setup=$3
  fixture="$TEST_ROOT/$name"

  copy_repository "$fixture"
  initialize_git_fixture "$fixture"
  setup_script="$TEST_ROOT/$name-setup.sh"
  runner_log="$TEST_ROOT/$name-runner.log"
  printf '%s\n' "$setup" >"$setup_script"

  if (
    cd "$fixture"
    . "$setup_script"
    EXPECTED_COMMIT=$(git rev-parse HEAD)
    export EXPECTED_COMMIT
    "$fixture/scripts/run-android-verification.sh"
  ) >"$runner_log" 2>&1; then
    printf '%s\n' "FAIL: Android runner accepted $name" >&2
    cat "$runner_log" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  if ! grep -Fq "$expected_message" "$runner_log"; then
    printf '%s\n' "FAIL: Android runner rejected $name for the wrong reason" >&2
    cat "$runner_log" >&2
    (cd "$fixture" && git status --short --untracked-files=all) >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  printf '%s\n' "PASS: Android runner rejected $name"
}

expect_archive_rejected() {
  name=$1
  mutation=$2
  fixture="$TEST_ROOT/$name"
  archive="$TEST_ROOT/$name.tar"
  extracted="$TEST_ROOT/$name-extracted"
  verifier_log="$TEST_ROOT/$name-verifier.log"

  copy_repository "$fixture"
  initialize_git_fixture "$fixture"
  (
    cd "$fixture"
    sh -c "$mutation"
    git add .
    git commit -qm "$name"
    git archive --format=tar --output="$archive" HEAD
  )
  mkdir "$extracted"
  tar -xf "$archive" -C "$extracted"

  if "$fixture/scripts/verify-archive-tree.py" \
    "$fixture" HEAD "$extracted" >"$verifier_log" 2>&1; then
    printf '%s\n' "FAIL: archive verifier accepted $name" >&2
    cat "$verifier_log" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  if ! grep -Fq 'Archive contents do not exactly match the reviewed Git tree.' "$verifier_log"; then
    printf '%s\n' "FAIL: archive verifier rejected $name for the wrong reason" >&2
    cat "$verifier_log" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  printf '%s\n' "PASS: archive verifier rejected $name"
}

expect_rejected() {
  name=$1
  expected_message=$2
  mutation=$3
  fixture="$TEST_ROOT/$name"

  copy_repository "$fixture"
  (
    cd "$fixture"
    sh -c "$mutation"
  )

  if "$fixture/scripts/check-baseline.sh" >"$fixture/check.log" 2>&1; then
    printf '%s\n' "FAIL: publication gate accepted $name" >&2
    cat "$fixture/check.log" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  if ! grep -Eq "$expected_message" "$fixture/check.log"; then
    printf '%s\n' "FAIL: publication gate rejected $name for the wrong reason" >&2
    cat "$fixture/check.log" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  printf '%s\n' "PASS: publication gate rejected $name"
}

expect_rejected appended-gradle-assignment \
  'Makefile must retain the reviewed non-substitutable verification entry point.' \
  'printf "\nGRADLE := true\n" >> Makefile'
expect_rejected appended-override-gradle-assignment \
  'Makefile must retain the reviewed non-substitutable verification entry point.' \
  'printf "\noverride GRADLE := true\n" >> Makefile'
expect_rejected cleared-android-sdk \
  'Makefile must retain the reviewed non-substitutable verification entry point.' \
  'printf "\nANDROID_SDK :=\n" >> Makefile'
expect_rejected overridden-android-sdk \
  'Makefile must retain the reviewed non-substitutable verification entry point.' \
  'printf "\noverride ANDROID_SDK := /tmp/fake-sdk\n" >> Makefile'
expect_rejected alternate-gnu-make-root \
  'Alternate root makefiles must not shadow the reviewed Makefile.' \
  'printf ".PHONY: check\ncheck:\n\t@true\n" > GNUmakefile'
expect_rejected alternate-lowercase-make-root \
  'Alternate root makefiles must not shadow|Makefile must retain the reviewed' \
  'printf ".PHONY: check\ncheck:\n\t@true\n" > makefile'
expect_rejected workflow-alternate-makefile \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: make -f /tmp/Makefile check#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-gradle-environment-substitution \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: GRADLE=true ./scripts/run-android-verification.sh#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-sdk-environment-substitution \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: ANDROID_SDK= ./scripts/run-android-verification.sh#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-shell-command-substitution \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: sh -c ./scripts/run-android-verification.sh#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-default-pull-request-merge-ref \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak '/ref:.*pull_request.head.sha/d' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-missing-expected-commit \
  'GitHub Actions check workflow must match the reviewed hosted Android verification workflow.' \
  "sed -i.bak '/EXPECTED_COMMIT:/d' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected runner-gradle-variable-substitution \
  'Android verification must retain the reviewed exact wrapper and SDK runner.' \
  'cat > scripts/run-android-verification.sh <<"EOF"
#!/usr/bin/env sh
set -eu
"${GRADLE:-true}" lint check assembleDebug
EOF
chmod +x scripts/run-android-verification.sh'
expect_rejected runner-path-gradle-substitution \
  'Android verification must retain the reviewed exact wrapper and SDK runner.' \
  'cat > scripts/run-android-verification.sh <<"EOF"
#!/usr/bin/env sh
set -eu
gradle lint check assembleDebug
EOF
chmod +x scripts/run-android-verification.sh'
expect_rejected runner-sdk-variable-substitution \
  'Android verification must retain the reviewed exact wrapper and SDK runner.' \
  'cat > scripts/run-android-verification.sh <<"EOF"
#!/usr/bin/env sh
set -eu
ANDROID_HOME="${ANDROID_SDK:-}" ./gradlew lint check assembleDebug
EOF
chmod +x scripts/run-android-verification.sh'
expect_rejected runner-shell-evaluation-substitution \
  'Android verification must retain the reviewed exact wrapper and SDK runner.' \
  'cat > scripts/run-android-verification.sh <<"EOF"
#!/usr/bin/env sh
set -eu
eval "${GRADLE:-./gradlew} lint check assembleDebug"
EOF
chmod +x scripts/run-android-verification.sh'
expect_rejected coedited-runner-and-checker-digest \
  'Publication-gate tests must independently pin the reviewed Android runner.' \
  'cat > scripts/run-android-verification.sh <<"EOF"
#!/usr/bin/env sh
exit 0
EOF
chmod +x scripts/run-android-verification.sh
new_hash=$(sha256sum scripts/run-android-verification.sh | cut -d " " -f 1)
sed -i.bak "s/33a7262b70ae73e16733980c76c06c6c89666040147e2a4e5736352513fb080f/$new_hash/g" scripts/check-baseline.sh
rm scripts/check-baseline.sh.bak'
expect_rejected appended-application-gradle-forgery \
  'Application Gradle build definition must retain the reviewed Android plugin tasks.' \
  'cat >> Application/build.gradle <<"EOF"

task forgePublicationEvidence { doLast { println ":Application:compileDebugJava" } }
EOF'
expect_rejected replaced-root-gradle-build \
  'Root Gradle build definition must retain the reviewed project contract.' \
  'printf "task fake\n" > build.gradle'
expect_rejected replaced-gradle-settings \
  'Gradle settings must retain the reviewed Application project inclusion.' \
  'printf "include :Fake\n" > settings.gradle'
expect_rejected modified-lint-configuration \
  'Android lint configuration must retain the reviewed gate contract.' \
  'printf "\n<!-- bypass -->\n" >> Application/lint.xml'
expect_rejected added-gradle-properties \
  'Unreviewed Gradle configuration entry points are not allowed.' \
  'printf "org.gradle.daemon=false\n" > gradle.properties'
expect_rejected added-local-properties \
  'Unreviewed Gradle configuration entry points are not allowed.' \
  'printf "sdk.dir=/tmp/fake\n" > local.properties'
expect_rejected added-buildsrc \
  'Unreviewed Gradle configuration entry points are not allowed.' \
  'mkdir -p buildSrc/src/main/groovy; printf "class Fake {}\n" > buildSrc/src/main/groovy/Fake.groovy'

expect_runner_rejected fake-caller-controlled-java \
  'Hosted Java must come from the pinned Corretto toolcache.' \
  'fake_root="$TEST_ROOT/fake-hosted-toolchain"
mkdir -p "$fake_root/jdk/bin" "$fake_root/sdk/platforms/android-22" "$fake_root/sdk/build-tools/24.0.3" "$fake_root/toolcache"
printf x > "$fake_root/sdk/platforms/android-22/android.jar"
printf "#!/bin/sh\nexit 0\n" > "$fake_root/sdk/build-tools/24.0.3/aapt"
chmod +x "$fake_root/sdk/build-tools/24.0.3/aapt"
cat > "$fake_root/jdk/bin/java" <<"EOF"
#!/bin/sh
if [ "${1:-}" = "-version" ]; then
  echo "java version \"1.8.0_fake\"" >&2
  exit 0
fi
mkdir -p Application/build/outputs/apk Application/build/intermediates/classes/debug Application/build/intermediates/classes/release
printf x > Application/build/outputs/lint-results.xml
printf x > Application/build/outputs/apk/Application-debug.apk
printf x > Application/build/intermediates/classes/debug/Fake.class
printf x > Application/build/intermediates/classes/release/Fake.class
printf "%s\n" :Application:compileDebugJava :Application:compileReleaseJava :Application:lint :Application:check :Application:assembleDebug "BUILD SUCCESSFUL"
EOF
chmod +x "$fake_root/jdk/bin/java"
export GITHUB_ACTIONS=true RUNNER_OS=Linux ImageOS=ubuntu24 RUNNER_TOOL_CACHE="$fake_root/toolcache"
export JAVA_HOME="$fake_root/jdk" ANDROID_HOME="$fake_root/sdk"'

expect_runner_rejected dirty-tracked-worktree \
  'Authenticated verification requires a clean tracked tree and index.' \
  'printf "\nunauthorized drift\n" >> README.md'
expect_runner_rejected dirty-index \
  'Authenticated verification requires a clean tracked tree and index.' \
  'printf "\nunauthorized staged drift\n" >> README.md; git add README.md'
expect_runner_rejected untracked-protected-gradle-file \
  'Authenticated verification requires a clean tracked tree and index.' \
  'printf "org.gradle.daemon=false\n" > gradle.properties'
expect_runner_rejected git-dir-substitution-with-dirty-tree \
  'Authenticated verification requires a clean tracked tree and index.' \
  'cp -R .git ../decoy.git; printf "\nunauthorized drift\n" >> README.md; export GIT_DIR="$PWD/../decoy.git"'
expect_runner_rejected git-work-tree-substitution-with-dirty-tree \
  'Authenticated verification requires a clean tracked tree and index.' \
  'mkdir ../clean-tree; git archive HEAD | tar -xf - -C ../clean-tree; printf "\nunauthorized drift\n" >> README.md; export GIT_WORK_TREE="$PWD/../clean-tree"'

expect_archive_rejected export-ignore-java-source \
  'printf "%s\n" "Application/src/main/java/com/garethpaul/app/hrm/ArchiveIgnoredBroken.java export-ignore" > .gitattributes
cat > Application/src/main/java/com/garethpaul/app/hrm/ArchiveIgnoredBroken.java <<"EOF"
package com.garethpaul.app.hrm;
public class ArchiveIgnoredBroken { public void broken() { int value = } }
EOF'
expect_archive_rejected export-ignore-build-input \
  'printf "%s\n" "Application/build.gradle export-ignore" > .gitattributes'
expect_archive_rejected export-ignore-publication-script \
  'printf "%s\n" "scripts/check-baseline.sh export-ignore" > .gitattributes'
expect_archive_rejected export-subst-byte-drift \
  'printf "%s\n" "README.md export-subst" > .gitattributes
cat >> README.md <<"EOF"

archive commit: $Format:%H$
EOF'

make_command=$(make -s -n -f "$ROOT_DIR/Makefile" ROOT=/tmp/attacker/ check 2>&1 || :)
if printf '%s\n' "$make_command" | grep -Fq '/tmp/attacker/'; then
  printf '%s\n' "FAIL: command-line ROOT redirected the reviewed Make entry point" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: command-line ROOT cannot redirect the reviewed Make entry point"
fi

if grep -F 'scripts/run-android-verification.sh' "$ROOT_DIR/Makefile" | grep -Fvq 'printf'; then
  printf '%s\n' "FAIL: Make remains represented as an authenticated verification entry point" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: Make is outside the authenticated verification boundary"
fi

make_log="$TEST_ROOT/make-boundary.log"
if make -s -f "$ROOT_DIR/Makefile" check >"$make_log" 2>&1 || \
   ! grep -Fq 'Make is unsupported. Use the pinned GitHub Actions Check workflow' "$make_log"; then
  printf '%s\n' "FAIL: Make does not explicitly refuse authenticated verification" >&2
  cat "$make_log" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: Make explicitly refuses authenticated verification"
fi

probe_log="$TEST_ROOT/make-ignore.log"
if make -s -f "$ROOT_DIR/Makefile" -i check >"$probe_log" 2>&1; then
  printf '%s\n' "FAIL: unsupported Make -i invocation returned success" >&2
  cat "$probe_log" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: unsupported Make -i invocation failed"
fi

probe_log="$TEST_ROOT/make-dry-run.log"
if make -s -f "$ROOT_DIR/Makefile" -n check >"$probe_log" 2>&1; then
  printf '%s\n' "FAIL: unsupported Make -n invocation returned success" >&2
  cat "$probe_log" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: unsupported Make -n invocation failed"
fi

probe_log="$TEST_ROOT/make-shell.log"
if make -s -f "$ROOT_DIR/Makefile" SHELL=/usr/bin/true check >"$probe_log" 2>&1; then
  printf '%s\n' "FAIL: unsupported Make SHELL override returned success" >&2
  cat "$probe_log" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: unsupported Make SHELL override failed"
fi

if ! grep -Fq 'The pinned GitHub Actions `Check` workflow is the only supported authenticated' "$ROOT_DIR/README.md" || \
   grep -Fq 'runs full `make check`' "$ROOT_DIR/README.md" || \
   grep -Fq 'CI baseline that runs the root Make gate' "$ROOT_DIR/README.md"; then
  printf '%s\n' "FAIL: README does not bound publication evidence to the exact runner" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: README bounds publication evidence to the exact runner"
fi

README_SETUP=$(sed -n '/^### Setup$/,/^## Running or Using the Project$/p' "$ROOT_DIR/README.md")
if printf '%s\n' "$README_SETUP" | grep -Fq './scripts/run-android-verification.sh'; then
  printf '%s\n' "FAIL: README setup instructs local execution of the hosted-only runner" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: README setup omits the hosted-only runner"
fi

if grep -Fq 'make check' "$ROOT_DIR/docs/readme-overview.svg" || \
   ! grep -Fq 'GitHub Actions Check' "$ROOT_DIR/docs/readme-overview.svg" || \
   ! grep -Fq 'Make unsupported' "$ROOT_DIR/docs/readme-overview.svg"; then
  printf '%s\n' "FAIL: overview graphic does not describe the supported verification boundary" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: overview graphic describes the supported verification boundary"
fi

if ! grep -Fq 'The pinned GitHub Actions `Check` workflow is the only supported authenticated' "$ROOT_DIR/SECURITY.md" || \
   grep -Fq 'runs the root `make check` baseline' "$ROOT_DIR/SECURITY.md"; then
  printf '%s\n' "FAIL: security guidance still treats Make as authenticated evidence" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: security guidance excludes Make from authenticated evidence"
fi

if ! grep -Fq 'unset ANDROID_SDK GRADLE GRADLE_OPTS GNUMAKEFLAGS JAVA_OPTS JAVA_TOOL_OPTIONS MAKEFLAGS MAKEFILES MFLAGS _JAVA_OPTIONS' \
  "$ROOT_DIR/scripts/run-android-verification.sh"; then
  printf '%s\n' "FAIL: Android runner does not clear inherited JVM and Gradle injection options" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: Android runner clears inherited JVM and Gradle injection options"
fi

if ! grep -Fq 'EXPECTED_COMMIT' "$ROOT_DIR/scripts/run-android-verification.sh" || \
   ! grep -Fq '/usr/bin/git -C "$SOURCE_ROOT" rev-parse HEAD' "$ROOT_DIR/scripts/run-android-verification.sh" || \
   ! grep -Fq 'archive --format=tar' "$ROOT_DIR/scripts/run-android-verification.sh"; then
  printf '%s\n' "FAIL: Android runner does not bind hosted evidence to the reviewed commit" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: Android runner binds hosted evidence to the reviewed commit"
fi

if [ "$FAILURES" -ne 0 ]; then
  printf '%s\n' "$FAILURES publication-gate mutations were accepted." >&2
  exit 1
fi

printf '%s\n' "Publication-gate mutation tests passed."
