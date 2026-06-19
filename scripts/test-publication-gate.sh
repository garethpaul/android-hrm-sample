#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-hrm-publication-gate.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM
FAILURES=0

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
  'GitHub Actions check workflow must match the approved full Android security baseline.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: make -f /tmp/Makefile check#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-gradle-environment-substitution \
  'GitHub Actions check workflow must match the approved full Android security baseline.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: GRADLE=true ./scripts/run-android-verification.sh#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-sdk-environment-substitution \
  'GitHub Actions check workflow must match the approved full Android security baseline.' \
  "sed -i.bak 's#run: ./scripts/run-android-verification.sh#run: ANDROID_SDK= ./scripts/run-android-verification.sh#' .github/workflows/check.yml; rm .github/workflows/check.yml.bak"
expect_rejected workflow-shell-command-substitution \
  'GitHub Actions check workflow must match the approved full Android security baseline.' \
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

if [ "$FAILURES" -ne 0 ]; then
  printf '%s\n' "$FAILURES publication-gate mutations were accepted." >&2
  exit 1
fi

printf '%s\n' "Publication-gate mutation tests passed."
