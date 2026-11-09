.PHONY: app run install test clean linux-deps linux-app linux-run linux-test macos-app macos-run macos-test

export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

# Primary target: Linux (Omarchy / Arch)
app: linux-app
run: linux-run
test: linux-test
install: linux-app
	@echo "Install a bundle from linux/src-tauri/target/release/bundle/ or copy:"
	@echo "  linux/src-tauri/target/release/writer"

linux-deps:
	cd linux && npm install

linux-app: linux-deps
	cd linux && npm run tauri:build

linux-run: linux-deps
	cd linux && npm run tauri:dev

linux-test: linux-deps
	cd linux && npm run build
	cd linux && node --experimental-strip-types scripts/smoke.mjs

# macOS (legacy / reference)
macos-app:
	@scripts/build-app.sh release

macos-run: macos-app
	open build/Writer.app

macos-test:
	swift test

macos-install: macos-app
	rm -rf /Applications/Writer.app
	cp -R build/Writer.app /Applications/Writer.app
	open /Applications/Writer.app

clean:
	rm -rf .build build linux/dist linux/src-tauri/target
