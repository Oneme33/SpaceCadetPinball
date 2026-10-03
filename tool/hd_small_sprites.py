#!/usr/bin/env python3
"""Upscales the small sprites of the HD set with xBRZ instead of
Real-ESRGAN: lamps of a few pixels come out of ESRGAN as rectangles,
xBRZ (made for pixel art) rounds them the way they are drawn.

    python3 tool/hd_small_sprites.py <src dir> <out dir> [max size] [scale]

Overwrites out/gN.png for every src/gN.png whose width and height are at
most max size (default 16). Needs `pip install xbrz.py Pillow`.
"""
import os
import sys

import xbrz
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
limit = int(sys.argv[3]) if len(sys.argv) > 3 else 16
scale = int(sys.argv[4]) if len(sys.argv) > 4 else 4
count = 0
for name in sorted(os.listdir(src)):
    if not name.endswith('.png'):
        continue
    im = Image.open(os.path.join(src, name)).convert('RGBA')
    if max(im.size) > limit:
        continue
    xbrz.scale_pillow(im, scale).save(os.path.join(out, name))
    count += 1
print(f'xBRZ for {count} small sprites')
