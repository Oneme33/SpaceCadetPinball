#!/bin/bash
# Puts the website together in build/site/ (git-ignored: the game in it
# carries the original files):
#   index.html …   the landing page, from site/
#   play/          the web build of the game
#   download/      the newest APK from dist/
#
#   tool/build_site.sh            build only
#   tool/build_site.sh --serve    and serve it on http://localhost:8124
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT=build/site
rm -rf "$OUT"
mkdir -p "$OUT/download"
flutter build web --release --base-href /play/
cp -R build/web "$OUT/play"
cp site/*.html site/*.css site/*.js site/*.txt site/*.xml site/*.png "$OUT/"
cp web/icons/Icon-512.png "$OUT/icon.png"
ZIP=$(ls -t dist/space-cadet-*.zip 2>/dev/null | head -1)
if [ -n "$ZIP" ]; then
  unzip -p "$ZIP" '*.apk' > "$OUT/download/space-cadet.apk"
else
  echo "No APK in dist/ yet: run tool/release_apk.sh for the download." >&2
fi
echo "Site in $OUT"
if [ "$1" = "--serve" ]; then
  python3 -m http.server 8124 --directory "$OUT"
fi
