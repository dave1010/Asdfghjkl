.PHONY: build test run clean

build:
	swift build
	@echo "Executable built at .build/debug/Asdfghjkl"

build-prod:
	swift build --configuration release --product Asdfghjkl

test:
	swift test --parallel

run: build
	.build/debug/Asdfghjkl

run-prod: build-prod
	.build/release/Asdfghjkl

clean:
	swift package clean
