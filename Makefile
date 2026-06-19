.PHONY: build check lint test verify

override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

build check lint test verify:
	@$(ROOT)scripts/run-android-verification.sh
