.PHONY: build check lint test verify

ANDROID_HOME ?=
ANDROID_SDK_ROOT ?= $(ANDROID_HOME)
GRADLE ?= ./gradlew

lint:
	scripts/check-baseline.sh
	@if [ -n "$(ANDROID_HOME)" ] && [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) lint --no-daemon; \
	else \
		echo "Android SDK not configured; Gradle lint skipped."; \
	fi

test:
	@if [ -n "$(ANDROID_HOME)" ] && [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) check --no-daemon; \
	else \
		echo "Android SDK not configured; Gradle check skipped."; \
	fi

build:
	@if [ -n "$(ANDROID_HOME)" ] && [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) assembleDebug --no-daemon; \
	else \
		echo "Android SDK not configured; Gradle build skipped."; \
	fi

verify: lint test build

check: verify
