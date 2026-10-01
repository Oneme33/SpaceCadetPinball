#!/bin/bash
# Builds the measurement harness around the SpaceCadetPinball
# decompilation (k4zmu2a/SpaceCadetPinball, MIT), headless and without
# audio. Needs clang++, pkg-config and SDL2 (brew install sdl2 pkg-config).
#
#   tool/compare/harness/build.sh <work dir>
#
# Clones the decompilation into <work dir>/ref (once), makes its random
# field push switchable, and builds <work dir>/harness.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mkdir -p "$1" && cd "$1" && pwd)"
REF="$WORK/ref"
if [ ! -d "$REF" ]; then
  git clone -q --depth 1 https://github.com/k4zmu2a/SpaceCadetPinball.git "$REF"
fi
SRC="$REF/SpaceCadetPinball"
# RandFloat() returns 0.5 while HarnessNoRandom is set (the default), so
# runs are repeatable and comparable with the port's.
if ! grep -q HarnessNoRandom "$SRC/pch.h"; then
  python3 - "$SRC/pch.h" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace('inline float RandFloat()\n{\n\treturn',
              'extern bool HarnessNoRandom;\ninline float RandFloat()\n{\n\tif (HarnessNoRandom) return 0.5f;\n\treturn')
open(p, 'w').write(s)
PY
fi
mkdir -p "$WORK/obj"
# Paths may contain spaces (the project's does), so no xargs.
flags=(-std=c++14 -O2 -w -I"$SRC" -I"$HERE/stub" $(pkg-config --cflags sdl2))
jobs=0
for f in "$SRC"/*.cpp "$HERE/harness.cpp"; do
  [ "$(basename "$f")" = SpaceCadetPinball.cpp ] && continue
  o="$WORK/obj/$(basename "$f" .cpp).o"
  if [ ! -f "$o" ] || [ "$f" -nt "$o" ]; then
    clang++ "${flags[@]}" -c "$f" -o "$o" &
    jobs=$((jobs + 1))
    if [ $jobs -ge 8 ]; then wait; jobs=0; fi
  fi
done
wait
clang++ "$WORK"/obj/*.o $(pkg-config --libs sdl2) -o "$WORK/harness"
echo "built $WORK/harness"
