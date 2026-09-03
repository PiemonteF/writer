# The Command Line Tools SwiftPM ships a manifest library that fails to link, so build with Xcode's toolchain when present.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
