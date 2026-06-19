#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-hrm-publication-gate.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
FAILURES=0
APPROVED_RUNNER_SHA256=956d172ccc4a0e0cd0d6c7d7875c7fee81a94a7687ccd1e04733f723e57dd66c

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
sed -i.bak "s/956d172ccc4a0e0cd0d6c7d7875c7fee81a94a7687ccd1e04733f723e57dd66c/$new_hash/g" scripts/check-baseline.sh
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

make_command=$(make -s -n -f "$ROOT_DIR/Makefile" ROOT=/tmp/attacker/ check)
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
   ! grep -Fq 'Run ./scripts/run-android-verification.sh directly.' "$make_log"; then
  printf '%s\n' "FAIL: Make does not explicitly refuse authenticated verification" >&2
  cat "$make_log" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: Make explicitly refuses authenticated verification"
fi

if ! grep -Fq 'The exact runner is the only authenticated publication-gate entry point.' "$ROOT_DIR/README.md" || \
   grep -Fq 'runs full `make check`' "$ROOT_DIR/README.md"; then
  printf '%s\n' "FAIL: README does not bound publication evidence to the exact runner" >&2
  FAILURES=$((FAILURES + 1))
else
  printf '%s\n' "PASS: README bounds publication evidence to the exact runner"
fi

if ! grep -Fq 'The exact runner, not Make, is the authenticated hosted publication gate.' "$ROOT_DIR/SECURITY.md" || \
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
   ! grep -Fq '/usr/bin/git -C "$ROOT_DIR" rev-parse HEAD' "$ROOT_DIR/scripts/run-android-verification.sh"; then
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
