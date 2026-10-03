#!/usr/bin/env python3
"""HD versions of the small sprites (lamps, arrows) of the HD set.

Real-ESRGAN turns a lamp of a few pixels into a rectangle. So:
- a round lamp (its opaque pixels fill the ellipse of its bounding box)
  is drawn anew as a smooth ellipse, coloured from the centre outwards
  with the original's own colours (its radial colour profile): the same
  bright core and dark rim, now round at any size;
- other small sprites (triangles, arrows) use xBRZ, made for pixel art.

    python3 tool/hd_small_sprites.py <src dir> <out dir> [max size] [scale]

Overwrites out/gN.png for every src/gN.png whose width and height are at
most max size (default 16). Needs `pip install xbrz.py Pillow`.
"""
import math
import os
import sys

import xbrz
from PIL import Image

BINS = 10


def lamp(im, scale):
    """The lamp redrawn round, or None if the sprite is not round."""
    w, h = im.size
    px = im.load()
    opaque = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] > 0]
    if len(opaque) < 6:
        return None
    x0 = min(p[0] for p in opaque); x1 = max(p[0] for p in opaque) + 1
    y0 = min(p[1] for p in opaque); y1 = max(p[1] for p in opaque) + 1
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = (x1 - x0) / 2, (y1 - y0) / 2
    if rx < 1.5 or ry < 1.5 or max(rx, ry) / min(rx, ry) > 2.2:
        return None

    def rho(x, y):
        return math.hypot((x - cx) / rx, (y - cy) / ry)

    # Round: the opaque pixels and the ellipse mostly coincide.
    inside = {(x, y) for y in range(h) for x in range(w) if rho(x + .5, y + .5) <= 1}
    mask = set(opaque)
    iou = len(inside & mask) / max(1, len(inside | mask))
    if iou < 0.72:
        return None

    # Radial profile of colour and opacity, centre to rim.
    acc = [[0, 0, 0, 0, 0] for _ in range(BINS)]
    for y in range(h):
        for x in range(w):
            r = rho(x + .5, y + .5)
            if r > 1.15:
                continue
            b = min(BINS - 1, int(r / 1.15 * BINS))
            p = px[x, y]
            a = p[3] / 255
            acc[b][0] += p[0] * a; acc[b][1] += p[1] * a; acc[b][2] += p[2] * a
            acc[b][3] += a; acc[b][4] += 1
    prof = []
    for r, g, b, a, n in acc:
        prof.append(None if a == 0 else (r / a, g / a, b / a, a / n))
    # Fill gaps from the neighbours (inwards first).
    for i in range(BINS):
        if prof[i] is None:
            j = next((k for k in range(i - 1, -1, -1) if prof[k]), None)
            if j is None:
                j = next(k for k in range(i + 1, BINS) if prof[k])
            prof[i] = prof[j]

    def sample(r):
        t = min(r / 1.15 * BINS - .5, BINS - 1.0)
        if t <= 0:
            return prof[0]
        i = int(t); f = t - i
        a, b = prof[i], prof[min(i + 1, BINS - 1)]
        return tuple(a[k] + (b[k] - a[k]) * f for k in range(4))

    W, H = w * scale, h * scale
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    o = out.load()
    ss = 4  # supersampling for smooth edges
    for Y in range(H):
        for X in range(W):
            r_sum = g_sum = b_sum = a_sum = 0.0
            for sy in range(ss):
                for sx in range(ss):
                    x = (X + (sx + .5) / ss) / scale
                    y = (Y + (sy + .5) / ss) / scale
                    r = rho(x, y)
                    if r > 1.15:
                        continue
                    cr, cg, cb, ca = sample(r)
                    # Soft edge just outside the ellipse.
                    ca *= max(0.0, min(1.0, (1.15 - r) / 0.15)) if r > 1 else 1
                    r_sum += cr * ca; g_sum += cg * ca; b_sum += cb * ca; a_sum += ca
            if a_sum > 0:
                o[X, Y] = (round(r_sum / a_sum), round(g_sum / a_sum),
                           round(b_sum / a_sum), round(255 * a_sum / (ss * ss)))
    return out


def main():
    src, dst = sys.argv[1], sys.argv[2]
    limit = int(sys.argv[3]) if len(sys.argv) > 3 else 16
    scale = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    lamps = pixel = 0
    for name in sorted(os.listdir(src)):
        if not name.endswith('.png'):
            continue
        im = Image.open(os.path.join(src, name)).convert('RGBA')
        if max(im.size) > limit:
            continue
        out = lamp(im, scale)
        if out is not None:
            lamps += 1
        else:
            out = xbrz.scale_pillow(im, scale)
            pixel += 1
        out.save(os.path.join(dst, name))
    print(f'Small sprites: {lamps} round lamps redrawn, {pixel} with xBRZ')


if __name__ == '__main__':
    main()
