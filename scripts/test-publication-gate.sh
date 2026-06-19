#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-hrm-publication-gate.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
FAILURES=0
APPROVED_RUNNER_SHA256=fe4d3c94fb20fcb015b5a2c4ba91b0e331f112c908d1546b7ce91beed649da9d

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
sed -i.bak "s/fe4d3c94fb20fcb015b5a2c4ba91b0e331f112c908d1546b7ce91beed649da9d/$new_hash/g" scripts/check-baseline.sh
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

if [ "$FAILURES" -ne 0 ]; then
  printf '%s\n' "$FAILURES publication-gate mutations were accepted." >&2
  exit 1
fi

printf '%s\n' "Publication-gate mutation tests passed."
