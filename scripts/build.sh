#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
VERSION="$(cat VERSION)"
APP="$PWD/dist/Vista.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ "${1:-}" == "--universal" ]]; then
  for ARCH in arm64 x86_64; do
    swift build -c release --disable-sandbox --arch "$ARCH"
  done
  lipo -create .build/arm64-apple-macosx/release/Vista .build/x86_64-apple-macosx/release/Vista -output "$APP/Contents/MacOS/Vista.new"
else
  swift build -c release --disable-sandbox
  cp .build/release/Vista "$APP/Contents/MacOS/Vista.new"
fi
mv -f "$APP/Contents/MacOS/Vista.new" "$APP/Contents/MacOS/Vista"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Vista</string>
<key>CFBundleDisplayName</key><string>Vista</string>
<key>CFBundleIdentifier</key><string>local.vista.app</string>
<key>CFBundleExecutable</key><string>Vista</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><false/>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>Vista</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Sauren Khosla. MIT License.</string>
</dict></plist>
PLIST
cp Assets/Vista.icns "$APP/Contents/Resources/"
if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi
codesign --verify --deep --strict "$APP"
printf 'Built %s (%s)\n' "$APP" "$VERSION"
