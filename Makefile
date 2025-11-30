.PHONY: build test run clean

build:
	swift build
	swiftc -o .build/debug/Asdfghjkl-cli Sources/Asdfghjkl/*.swift Sources/AsdfghjklCore/*.swift
	@echo "Executable built at .build/debug/Asdfghjkl"
	@echo "Alternate CLI stub built at .build/debug/Asdfghjkl-cli"

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
	rm -f .build/debug/Asdfghjkl-cli
