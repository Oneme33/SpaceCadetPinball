#!/usr/bin/env python3
"""HD versions of the lamps and the ball, which Real-ESRGAN gets wrong
(a lamp of a few pixels comes out as a rectangle, the small balls square).

- A round lamp (its opaque pixels fill the ellipse of its bounding box) is
  drawn anew as a smooth ellipse, coloured from the centre outwards with
  the original's own colours (its radial colour profile): the same bright
  core and dark rim, now round at any size.
- Other lamps (triangles, arrows) use xBRZ, made for pixel art.
- The ball keeps its own picture (highlight, reflection, rim) upscaled
  smoothly, cut to an exact circle with a soft edge.
Every other sprite keeps its ESRGAN version.

    python3 tool/hd_small_sprites.py <src dir> <out dir> <groups.json> [scale]

groups.json: {"lamps": [group, …], "balls": [group, …]}, written by
tool/make_hd.dart. Needs `pip install xbrz.py Pillow`.
"""
import json
import math
import os
import sys

import xbrz
from PIL import Image, ImageFilter

BINS = 10

# Lamps up to this size (pixels) are redrawn; larger ones keep ESRGAN.
LAMP_LIMIT = 16


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


def ball(im, scale):
    """The ball's own picture upscaled smoothly and cut to a circle."""
    w, h = im.size
    px = im.load()
    opaque = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] > 0]
    x0 = min(p[0] for p in opaque); x1 = max(p[0] for p in opaque) + 1
    y0 = min(p[1] for p in opaque); y1 = max(p[1] for p in opaque) + 1
    cx, cy = (x0 + x1) / 2 * scale, (y0 + y1) / 2 * scale
    r = min(x1 - x0, y1 - y0) / 2 * scale
    # Transparent pixels carry the neighbouring colour (see make_hd's bleed),
    # so the smooth scale does not darken the edge.
    rgb = im.convert('RGB').resize((w * scale, h * scale), Image.BICUBIC)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=2, percent=90, threshold=2))
    out = Image.new('RGBA', rgb.size, (0, 0, 0, 0))
    o, c = out.load(), rgb.load()
    for y in range(h * scale):
        for x in range(w * scale):
            a = max(0.0, min(1.0, r - math.hypot(x + .5 - cx, y + .5 - cy) + .5))
            if a > 0:
                p = c[x, y]
                o[x, y] = (p[0], p[1], p[2], round(255 * a))
    return out


def main():
    src, dst = sys.argv[1], sys.argv[2]
    groups = json.load(open(sys.argv[3]))
    scale = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    counts = {'round lamps': 0, 'other lamps (xBRZ)': 0, 'balls': 0}
    for kind in ('lamps', 'balls'):
        for g in groups[kind]:
            path = os.path.join(src, f'g{g}.png')
            if not os.path.exists(path):
                continue
            im = Image.open(path).convert('RGBA')
            # Larger lamps (the big arrows) come out of ESRGAN well.
            if kind == 'lamps' and max(im.size) > LAMP_LIMIT:
                continue
            if kind == 'balls':
                out = ball(im, scale)
                counts['balls'] += 1
            else:
                out = lamp(im, scale)
                if out is not None:
                    counts['round lamps'] += 1
                else:
                    out = xbrz.scale_pillow(im, scale)
                    counts['other lamps (xBRZ)'] += 1
            out.save(os.path.join(dst, f'g{g}.png'))
    print('Redrawn: ' + ', '.join(f'{n} {k}' for k, n in counts.items()))


if __name__ == '__main__':
    main()
