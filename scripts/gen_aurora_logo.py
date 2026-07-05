#!/usr/bin/env python3
"""Generate Aurora TV logo assets from the master branding image."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "src" / "app" / "res" / "branding"
SOURCE = BRANDING / "aurora_logo.png"

# Crop regions tuned for aurora_logo.png (1024x819).
SYMBOL_BOX = (309, 135, 719, 430)
FULL_BOX = (172, 135, 849, 697)

ICON_INSET = 0.14


def crop_box(im: Image.Image, box: tuple[int, int, int, int], pad: int = 8) -> Image.Image:
    x0, y0, x1, y1 = box
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.width, x1 + pad)
    y1 = min(im.height, y1 + pad)
    return im.crop((x0, y0, x1, y1))


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


def flatten_black_to_transparent(im: Image.Image, threshold: int = 28) -> Image.Image:
    rgba = im.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if r + g + b <= threshold:
                px[x, y] = (0, 0, 0, 0)
    return rgba


def make_app_icon(symbol: Image.Image, size: int, inset: float = ICON_INSET) -> Image.Image:
    """Symbol centered on a transparent square (OS launcher / in-app nav icon)."""
    trimmed = flatten_black_to_transparent(symbol.crop(content_bbox(symbol)))
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner = max(1, int(size * (1.0 - 2.0 * inset)))
    sw, sh = trimmed.size
    scale = min(inner / sw, inner / sh)
    nw = max(1, int(sw * scale + 0.5))
    nh = max(1, int(sh * scale + 0.5))
    resized = trimmed.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (size - nw) // 2
    oy = (size - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def make_splash(full: Image.Image, width: int = 1920, height: int = 1080) -> Image.Image:
    canvas = Image.new("RGB", (width, height), (0, 0, 0))
    src = flatten_black_to_transparent(full)
    scale = min(width / src.width, height / src.height) * 0.72
    nw = max(1, int(src.width * scale))
    nh = max(1, int(src.height * scale))
    resized = src.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (width - nw) // 2
    y = (height - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main() -> int:
    if not SOURCE.is_file():
        print(f"Missing source image: {SOURCE}", file=sys.stderr)
        return 1

    logo = Image.open(SOURCE).convert("RGBA")
    symbol = crop_box(logo, SYMBOL_BOX)
    full = crop_box(logo, FULL_BOX, pad=16)

    icon_96 = make_app_icon(symbol, 96)
    icon_130 = make_app_icon(symbol, 130)
    icon_512 = make_app_icon(symbol, 512)
    splash = make_splash(full)

    out_img = ROOT / "src" / "app" / "res" / "img"
    out_webos = ROOT / "deploy" / "webos"
    out_linux = ROOT / "deploy" / "linux"
    out_steam = ROOT / "deploy" / "steamlink"
    out_img.mkdir(parents=True, exist_ok=True)
    out_webos.mkdir(parents=True, exist_ok=True)
    out_linux.mkdir(parents=True, exist_ok=True)
    out_steam.mkdir(parents=True, exist_ok=True)

    icon_96.save(out_img / "moonlight.png", optimize=True)
    wordmark_legacy = out_img / "aurora_wordmark.png"
    if wordmark_legacy.is_file():
        wordmark_legacy.unlink()

    icon_130.save(out_webos / "icon.png", optimize=True)
    icon_512.save(out_webos / "icon_large.png", optimize=True)
    splash.save(out_webos / "splash.png", optimize=True)
    icon_512.save(out_linux / "moonlight-tv.png", optimize=True)
    icon_512.save(out_steam / "moonlight.png", optimize=True)

    print(f"Wrote {out_img / 'moonlight.png'} ({icon_96.size[0]}x{icon_96.size[1]})")
    print(f"Wrote {out_webos / 'icon.png'}")
    print(f"Wrote {out_webos / 'icon_large.png'}")
    print(f"Wrote {out_webos / 'splash.png'}")
    print(f"Wrote {out_linux / 'moonlight-tv.png'}")
    print(f"Wrote {out_steam / 'moonlight.png'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
