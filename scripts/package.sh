#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(cat VERSION)"
./scripts/build.sh --universal
if [[ ! -x .build/packaging/bin/dmgbuild ]]; then
  python3 -m venv .build/packaging
  .build/packaging/bin/pip install -r packaging/requirements.txt
fi
# Optional Developer ID + notarytool profile. Neither is needed to build a preview.
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  : "${SIGNING_IDENTITY:?Notarization requires a Developer ID Application identity}"
  ditto -c -k --keepParent dist/Vista.app dist/Vista-notarization.zip
  xcrun notarytool submit dist/Vista-notarization.zip --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple dist/Vista.app
fi
DMG="dist/Vista-$VERSION-universal.dmg"
.build/packaging/bin/dmgbuild -s packaging/dmg-settings.py -D root="$PWD" "Vista" "$DMG"
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi
hdiutil verify "$DMG"
VERIFY_MOUNT="$(mktemp -d "${TMPDIR:-/tmp}/vista-verify.XXXXXX")"
cleanup() { hdiutil detach "$VERIFY_MOUNT" >/dev/null 2>&1 || true; rmdir "$VERIFY_MOUNT" 2>/dev/null || true; }
trap cleanup EXIT
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$VERIFY_MOUNT"
codesign --verify --deep --strict "$VERIFY_MOUNT/Vista.app"
lipo "$VERIFY_MOUNT/Vista.app/Contents/MacOS/Vista" -verify_arch arm64 x86_64
test "$(readlink "$VERIFY_MOUNT/Applications")" = /Applications
hdiutil detach "$VERIFY_MOUNT"
rmdir "$VERIFY_MOUNT"
trap - EXIT
(cd dist && shasum -a 256 "Vista-$VERSION-universal.dmg" > SHA256SUMS.txt)
printf '\nRelease artifacts: %s and dist/SHA256SUMS.txt\n' "$DMG"
