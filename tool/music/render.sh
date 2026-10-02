#!/bin/bash
# Records the original music (PINBALL.MID) for the app, which has no MIDI
# synthesizer: TinySoundFont (MIT) plays it with the GeneralUser GS
# SoundFont (free to use), and lame makes an MP3 of it.
#
#   tool/music/render.sh [PINBALL.MID]     (default assets/original/PINBALL.MID)
#
# Writes assets/original/music.mp3 (git-ignored, like every original
# file); a WAV if lame is not installed. Needs clang and curl; downloads
# the synthesizer and the SoundFont (32 MB) into tool/music/.cache once.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
MID="${1:-$ROOT/assets/original/PINBALL.MID}"
CACHE="$HERE/.cache"
OUT="$ROOT/assets/original"
mkdir -p "$CACHE" "$OUT"
[ -f "$MID" ] || { echo "No $MID: run dart run tool/install_originals.dart first." >&2; exit 1; }

fetch() { [ -f "$CACHE/$1" ] || curl -sSfL -o "$CACHE/$1" "$2"; }
fetch tsf.h https://raw.githubusercontent.com/schellingb/TinySoundFont/main/tsf.h
fetch tml.h https://raw.githubusercontent.com/schellingb/TinySoundFont/main/tml.h
fetch GeneralUser-GS.sf2 https://github.com/mrbumpy409/GeneralUser-GS/raw/main/GeneralUser-GS.sf2

if [ ! -x "$CACHE/render_midi" ] || [ "$HERE/render_midi.c" -nt "$CACHE/render_midi" ]; then
  clang -O2 -w -I"$CACHE" "$HERE/render_midi.c" -o "$CACHE/render_midi" -lm
fi

if command -v lame >/dev/null; then
  "$CACHE/render_midi" "$CACHE/GeneralUser-GS.sf2" "$MID" "$CACHE/music.wav"
  lame --quiet -V 4 "$CACHE/music.wav" "$OUT/music.mp3"
  rm -f "$CACHE/music.wav" "$OUT/music.wav"
  echo "Wrote $OUT/music.mp3"
else
  "$CACHE/render_midi" "$CACHE/GeneralUser-GS.sf2" "$MID" "$OUT/music.wav" 22050
  echo "Wrote $OUT/music.wav (install lame for a smaller MP3)"
fi
