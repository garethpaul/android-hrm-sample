.PHONY: build check lint test verify

ANDROID_HOME ?= /home/gjones/android-sdk
ANDROID_SDK_ROOT ?= $(ANDROID_HOME)
GRADLE ?= ./gradlew

lint:
	scripts/check-baseline.sh
	@if [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) lint --no-daemon; \
	else \
		echo "Android SDK not found at $(ANDROID_HOME); Gradle lint skipped."; \
	fi

test:
	@if [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) check --no-daemon; \
	else \
		echo "Android SDK not found at $(ANDROID_HOME); Gradle check skipped."; \
	fi

build:
	@if [ -d "$(ANDROID_HOME)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" $(GRADLE) assembleDebug --no-daemon; \
	else \
		echo "Android SDK not found at $(ANDROID_HOME); Gradle build skipped."; \
	fi

verify: lint test build

check: verify
