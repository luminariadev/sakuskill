.PHONY: all setup analyze test coverage build-apk build-release clean run help

# Default target
all: analyze test

## setup: Install Flutter pub dependencies
setup:
	@echo "==> Fetching Flutter dependencies..."
	flutter pub get

## analyze: Run static code analysis with strict linting rules
analyze:
	@echo "==> Running Flutter analyze..."
	flutter analyze --fatal-infos --fatal-warnings

## test: Run unit & widget test suites
test:
	@echo "==> Running test suites..."
	flutter test

## coverage: Run tests with code coverage report
coverage:
	@echo "==> Generating code coverage report..."
	flutter test --coverage
	@echo "==> Coverage report generated at coverage/lcov.info"

## run: Run mobile app on connected device/emulator
run:
	flutter run

## build-apk: Build debug APK for testing
build-apk:
	@echo "==> Building debug APK..."
	flutter build apk --debug

## build-release: Build production release APK
build-release:
	@echo "==> Building release APK..."
	flutter build apk --release

## clean: Clean build cache and transient files
clean:
	@echo "==> Cleaning Flutter cache..."
	flutter clean
	flutter pub get

## help: Display this help message
help:
	@echo "SakuSkill Mobile DevOps Tasks:"
	@grep -h -E '^##' $(MAKEFILE_LIST) | sed -e 's/## //' | awk 'BEGIN {FS = ": "}; {printf "  %-15s %s\n", $$1, $$2}'
