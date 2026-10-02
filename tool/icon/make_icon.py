#!/usr/bin/env python3
"""Draws the app icon as pixel art, in the 256-colour style of the game: a
chrome pinball as a ringed planet in the lavender of the Space Cadet logo,
a rocket flame behind it, on a starfield. Own artwork (no original game
art), so it can live in the repo.

Every pixel is computed on the icon's own grid (48 for the legacy icon,
108 for the adaptive layers, so a pixel is the same size in both), with
small fixed palettes and 4 × 4 ordered dithering between shades, as
pre-rendered art of the time was.

    python3 tool/icon/make_icon.py [preview.png]

Writes the Android launcher icons (adaptive and legacy) and the web icons.
Needs Pillow.
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

SPACE = [(6, 4, 18), (14, 9, 38), (24, 15, 62), (36, 22, 88)]
CHROME = [(22, 20, 38), (48, 46, 72), (86, 88, 120), (132, 138, 170),
          (186, 192, 220), (232, 236, 252), (255, 255, 255)]
GROUND = [(18, 16, 34), (40, 34, 74), (70, 58, 128), (104, 88, 176)]
LAVENDER = [(84, 58, 168), (122, 92, 214), (184, 164, 240), (230, 220, 255)]
FLAME = [(190, 40, 30), (240, 96, 32), (255, 170, 48), (255, 236, 150)]
STARS = [(255, 255, 255), (159, 180, 255), (110, 134, 232)]
OUTLINE = (12, 8, 28)


def shade(ramp, t, x, y):
    """Colour t (0…1) from a ramp, dithered between neighbouring shades."""
    t = min(max(t, 0.0), 1.0) * (len(ramp) - 1)
    i = int(t)
    if i >= len(ramp) - 1:
        return ramp[-1]
    return ramp[i + 1] if (t - i) * 16 > BAYER[y % 4][x % 4] + 0.5 else ramp[i]


def background(g):
    img = Image.new('RGBA', (g, g))
    px = img.load()
    for y in range(g):
        for x in range(g):
            d = math.hypot(x / g - 0.42, y / g - 0.40) / 0.8
            px[x, y] = shade(SPACE, 1 - d, x, y) + (255,)
    rnd = random.Random(7)
    for _ in range(int(g * g / 70)):
        x, y = rnd.randrange(g), rnd.randrange(g)
        px[x, y] = rnd.choice(STARS) + (255,)
    for sx, sy in [(0.17, 0.20), (0.82, 0.16), (0.86, 0.80)]:
        x, y = int(sx * g), int(sy * g)
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            px[(x + dx) % g, (y + dy) % g] = (236, 230, 255, 255)
    return img


def foreground(g, scale):
    """Ball, ring and flame with a dark outline, on transparent."""
    img = Image.new('RGBA', (g, g), (0, 0, 0, 0))
    px = img.load()
    cx, cy = g * 0.53, g * 0.50
    r = g * 0.26 * scale
    tilt = math.radians(18)
    ca, sa = math.cos(tilt), math.sin(tilt)
    rx, ry, width = r * 1.75, r * 0.55, r * 0.30
    light = (-0.45, -0.6, 0.66)

    def ring(x, y):
        """Position on the ring (0 outer … 1 inner) and whether it is in
        front of the ball, or None."""
        dx, dy = x - cx, y - cy
        u = dx * ca + dy * sa
        v = -dx * sa + dy * ca
        outer = (u / rx) ** 2 + (v / ry) ** 2
        inner = (u / (rx - width)) ** 2 + (v / (ry - width * 0.42)) ** 2
        if outer <= 1 and inner > 1:
            return 1 - (math.sqrt(outer) - (rx - width) / rx) / (width / rx), v > 0
        return None

    def flame(x, y):
        ang = math.radians(215)
        fx, fy = math.cos(ang), -math.sin(ang)
        dx, dy = x - cx, y - cy
        along = dx * fx + dy * fy - r * 0.45
        across = abs(-dx * fy + dy * fx)
        length = r * 1.5
        if 0 <= along <= length:
            half = r * 0.55 * (1 - along / length)
            if across <= half:
                return 1 - max(along / length, across / max(half, 1e-6)) * 0.85
        return None

    for y in range(g):
        for x in range(g):
            fxp, fyp = x + 0.5, y + 0.5
            dx, dy = (fxp - cx) / r, (fyp - cy) / r
            in_ball = dx * dx + dy * dy <= 1
            rg = ring(fxp, fyp)
            colour = None
            if rg is not None and not rg[1]:
                colour = shade(LAVENDER, 0.35 + 0.65 * rg[0], x, y)
            f = flame(fxp, fyp)
            if f is not None and not in_ball:
                colour = shade(FLAME, f, x, y)
            if in_ball:
                nz = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
                lit = max(0.0, dx * light[0] + dy * light[1] + nz * light[2])
                if dy < 0.12:
                    # Sky above the horizon.
                    t = 0.12 + 0.72 * lit ** 1.6
                    colour = shade(CHROME, t, x, y)
                else:
                    # The table below it, lighter towards the rim.
                    t = 0.2 + 0.8 * (1 - nz) * 0.9
                    colour = shade(GROUND, t, x, y)
                if math.hypot(dx + 0.30, dy + 0.52) < 0.20:
                    colour = CHROME[-1]
            if rg is not None and rg[1]:
                colour = shade(LAVENDER, 0.35 + 0.65 * rg[0], x, y)
            if colour is not None:
                px[x, y] = colour + (255,)
    # A one-pixel dark outline around everything.
    out = img.copy()
    o = out.load()
    for y in range(g):
        for x in range(g):
            if px[x, y][3]:
                continue
            for ddx, ddy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                nx, ny = x + ddx, y + ddy
                if 0 <= nx < g and 0 <= ny < g and px[nx, ny][3]:
                    o[x, y] = OUTLINE + (255,)
                    break
    return out


def blocks(img, px):
    return img.resize((px, px), Image.NEAREST)


def rounded(img, radius):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), m)
    return out


def main():
    full = background(48)
    full.alpha_composite(foreground(48, 1.0))
    bg = background(108)
    fg = foreground(108, 0.6)
    res = os.path.join(ROOT, 'android/app/src/main/res')
    for name, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        icon = blocks(full, px)
        rounded(icon, px * 0.18).save(os.path.join(d, 'ic_launcher.png'))
        circle = Image.new('L', (px, px), 0)
        ImageDraw.Draw(circle).ellipse([0, 0, px - 1, px - 1], fill=255)
        rnd = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        rnd.paste(icon, (0, 0), circle)
        rnd.save(os.path.join(d, 'ic_launcher_round.png'))
        layer = px * 108 // 48
        blocks(fg, layer).save(os.path.join(d, 'ic_launcher_foreground.png'))
        blocks(bg, layer).save(os.path.join(d, 'ic_launcher_background.png'))
    any_dpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(any_dpi, exist_ok=True)
    xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''
    for name in ['ic_launcher.xml', 'ic_launcher_round.xml']:
        open(os.path.join(any_dpi, name), 'w').write(xml)
    web = os.path.join(ROOT, 'web')
    for name, px, mask in [('icons/Icon-192.png', 192, True), ('icons/Icon-512.png', 512, True),
                           ('icons/Icon-maskable-192.png', 192, False), ('icons/Icon-maskable-512.png', 512, False),
                           ('favicon.png', 32, True)]:
        icon = blocks(full, px) if px >= 48 else full.resize((px, px), Image.LANCZOS)
        if mask:
            icon = rounded(icon, px * 0.18)
        icon.save(os.path.join(web, name))
    if len(sys.argv) > 1:
        preview = Image.new('RGBA', (960 + 20, 480), (255, 255, 255, 255))
        preview.paste(blocks(full, 480), (0, 0))
        a = bg.copy()
        a.alpha_composite(fg)
        v = 72
        o = (108 - v) // 2
        crop = blocks(a.crop((o, o, o + v, o + v)), 480)
        m = Image.new('L', (480, 480), 0)
        ImageDraw.Draw(m).ellipse([0, 0, 479, 479], fill=255)
        preview.paste(crop, (500, 0), m)
        preview.save(sys.argv[1])


if __name__ == '__main__':
    main()
