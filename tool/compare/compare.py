#!/usr/bin/env python3
"""Lays the port's ball tracks beside the reference's (the decompilation).

    compare.py ref.csv port.csv walls.json out_dir

Prints, per scenario, how far apart the two balls are over time and their
speeds, and draws both tracks over the table's walls in out_dir/<name>.png
(reference red, port cyan). Needs Pillow.
"""
import csv
import json
import math
import os
import sys
from collections import defaultdict

from PIL import Image, ImageDraw

SCALE = 28  # pixels per table unit


def load(path):
    tracks = defaultdict(list)
    with open(path) as f:
        # The reference prints its own log lines before the header.
        lines = f.read().splitlines()
        start = next(i for i, l in enumerate(lines) if l.startswith('scenario,'))
        for row in csv.DictReader(lines[start:]):
            if row['x'] == '':
                tracks[row['scenario']].append((float(row['t']), None))
                continue
            tracks[row['scenario']].append((
                float(row['t']),
                (float(row['x']), float(row['y']), float(row['vx']),
                 float(row['vy']), int(row['mask'] or 1),
                 row.get('holder') or ''),
            ))
    return tracks


def at(track, t):
    """Linear interpolation of a track at time t (None if the ball is gone)."""
    for (t0, a), (t1, b) in zip(track, track[1:]):
        if t0 <= t <= t1:
            if a is None or b is None:
                return a if t - t0 < t1 - t else b
            u = (t - t0) / (t1 - t0) if t1 > t0 else 0
            return tuple(a[i] + (b[i] - a[i]) * u for i in range(4)) + a[4:]
    return track[-1][1] if track and t >= track[-1][0] else None


def holds(track):
    """(holder, from, to) for every stretch a part holds the ball."""
    out, cur = [], None
    for t, p in track:
        h = p[5] if p and len(p) > 5 else ''
        if cur and h != cur[0]:
            out.append((cur[0], cur[1], t))
            cur = None
        if h and not cur:
            cur = (h, t)
    if cur:
        out.append((cur[0], cur[1], track[-1][0]))
    return out


def to_px(x, y):
    # +x is screen-left in table space.
    return ((8 - x) * SCALE, (y + 14.5) * SCALE)


def draw(name, ref, port, walls, out):
    img = Image.new('RGB', (16 * SCALE, 30 * SCALE), (12, 12, 20))
    d = ImageDraw.Draw(img)
    o = walls['outline']
    d.line([to_px(o[i], o[i + 1]) for i in range(0, len(o), 2)] +
           [to_px(o[0], o[1])], fill=(90, 90, 110), width=1)
    for w in walls['walls']:
        s = w['shape']
        if not s:
            continue
        col = (70, 70, 90)
        if s[0] == 'poly':
            p = s[1:]
            pts = [to_px(p[i], p[i + 1]) for i in range(0, len(p), 2)]
            d.line(pts + [pts[0]], fill=col)
        elif s[0] == 'line':
            d.line([to_px(s[1], s[2]), to_px(s[3], s[4])], fill=col)
        elif s[0] == 'circle':
            cx, cy = to_px(s[1], s[2])
            r = s[3] * SCALE
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col)
    for track, col in ((ref, (255, 80, 80)), (port, (80, 220, 255))):
        pts = [to_px(p[0], p[1]) for _, p in track if p]
        if len(pts) > 1:
            d.line(pts, fill=col, width=2)
        if pts:
            d.ellipse([pts[0][0] - 4, pts[0][1] - 4, pts[0][0] + 4,
                       pts[0][1] + 4], outline=col)
    d.text((6, 6), name, fill=(230, 230, 230))
    img.save(os.path.join(out, name + '.png'))


def main():
    ref, port = load(sys.argv[1]), load(sys.argv[2])
    walls = json.load(open(sys.argv[3]))
    out = sys.argv[4]
    os.makedirs(out, exist_ok=True)
    for name in ref:
        r, p = ref[name], port.get(name, [])
        draw(name, r, p, walls, out)
        end = min(r[-1][0], p[-1][0] if p else 0)
        diverge = None
        lines = []
        for t in [0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]:
            if t > end:
                break
            a, b = at(r, t), at(p, t)
            if a is None or b is None:
                lines.append(f'  t={t:<4} ref {"gone" if a is None else "on"}'
                             f' port {"gone" if b is None else "on"}')
                continue
            dist = math.hypot(a[0] - b[0], a[1] - b[1])
            lines.append(
                f'  t={t:<4} ref ({a[0]:6.2f},{a[1]:6.2f}) v{math.hypot(a[2], a[3]):5.1f}'
                f'  port ({b[0]:6.2f},{b[1]:6.2f}) v{math.hypot(b[2], b[3]):5.1f}'
                f'  Δ{dist:5.2f}')
        t = 0.0
        while t <= end:
            a, b = at(r, t), at(p, t)
            if (a is None) != (b is None) or (
                    a and b and math.hypot(a[0] - b[0], a[1] - b[1]) > 0.5):
                diverge = t
                break
            t += 0.01
        print(f'{name}: tracks within 0.5 until '
              f'{"the end" if diverge is None else f"{diverge:.2f} s"}')
        print('\n'.join(lines))
        hr, hp = holds(r), holds(p)
        if hr or hp:
            fmt = lambda hs: ', '.join(f'{h} {a:.2f}–{b:.2f}' for h, a, b in hs) or '—'
            print(f'  held: ref {fmt(hr)}')
            print(f'        port {fmt(hp)}')


if __name__ == '__main__':
    main()
