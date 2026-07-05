#!/usr/bin/env python3
"""Generate Aurora TV logo assets from branding reference images."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "src" / "app" / "res" / "branding"
VARIANTS = BRANDING / "aurora_variants.png"
HERO = BRANDING / "aurora_hero.png"


def content_bbox(im: Image.Image, threshold: int = 24) -> tuple[int, int, int, int]:
    rgb = im.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    xs: list[int] = []
    ys: list[int] = []
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r + g + b > threshold:
                xs.append(x)
                ys.append(y)
    if not xs:
        return 0, 0, w, h
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def square_crop(im: Image.Image, bbox: tuple[int, int, int, int], pad: float = 0.06) -> Image.Image:
    x0, y0, x1, y1 = bbox
    cw, ch = x1 - x0, y1 - y0
    side = max(cw, ch)
    pad_px = int(side * pad)
    side += pad_px * 2
    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    left = max(0, cx - side // 2)
    top = max(0, cy - side // 2)
    right = min(im.width, left + side)
    bottom = min(im.height, top + side)
    crop = im.crop((left, top, right, bottom))
    side = min(crop.width, crop.height)
    return crop.crop((0, 0, side, side))


def resize_icon(im: Image.Image, size: int) -> Image.Image:
    return im.resize((size, size), Image.Resampling.LANCZOS)


def make_splash(hero: Image.Image, width: int = 1920, height: int = 1080) -> Image.Image:
    canvas = Image.new("RGB", (width, height), (8, 10, 18))
    src = hero.convert("RGBA")
    scale = min(width / src.width, height / src.height) * 0.88
    nw = max(1, int(src.width * scale))
    nh = max(1, int(src.height * scale))
    resized = src.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (width - nw) // 2
    y = (height - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def extract_panel_icon(variants: Image.Image, panel_index: int) -> Image.Image:
    w, h = variants.size
    panel_w = w // 3
    x0 = panel_index * panel_w
    panel = variants.crop((x0, 0, x0 + panel_w, h))
    # Skip label row at top (~18% of panel height).
    icon_area = panel.crop((0, int(h * 0.16), panel_w, h))
    bbox = content_bbox(icon_area)
    return square_crop(icon_area, bbox, pad=0.04)


def main() -> int:
    if not VARIANTS.is_file():
        print(f"Missing variants image: {VARIANTS}", file=sys.stderr)
        return 1
    if not HERO.is_file():
        print(f"Missing hero image: {HERO}", file=sys.stderr)
        return 1

    variants = Image.open(VARIANTS).convert("RGBA")
    hero = Image.open(HERO).convert("RGBA")

    icon_src = extract_panel_icon(variants, 0)
    icon_96 = resize_icon(icon_src, 96)
    icon_130 = resize_icon(icon_src, 130)
    icon_512 = resize_icon(icon_src, 512)
    splash = make_splash(hero)

    out_app = ROOT / "src" / "app" / "res" / "img" / "moonlight.png"
    out_webos = ROOT / "deploy" / "webos"
    out_app.parent.mkdir(parents=True, exist_ok=True)
    out_webos.mkdir(parents=True, exist_ok=True)

    icon_96.save(out_app, optimize=True)
    icon_130.save(out_webos / "icon.png", optimize=True)
    icon_512.save(out_webos / "icon_large.png", optimize=True)
    splash.save(out_webos / "splash.png", optimize=True)

    print(f"Wrote {out_app}")
    print(f"Wrote {out_webos / 'icon.png'}")
    print(f"Wrote {out_webos / 'icon_large.png'}")
    print(f"Wrote {out_webos / 'splash.png'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
