.PHONY: build check lint test verify

build check lint test verify:
	@printf '%s\n' 'Make is not an authenticated verification boundary.' >&2
	@printf '%s\n' 'Run ./scripts/run-android-verification.sh directly.' >&2
	@exit 2
