.PHONY: app run install test clean \
	linux-deps linux-app linux-run linux-test linux-install linux-uninstall linux-pkg \
	macos-app macos-run macos-test macos-install

export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

# Primary target: Linux (Omarchy / Arch)
app: linux-app
run: linux-run
test: linux-test
install: linux-install

linux-deps:
	cd linux && npm install

linux-app: linux-deps
	cd linux && npm run tauri:build

linux-run: linux-deps
	cd linux && npm run tauri:dev

linux-test: linux-deps
	cd linux && npm run build
	cd linux && node --experimental-strip-types scripts/smoke.mjs

# Install into ~/.local (Omarchy Walker picks up the .desktop entry)
# Override with: make linux-install PREFIX=/usr
linux-install: linux-app
	@if [ -n "$(PREFIX)" ]; then \
	  PREFIX="$(PREFIX)" bash linux/scripts/install-desktop.sh --skip-build --prefix "$(PREFIX)"; \
	else \
	  bash linux/scripts/install-desktop.sh --skip-build; \
	fi

linux-uninstall:
	@prefix="$(or $(PREFIX),$(HOME)/.local)"; \
	rm -f "$$prefix/bin/writer" \
	  "$$prefix/share/applications/writer.desktop" \
	  "$$prefix/share/applications/icons/writer.png" \
	  "$$prefix/share/icons/hicolor/32x32/apps/writer.png" \
	  "$$prefix/share/icons/hicolor/128x128/apps/writer.png" \
	  "$$prefix/share/icons/hicolor/256x256/apps/writer.png" \
	  "$$prefix/share/icons/hicolor/512x512/apps/writer.png"; \
	echo "Removed Writer from $$prefix"

# Build an Arch package (requires makepkg on Omarchy/Arch)
linux-pkg: linux-app
	@command -v makepkg >/dev/null || { echo "makepkg not found (Arch/Omarchy only)"; exit 1; }
	cd linux/packaging/arch && WRITER_SRC="$(CURDIR)" makepkg -sf --noconfirm

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
	rm -rf .build build linux/dist linux/src-tauri/target linux/packaging/arch/pkg linux/packaging/arch/src linux/packaging/arch/*.pkg.tar.*
