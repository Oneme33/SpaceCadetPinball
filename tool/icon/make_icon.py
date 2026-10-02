#!/usr/bin/env python3
"""Draws the app icon: a chrome pinball as a ringed planet, a rocket flame
behind it, on a starfield, in the colours of the Space Cadet logo. Own
artwork (no original game art), so it can live in the repo.

    python3 tool/icon/make_icon.py [preview.png]

Writes the Android launcher icons (adaptive and legacy) and the web icons.
Needs Pillow.
"""
import math
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
N = 2048  # drawing size; everything is scaled down from here


def radial(size, inner, outer, center=(0.5, 0.5), radius=0.75):
    """A radial gradient from inner to outer colour."""
    w = h = size
    img = Image.new('RGB', (w, h))
    px = img.load()
    cx, cy = center[0] * w, center[1] * h
    r = radius * w
    for y in range(h):
        for x in range(w):
            t = min(1.0, math.hypot(x - cx, y - cy) / r)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return img


def background(size):
    """Deep space with stars and a violet glow."""
    small = 256
    bg = radial(small, (40, 26, 92), (4, 3, 14), center=(0.42, 0.40), radius=0.85)
    bg = bg.resize((size, size), Image.BICUBIC)
    d = ImageDraw.Draw(bg)
    rnd = random.Random(7)
    for _ in range(160):
        x, y = rnd.random() * size, rnd.random() * size
        r = size * (0.0016 + rnd.random() ** 3 * 0.004)
        c = rnd.choice([(255, 255, 255), (159, 180, 255), (110, 134, 232)])
        a = int(120 + rnd.random() * 135)
        d.ellipse([x - r, y - r, x + r, y + r], fill=c + (a,))
    for x, y, s in [(0.18, 0.22, 0.030), (0.80, 0.16, 0.022), (0.86, 0.78, 0.018)]:
        sparkle(d, x * size, y * size, s * size)
    return bg


def sparkle(d, x, y, s):
    """A four-pointed star."""
    for dx, dy in [(1, 0), (0, 1)]:
        d.polygon([
            (x - dx * s, y - dy * s), (x + dy * s * 0.12, y + dx * s * 0.12),
            (x + dx * s, y + dy * s), (x - dy * s * 0.12, y - dx * s * 0.12),
        ], fill=(235, 230, 255))


def ellipse_mask(size, box, angle=0.0, blur=0):
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).ellipse(box, fill=255)
    if angle:
        m = m.rotate(angle, resample=Image.BICUBIC, center=((box[0] + box[2]) / 2, (box[1] + box[3]) / 2))
    if blur:
        m = m.filter(ImageFilter.GaussianBlur(blur))
    return m


def ball_layer(size, cx, cy, r):
    """A chrome ball: sky above the horizon, dark ground below, a white
    highlight, a violet rim light."""
    yy = Image.linear_gradient('L').resize((size, size))
    sky = Image.new('RGB', (size, size), (236, 240, 255))
    mid = Image.new('RGB', (size, size), (120, 128, 160))
    ground = Image.new('RGB', (size, size), (30, 30, 46))
    top = int(cy - r)
    span = 2 * r
    # Vertical blend: sky → mid at the horizon (just below the middle) → ground.
    grad = Image.new('L', (1, 256))
    for i in range(256):
        t = i / 255
        grad.putpixel((0, i), int(255 * min(1, max(0, (t - 0.0) / 0.55))))
    g1 = grad.resize((size, int(span))).crop((0, 0, size, int(span)))
    a = Image.new('L', (size, size), 0)
    a.paste(g1, (0, top))
    body = Image.composite(mid, sky, a)
    grad2 = Image.new('L', (1, 256))
    for i in range(256):
        t = i / 255
        grad2.putpixel((0, i), 255 if t > 0.56 else int(255 * max(0, (t - 0.50) / 0.06)))
    g2 = grad2.resize((size, int(span)))
    b = Image.new('L', (size, size), 0)
    b.paste(g2, (0, top))
    body = Image.composite(ground, body, b)
    # Ground lightens towards the bottom rim (reflected table).
    rim = ellipse_mask(size, [cx - r * 0.9, cy + r * 0.25, cx + r * 0.9, cy + r * 1.3], blur=r * 0.15)
    body = Image.composite(Image.new('RGB', (size, size), (96, 82, 170)), body, rim.point(lambda v: v * 0.55))
    # Highlight.
    hl = ellipse_mask(size, [cx - r * 0.62, cy - r * 0.78, cx - r * 0.02, cy - r * 0.30], angle=-25, blur=r * 0.06)
    body = Image.composite(Image.new('RGB', (size, size), (255, 255, 255)), body, hl)
    spot = ellipse_mask(size, [cx + r * 0.30, cy - r * 0.55, cx + r * 0.46, cy - r * 0.40], blur=r * 0.03)
    body = Image.composite(Image.new('RGB', (size, size), (255, 255, 255)), body, spot)
    # Edge darkening.
    edge = ellipse_mask(size, [cx - r, cy - r, cx + r, cy + r])
    inner = ellipse_mask(size, [cx - r * 0.86, cy - r * 0.86, cx + r * 0.86, cy + r * 0.86], blur=r * 0.12)
    shade = ImageChops.subtract(edge, inner).point(lambda v: v * 0.6)
    body = Image.composite(Image.new('RGB', (size, size), (20, 18, 40)), body, shade)
    return body, edge


