.PHONY: build check lint test verify

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

build check lint test verify:
	@$(ROOT)scripts/run-android-verification.sh
