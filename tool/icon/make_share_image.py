#!/usr/bin/env python3
"""The 1200 × 630 share image for the website (WhatsApp, Facebook, X
previews): the pixel-art icon and the title on a starfield. Own artwork.

    python3 tool/icon/make_share_image.py
"""
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_icon  # noqa: E402

ROOT = make_icon.ROOT
W, H = 1200, 630


def font(size):
    for f in ['/System/Library/Fonts/Supplemental/Arial Black.ttf',
              '/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf',
              '/Library/Fonts/Arial Bold.ttf']:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def gradient_text(img, xy, text, f, top, bottom, outline):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).text(xy, text, font=f, fill=255)
    box = mask.getbbox()
    grad = Image.new('RGB', img.size)
    g = ImageDraw.Draw(grad)
    for y in range(box[1], box[3] + 1):
        t = (y - box[1]) / max(1, box[3] - box[1])
        g.line([(0, y), (img.size[0], y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    d = ImageDraw.Draw(img)
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            if dx * dx + dy * dy <= 10:
                d.text((xy[0] + dx, xy[1] + dy), text, font=f, fill=outline)
    img.paste(grad, (0, 0), mask)


def main():
    img = Image.new('RGB', (W, H), (6, 4, 18))
    d = ImageDraw.Draw(img)
    rnd = random.Random(3)
    for _ in range(420):
        x, y = rnd.randrange(W), rnd.randrange(H)
        c = rnd.choice([(255, 255, 255), (159, 180, 255), (110, 134, 232)])
        s = rnd.choice([2, 2, 3])
        d.rectangle([x, y, x + s, y + s], fill=c)
    icon = make_icon.background(48)
    icon.alpha_composite(make_icon.foreground(48, 1.0))
    icon = make_icon.rounded(make_icon.blocks(icon, 384), 384 * 0.18)
    img.paste(icon, (70, (H - 384) // 2), icon)
    # The title as large as fits right of the icon.
    size = 104
    while size > 40 and d.textlength('Space Cadet', font=font(size)) > W - 500 - 50:
        size -= 2
    gradient_text(img, (500, 175), '3D Pinball', font(int(size * 0.6)), (230, 220, 255), (184, 164, 240), (42, 27, 92))
    gradient_text(img, (494, 250), 'Space Cadet', font(size), (230, 220, 255), (122, 92, 214), (42, 27, 92))
    d.text((502, 410), 'Play in your browser or on Android', font=font(34), fill=(201, 196, 230))
    out = os.path.join(ROOT, 'site/share.png')
    img.save(out, optimize=True)
    print(out)


if __name__ == '__main__':
    main()
