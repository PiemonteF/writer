.PHONY: app run test clean

export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

app:
	@scripts/build-app.sh release

run: app
	open build/Writer.app

test:
	swift test

clean:
	rm -rf .build build
