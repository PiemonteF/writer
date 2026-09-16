.PHONY: app run install test clean

export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

app:
	@scripts/build-app.sh release

run: app
	open build/Writer.app

install: app
	rm -rf /Applications/Writer.app
	cp -R build/Writer.app /Applications/Writer.app
	open /Applications/Writer.app

test:
	swift test

clean:
	rm -rf .build build