def ring_layer(size, cx, cy, rx, ry, width, angle):
    """The planet ring as an image with alpha, and the mask of its front
    half (in front of the ball)."""
    outer = ellipse_mask(size, [cx - rx, cy - ry, cx + rx, cy + ry])
    inner = ellipse_mask(size, [cx - rx + width, cy - ry + width * 0.42,
                                cx + rx - width, cy + ry - width * 0.42])
    band = ImageChops.subtract(outer, inner)
    # Lavender, lighter at the top edge of the band.
    col = Image.new('RGB', (size, size), (184, 164, 240))
    light = Image.new('RGB', (size, size), (236, 228, 255))
    top = ellipse_mask(size, [cx - rx, cy - ry, cx + rx, cy + ry - width * 0.3])
    col = Image.composite(light, col, ImageChops.subtract(band, top).point(lambda v: 255 - v).point(lambda v: v // 2))
    stripe_out = ellipse_mask(size, [cx - rx + width * 0.45, cy - ry + width * 0.19,
                                     cx + rx - width * 0.45, cy + ry - width * 0.19])
    stripe_in = ellipse_mask(size, [cx - rx + width * 0.55, cy - ry + width * 0.23,
                                    cx + rx - width * 0.55, cy + ry - width * 0.23])
    col = Image.composite(Image.new('RGB', (size, size), (122, 92, 214)), col,
                          ImageChops.subtract(stripe_out, stripe_in))
    front = Image.new('L', (size, size), 0)
    ImageDraw.Draw(front).rectangle([0, cy, size, size], fill=255)
    rot = lambda im: im.rotate(angle, resample=Image.BICUBIC, center=(cx, cy))
    return rot(col), rot(band), rot(front)


def flame_layer(size, cx, cy, r):
    """A rocket flame streaming away to the lower left."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ang = math.radians(215)
    for i, (c, w, l) in enumerate([((255, 70, 40), 0.55, 1.55), ((255, 150, 40), 0.40, 1.25), ((255, 235, 140), 0.22, 0.95)]):
        base = (cx + math.cos(ang) * r * 0.55, cy - math.sin(ang) * r * 0.55)
        tip = (cx + math.cos(ang) * r * (0.55 + l), cy - math.sin(ang) * r * (0.55 + l))
        px, py = -math.sin(ang), -math.cos(ang)
        hw = r * w
        d.polygon([(base[0] + px * hw, base[1] + py * hw), tip, (base[0] - px * hw, base[1] - py * hw)], fill=c + (235,))
    return layer.filter(ImageFilter.GaussianBlur(r * 0.06))


def foreground(size, scale=1.0):
    """Ball, ring and flame on transparent, centred, at [scale] of the
    layer (adaptive icons keep the inner 66 %)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cx, cy = size * 0.53, size * 0.50
    r = size * 0.26 * scale
    img.alpha_composite(flame_layer(size, cx, cy, r))
    col, band, front = ring_layer(size, cx, cy, r * 1.75, r * 0.55, r * 0.30, 18)
    back = ImageChops.subtract(band, front)
    img.paste(col, (0, 0), back)
    body, mask = ball_layer(size, cx, cy, r)
    # Soft glow around the ball.
    glow = mask.filter(ImageFilter.GaussianBlur(r * 0.18)).point(lambda v: v * 0.5)
    img.paste(Image.new('RGB', (size, size), (122, 92, 214)), (0, 0), glow)
    img.paste(body, (0, 0), mask)
    img.paste(col, (0, 0), ImageChops.multiply(band, front))
    return img


def rounded(img, radius):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), m)
    return out


def main():
    bg = background(N).convert('RGBA')
    full = bg.copy()
    full.alpha_composite(foreground(N, scale=1.0))
    # Adaptive icon layers: 108 dp, content in the middle 66 %.
    adaptive_fg = foreground(N, scale=0.6)
    res = os.path.join(ROOT, 'android/app/src/main/res')
    for name, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        icon = full.resize((px, px), Image.LANCZOS)
        rounded(icon, px * 0.18).save(os.path.join(d, 'ic_launcher.png'))
        circle = Image.new('L', (px, px), 0)
        ImageDraw.Draw(circle).ellipse([0, 0, px - 1, px - 1], fill=255)
        rnd = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        rnd.paste(icon, (0, 0), circle)
        rnd.save(os.path.join(d, 'ic_launcher_round.png'))
        layer = px * 108 // 48
        adaptive_fg.resize((layer, layer), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))
        bg.resize((layer, layer), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_background.png'))
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
        icon = full.resize((px, px), Image.LANCZOS)
        if mask:
            icon = rounded(icon, px * 0.18)
        icon.save(os.path.join(web, name))
    if len(sys.argv) > 1:
        full.resize((512, 512), Image.LANCZOS).save(sys.argv[1])


if __name__ == '__main__':
    main()
