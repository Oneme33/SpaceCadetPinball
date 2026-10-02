#!/bin/bash
# Builds the release APK and zips it into dist/: the newest zip stays in
# dist/, earlier ones move to dist/history/.
#
#   tool/release_apk.sh
#
# dist/ is not part of the app build (only pubspec.yaml's assets are).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
flutter build apk --release
SHA=$(git rev-parse --short HEAD)
VERSION=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
NAME="space-cadet-$VERSION-$(date +%Y%m%d)-$SHA"
mkdir -p dist/history
for old in dist/*.zip; do
  [ -e "$old" ] && mv "$old" dist/history/
done
TMP=$(mktemp -d)
cp build/app/outputs/flutter-apk/app-release.apk "$TMP/$NAME.apk"
(cd "$TMP" && zip -q -9 "$ROOT/dist/$NAME.zip" "$NAME.apk")
rm -rf "$TMP"
echo "dist/$NAME.zip"
